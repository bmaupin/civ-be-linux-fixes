# Mesa crash research

## Summary

Beyond Earth will crash when using Intel Iris graphics and Mesa 24.0 or later. A bug has been filed upstream with Mesa: https://gitlab.freedesktop.org/mesa/mesa/-/issues/12438

## Details

After upgrading to Ubuntu 24.04, the game crashes even without mods. It can crash when opening the Steam overlay. Most of the time the match will start fine, but then in the match the graphics (specifically text) will not show or become corrupt, and flicker back and forth between not showing/corrupt or just fine. And the game will eventually crash within a few minutes.

Backtrace:

```
Thread 17 "CivBE:gl0" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0xe2193b40 (LWP 57944)]
Download failed: Invalid argument.  Continuing without source file ./string/../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S.
__memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:480
warning: 480	../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S: No such file or directory
(gdb) bt
#0  __memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:480
#1  0xf2f2f770 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#2  0xf2f2d5bb in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#3  0xf2c9b73a in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#4  0xf2c9ba5b in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#5  0xf2a1d4fe in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#6  0xf2bbdd16 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#7  0xf2bbf266 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#8  0xf2c310a1 in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#9  0xf29d40cb in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#10 0xf299fc9b in ?? () from /usr/lib/i386-linux-gnu/dri/iris_dri.so
#11 0xf762fff7 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:447
#12 0xf76c75b8 in clone3 () at ../sysdeps/unix/sysv/linux/i386/clone3.S:111
```

Another backtrace (this is actually the one I saw originally, which is why it took me some time to suspect Mesa was the issue):

```
__memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:479
warning: 479	../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S: No such file or directory
(gdb) bt
#0  __memcpy_sse2_unaligned () at ../sysdeps/i386/i686/multiarch/memcpy-sse2-unaligned.S:479
#1  0x08b11cd0 in FStaticVector<TerrainCell*, 512u, true, 1002u, 259u>::GrowSize(unsigned int) ()
#2  0x08b118fe in FStaticVector<TerrainCell*, 512u, true, 1002u, 259u>::push_back(TerrainCell* const&) ()
#3  0x08b0f994 in Terrain::LaunchJobs(bool) ()
#4  0x08b30d31 in TerrainSystem::LaunchJobs() ()
#5  0x08a9e183 in GameViewState::RenderGame(unsigned short, unsigned short) ()
#6  0x08a9ecc9 in GameViewState::Render(unsigned short, unsigned short, bool) ()
#7  0x089fc4d0 in CivBEApp::RenderFrame(float) ()
#8  0x089f7b96 in CivBEApp::OnIdle() ()
#9  0x089f6859 in CivBEApp::Tick(AppHost::TickInfo const*) ()
#10 0x0903b6e8 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#11 0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#12 0x089f0ff8 in WinMain ()
#13 0x08987301 in ?? ()
#14 0x089bfcb5 in ThreadHANDLE::ThreadProc(void*) ()
#15 0xf762fff7 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:447
#16 0xf76c75b8 in clone3 () at ../sysdeps/unix/sysv/linux/i386/clone3.S:111
```

## Troubleshooting the crash

#### Overview

After trying a bunch of different things to troubleshoot the issue, at some point I started troubleshooting Mesa and I found that the crash started occurring with Mesa 24.0.

The game worked fine with Ubuntu 22.04 (which has Mesa 23.2) but started crashing after upgrading to Ubuntu 24.04, which uses Mesa 24.0

#### More on Mesa

From what I understand, Mesa is basically the OpenGL graphics library for Linux used by open source drivers, which includes all Intel drivers (also some AMD drivers, but Nvidia support is unofficial). Mesa converts OpenGL calls to the API used by the device using user-space drivers (Crocus for older Intel graphics cards, Iris for newer ones). Then these user-space drivers call drivers in the kernel (i915 I think).

I don't know if a program that uses Vulkan would go through Mesa too.

But Mesa does have a "Zink" driver that converts OpenGL calls to Vulkan and then passes those calls to the device's Vulkan API. But due to the extra translation this isn't perfect and can result in some graphics anomalies and a performance hit due to the extra translation.

#### First steps

1. First, I ran the game with gdb to get the backtrace (above), e.g.

   ```
   gdb CivBe
   (gdb) start
   (gdb) cont
   (after crash)
   (gdb) bt
   ```

