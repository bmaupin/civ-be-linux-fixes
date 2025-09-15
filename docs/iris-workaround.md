# Intel Iris crash workaround

ⓘ This workaround is already included in the all-in-one patch script in the [readme](../README.md)

If you're using Intel graphics and the game is crashing:

1. First, make sure you've read the [readme](../README.md) and applied any fixes there

1. If the game is still crashing, determine if you're using Iris or Crocus Mesa driver, e.g.

   ```
   $ lspci | grep -i vga
   00:02.0 VGA compatible controller: Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics] (rev 01)
   ```

1. Get the version of Mesa you're using, e.g.

   ```
   $ glxinfo | grep "OpenGL version"
   OpenGL version string: 4.6 (Compatibility Profile) Mesa 24.0.9-0ubuntu0.3
   ```

1. If you have Iris and you're using Mesa 24.0 or later, download the workaround

   https://github.com/bmaupin/civ-be-linux-fixes/releases/download/v1.0.0/mesa-iris-workaround.tar.xz

1. Extract the files and copy them to the game directory

1. Run this command inside the game directory:

   ```
   echo -ne "$(pwd)\0" | dd of=libGL.so.1 bs=1 seek=350508 conv=notrunc
   ```

   ⓘ This replaces the dummy dri search path inside libGL with the game directory so it will find the iris driver. Unfortunately this will only work when the game is run from the command line because the Steam Linux runtime sets `LIBGL_DRIVERS_PATH` which overrides this path.

1. Set Steam Compatibility

   1. Open Steam and go to _Library_

   1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

   1. Go to _Compatibility_ and check _Force the use of a specific Steam Play compatibility tool_

   1. Select _Legacy runtime 1.0_

      **Alternatively**, you can go to _General_ under _Launch Options_, add this:

      ```
      LIBGL_DRIVERS_PATH="$(pwd)" %command%
      ```

For more info, see [notes/mesa-crash-research.md](notes/mesa-crash-research.md)