1. Then I tried some high-level troubleshooting

   - Check game Lua logs to make sure it's not a game issue
   - Try X11 instead of Wayland
   - Try with just one monitor
   - Try full screen instead of windowed
   - Try without mods
   - Try different libtbb
   - Try `taskset` (I'd read about this elsewhere and seems to fix issues with too many cores)

1. Next I ran the game with `MESA_DEBUG=verbose` to look for errors:

   ```
   MESA_DEBUG=verbose LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so ./CivBE
   ```

   And I saw:

   ```
   Mesa: error: GL_OUT_OF_MEMORY in glMapBufferRange(map failed)
   ...
   Segmentation fault
   ```

1. I tried a handful of workarounds:

   - `GALLIUM_THREAD=0 ./CivBE` fixed the crash and the graphic corruption, but the graphics still flickered
   - `LIBGL_ALWAYS_SOFTWARE=1 ./CivBE` switched to software rendering, which worked but the game was unbearably slow. I suppose this confirmed the crash was an issue with hardware rendering
   - `MESA_LOADER_DRIVER_OVERRIDE=zink` fixed all of the issues I was having, but unfortunately it had some annoying graphical anomalies like flickering textures

1. I confirmed that the game had no issues on a different computer; this computer was using the Crocus Mesa driver (it has older intel Graphics)

1. I confirmed again that the game had no issues on another computer with Iris graphics running Ubuntu 22.04 (Mesa 23.2), so it seemed the issue must be with Mesa and more specifically with the Iris driver and with a newer version of Mesa between 23.2 and 24.0

#### Mesa 24.2.8

I wanted to see if upgrading Mesa corrected the issue in case it had already been discovered and fixed upstream.

Unfortunately upgrading to mesa 24.2.8 caused the game to crash before the match even started or just after it started.

Also I noticed that the `GALLIUM_THREAD=0` workaround didn't work any more.

Backtrace:

```
Thread 8 "CivBE" received signal SIGSEGV, Segmentation fault.
[Switching to Thread 0xe5effb40 (LWP 9584)]
0xf3ae7aff in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
(gdb) bt
#0  0xf3ae7aff in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#1  0xf3aea3f4 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#2  0xf3ab6f1f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#3  0xf344f997 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#4  0xf3453614 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#5  0xf3140666 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#6  0xf345242f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#7  0xf25e9c5c in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#8  0xf25ba31f in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#9  0xf25bd882 in ?? ()
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#10 0xf25c3c56 in ?? ()
--Type <RET> for more, q to quit, c to continue without paging--c
   from /lib/i386-linux-gnu/libgallium-24.2.8-1ubuntu1~24.04.1.so
#11 0x0996862f in ID3D11ShaderResourceView_Mac::ASLTexSubImage2D(unsigned int, int, int, int, int, int, unsigned int, unsigned int, void const*, int, int) const ()
#12 0x09963a4b in ID3D11ShaderResourceView_Mac::ASLUpdateSubresource(ID3D11Texture2D_Mac*, unsigned int, D3D11_BOX const*) ()
#13 0x09964169 in ID3D11Texture2D_Mac::ASLUpdateSubresource(unsigned int, D3D11_BOX const*, void const*, unsigned int) ()
#14 0x0994eb7d in ID3D11DeviceContext_Mac::UpdateSubresource(ID3D11Resource*, unsigned int, D3D11_BOX const*, void const*, unsigned int, unsigned int) ()
#15 0x0929e49b in Graphics::_INTERNAL::UpdateSubresource_Workaround(ID3D11Device*, ID3D11DeviceContext*, ID3D11Resource*, unsigned int, D3D11_BOX const*, void const*, unsigned int, unsigned int, unsigned int, bool*) ()
#16 0x092a9f98 in ?? ()
#17 0x092a7a20 in Graphics::Renderer::Render() ()
#18 0x089fc4d5 in CivBEApp::RenderFrame(float) ()
#19 0x089f7b96 in CivBEApp::OnIdle() ()
#20 0x089f6859 in CivBEApp::Tick(AppHost::TickInfo const*) ()
#21 0x0903b6e8 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#22 0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#23 0x089f0ff8 in WinMain ()
#24 0x08987301 in ?? ()
#25 0x089bfcb5 in ThreadHANDLE::ThreadProc(void*) ()
#26 0xf762fff7 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:447
#27 0xf76c75b8 in clone3 () at ../sysdeps/unix/sysv/linux/i386/clone3.S:111
```

#### Downgrade Mesa

Since upgrading Mesa didn't work, it seemed like whatever issue I was running into hasn't yet been identified and fixed. So next, I wanted to downgrade Mesa to indeed confirm it was the issue:

1. Go here: https://launchpad.net/ubuntu/+source/mesa
2. In the list in the main part of the page click _The Noble Numbat_
3. Click on a version under _Releases in Ubuntu_
4. Under _Builds_ click _amd64_
5. Copy the URL for libegl-mesa0, e.g. https://launchpad.net/ubuntu/+source/mesa/23.3.0-1ubuntu1/+build/27036119/+files/libegl-mesa0_23.3.0-1ubuntu1_amd64.deb
6. Get the list of packages we need and copy to a new file in vscode

   ```
   dpkg -l | egrep "mesa|gbm|axtracker" | awk '{print $2}' | egrep -v "mesa-utils|\-dev" | cut -d : -f 1 | sort -u
   ```

7. Prepend each package name with the first part of the URL, and append with the last
8. Prepend `wget ` to each package name and copy to terminal to download
9. Go back to step for, click i386, repeat (it will have a different build number)
   - Or just get the build number for i386 and replace, and replace `amd64` with `i386`
10. Install the packages

    ```
    sudo dpkg -i *.deb
    ```

11. Reboot and test

#### Build Mesa from source

References:

- https://docs.mesa3d.org/install.html
- https://docs.mesa3d.org/meson.html
  - 👉 In particular, see _Cross-compilation and 32-bit builds_
- https://gist.github.com/Venemo/a9483106565df3a83fc67a411191edbd?permalink_comment_id=3951924

Build Mesa from source so we can do a Git bisect and submit an upstream issue:

1. Check out mesa from Git

   https://gitlab.freedesktop.org/mesa/mesa

   ⚠️ This was a huge pain because the `git clone` kept timing out. I tried a bunch of stuff but in the end this is what worked (as per https://stackoverflow.com/a/57082400/399105):

   ```
   Host gitlab.freedesktop.org
        IPQoS=throughput
   ```

1. Check out a tag, e.g. `mesa-23.3.3`

   ⚠️ This is only for testing a specific version. Don't use tags with git bisect

1. Make cross compile file, e.g.

   ```
   echo "[binaries]
   c = '/usr/bin/gcc'
   cpp = '/usr/bin/g++'
   ar = '/usr/bin/gcc-ar'
   strip = '/usr/bin/strip'
   pkg-config = '/usr/bin/pkg-config'
   llvm-config = '/usr/bin/llvm-config-17'

   [properties]
   c_args = ['-m32']
   c_link_args = ['-m32']
   cpp_args = ['-m32']
   cpp_link_args = ['-m32']

   [host_machine]
   system = 'linux'
   cpu_family = 'x86'
   cpu = 'i686'
   endian = 'little'" > cross
   ```

1. (Recommended) Build using Docker

   Figuring out the exact dependencies can be a pain and can leave a bunch of extra unneeded packages or even mess up your system. It's much easier to use Docker to do the build:

   ```
   $ docker run -v "$PWD:/build" --rm -it ubuntu:24.04

   dpkg --add-architecture i386
   apt update
   DEBIAN_FRONTEND=noninteractive apt install -y bison flex g++-multilib gcc-multilib glslang-tools:i386 libclang-17-dev:i386 libclc-17 libclc-17-dev libdrm-dev:i386 libelf-dev:i386 libexpat1-dev:i386 libglvnd-core-dev libllvmspirvlib-17-dev:i386 libllvmspirvlib17:i386 libsensors-dev:i386 libudev-dev:i386 libwayland-bin libwayland-dev:i386 libwayland-egl-backend-dev:i386 libx11-dev:i386 libx11-xcb-dev:i386 libxcb-dri2-0-dev:i386 libxcb-dri3-dev:i386 libxcb-glx0-dev:i386 libxcb-keysyms1-dev:i386 libxcb-present-dev:i386 libxcb-shm0-dev:i386 libxext-dev:i386 libxfixes-dev:i386 libxrandr-dev:i386 libxshmfence-dev:i386 libxxf86vm-dev:i386 libzstd-dev:i386 llvm-17 llvm-17-dev meson pkgconf python3-mako spirv-tools:i386 valgrind zlib1g-dev:i386
   cd /build
   # Run the build command below
   ```

   If you don't wish to use Docker, run the `apt install` command (with `sudo`) above to install dependencies, and make a note of what's installed so you can clean it up later

1. Compile

   Still inside the container, do the build:

   ```
   rm -rf builddir/; \
       meson compile -C builddir/ --clean; \
       PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH meson setup --cross-file cross -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu -Dsysconfdir=/etc -Dgallium-drivers=iris -Dvulkan-drivers= -Dbuildtype=release --wipe builddir/ && \
       meson compile -j 6 -C builddir/
   ```

   👉 Adjust `meson compile -j 6` to the number of cores you wish to use, e.g. `-j 6` will use 6 cores

   - `-Dgallium-drivers=iris -Dvulkan-drivers=`: only build the iris driver to save time
   - `-Dbuildtype=release`: the default build type (debug) will have slower performance and create larger files
   - `-Dprefix`, `-Dlibdir`, `-Dsysconfdir`: these use the same directory layout as Ubuntu; the built libraries will contain some hard-coded references to these paths for configuration files, e.g.

     ```
     $ strings /usr/lib/x86_64-linux-gnu/libGLX_mesa.so.0 | egrep "/drirc"
     /usr/share/drirc.d
     /etc/drirc
     ```

     - libGL/libGLX_mesa has references to:
       - `libdir`/dri
       - `prefix`/share/drirc.d
       - `sysconfdir`/drirc
     - iris/libgalium has references to:
       - `prefix`/share/drirc.d
       - `sysconfdir`/drirc

   ⚠️ Ignore these errors:

   ```
   /usr/bin/ld: skipping incompatible /usr/lib/llvm-17/lib/libLLVM-17.so when searching for -lLLVM-17
   ```

1. Install

   Still inside the container, do the install:

   ```
   rm -rf built; \
       DESTDIR=$(pwd)/built meson install -C builddir/
   ```

   👉 At this point, you can do the remaining commands outside the container, but leave the container running so you don't have to reinstall everything if you need to do another build

1. Sanity check

   1. Download 32-bit glxinfo

      I downloaded the mesa-utils i386 .deb from here and extracted glxinfo from it: https://launchpad.net/ubuntu/+source/mesa-demos/8.4.0-1build1/+build/15697776

   1. Run this command and make sure you see the version you just built

      ```
      $ LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/ ~/Desktop/tmp-mesa/mesa-utils-i386/glxinfo | grep -i mesa
      ```

      👉 For Mesa 23, you'll also need `LIBGL_DRIVERS_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/dri`

1. Test

   ```
   cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth
   MESA_DEBUG=verbose LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/ ./CivBE
   ```

   👉 For Mesa 23, you'll also need `LIBGL_DRIVERS_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/dri`

If you get a build error, go up the logs and look for the actual error (it may not be at the end due to parallel compilation), e.g.

```
/usr/bin/ld: /usr/lib/x86_64-linux-gnu/libxcb.so: error adding symbols: file in wrong format
collect2: error: ld returned 1 exit status
```

Then search for which package contains the file:

```
$ apt-file search /usr/lib/x86_64-linux-gnu/libxcb.so
libxcb1: /usr/lib/x86_64-linux-gnu/libxcb.so.1
libxcb1: /usr/lib/x86_64-linux-gnu/libxcb.so.1.1.0
libxcb1-dev: /usr/lib/x86_64-linux-gnu/libxcb.so
```

And install the 32-bit version, e.g.

```
sudo apt install libxcb1-dev:i386
```

It may also help to uninstall the 64-bit version:

```
sudo apt purge libxcb1-dev
```

#### Bisect

⚠️ Don't bisect with a tag, e.g. `git checkout mesa-23.3.3`

```
git checkout main
git bisect start
git log -p VERSION
git checkout fac4f526acfa300139c37e7270dd8ec84b31ce0f
# build
# test
git bisect good
git checkout 69d1e29dc318bb0f1c395c9a9ba1a94056d4dbef
# rebuild
# test
git bisect bad
# rebuild, test, repeat
```

## Troubleshooting Mesa build

### Build errors

#### `/usr/bin/ld: skipping incompatible /usr/lib/llvm-17/lib/libLLVM-17.so when searching for -lLLVM-17`

This can be ignored

### Runtime errors

#### `did not find extension DRI_IMAGE_DRIVER version 1`

This was happening because I wasn't deleting the `built/` directory in between builds so there was a conflict between the different Mesa versions

## Package Mesa

#### Mesa 23

ⓘ Mesa 23 seems to have a hard-coded dri path inside libGL which will search for the iris driver. This path can be worked around at runtime using `LIBGL_DRIVERS_PATH`. As an alternative, we'll build Mesa with a dummy dri path and then replace the path in LibGL with the path to the game directory so we don't have to provide `LIBGL_DRIVERS_PATH`.

1. Rebuild Mesa

   ```
   rm -rf builddir/; \
       meson compile -C builddir/ --clean; \
       PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig:$PKG_CONFIG_PATH meson setup --cross-file cross -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu -Ddri-drivers-path=/AReallyLongDirectoryNameToReplace12345678901234567890123456789012345678901234567890123456789012345678901234567890 -Dsysconfdir=/etc -Dgallium-drivers=iris -Dvulkan-drivers= -Dbuildtype=release --wipe builddir/ && \
       meson compile -j 6 -C builddir/
   ```

1. Install Mesa

   ```
   rm -rf built; \
       DESTDIR=$(pwd)/built meson install -C builddir/
   ```

1. Rename the dri directory inside built

   ```
   mv built/AReallyLongDirectoryNameToReplace12345678901234567890123456789012345678901234567890123456789012345678901234567890/ built/usr/lib/i386-linux-gnu/dri
   ```

1. Figure out which files are needed

   ```
   $ LIBGL_DRIVERS_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/dri/ LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/ strace -e openat,open -f ~/Desktop/tmp-mesa/mesa-utils-i386/glxinfo 2>&1 | grep tmp-mesa | egrep -v "No such file"
   openat(AT_FDCWD, "/home/username/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libGL.so.1", O_RDONLY|O_LARGEFILE|O_CLOEXEC) = 3
   openat(AT_FDCWD, "/home/username/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libglapi.so.0", O_RDONLY|O_LARGEFILE|O_CLOEXEC) = 3
   openat(AT_FDCWD, "/home/username/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/dri//iris_dri.so", O_RDONLY|O_LARGEFILE|O_CLOEXEC) = 5
   ```

1. Copy the files to the game directory

   ```
   cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth
   cp /home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libGL.so.1 .
   cp /home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libglapi.so.0 .
   cp /home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/dri/iris_dri.so .
   ```

1. Replace the dummy dri lookup path with the game directory

   Run this command inside the game directory:

   ```
   offset=$(grep -oba "/AReallyLongDirectoryNameToReplace" libGL.so.1 | cut -d : -f 1)
   echo -ne "$(pwd)\0" | dd of=libGL.so.1 bs=1 seek=${offset} conv=notrunc
   ```

1. Test

   ```
   MESA_DEBUG=verbose LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so ./CivBE
   ```

1. Strip the libraries

   ⓘ You can also add `-Dstrip=true` to the meson build command

   ```
   strip iris_dri.so libGL.so.1 libglapi.so.0
   ```

#### Mesa 24+

1. Run Beyond Earth with gdb

   ```
   MESA_DEBUG=verbose LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/ gdb CivBE
   (gdb) start
   (gdb) cont
   ```

1. Start a match, and then in gdb type Ctrl+C

1. Enter this into gdb to list shared libraries in use:

   ```
   info sharedlibrary
   ```

1. Make note of which ones are used and copy them directly into the game directory, e.g.

   ```
   cp /home/$HOME/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libgallium-25.0.0-devel.so .
   cp /home/$HOME/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libglapi.so.0.0.0 libglapi.so.0
   cp /home/$HOME/Desktop/tmp-mesa/mesa/built/usr/lib/i386-linux-gnu/libGLX_mesa.so.0.0.0 libGLX_mesa.so.0
   ```

1. Test again to make sure everything works, e.g.

   ```
   MESA_DEBUG=verbose LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so ./CivBE
   ```

1. Strip the libraries

   ⓘ You can also add `-Dstrip=true` to the meson build command

   ```
   strip libgallium-25.0.0-devel.so libglapi.so.0 libGLX_mesa.so.0
   ```

## Apitrace

#### Build apitrace from source

See https://github.com/apitrace/apitrace/blob/master/docs/INSTALL.markdown

```
sudo apt install libx11-dev:i386
git clone https://github.com/apitrace/apitrace.git
git submodule update --init --recursive
cd apitrace
cmake \
    -S. -Bbuild32 \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_C_FLAGS=-m32 \
    -DCMAKE_CXX_FLAGS=-m32 \
    -DCMAKE_SYSTEM_LIBRARY_PATH=/usr/lib/i386-linux-gnu/ \
    -DENABLE_GUI=FALSE
make -C build32
make -C build32 glxtrace
```

Cleanup:

```
sudo apt purge libx11-dev:i386
sudo apt autoremove --purge
```

#### Do apitrace

```
LD_LIBRARY_PATH=/home/$USER/Desktop/tmp-mesa/mesa/built/lib /home/$USER/Desktop/tmp-mesa/apitrace/build32/apitrace trace ./CivBE
```

⚠️ Don't use `LD_PRELOAD=/home/$USER/.local/share/Steam/ubuntu12_32/gameoverlayrenderer.so` as it seems to break apitrace

👉 You may need to try a few times before the crash will happen. For whatever reason, the same exact thing that would consistently cause a crash without apitrace wasn't working, but I tried a handful of times (exiting the game between each time) and finally it worked.
