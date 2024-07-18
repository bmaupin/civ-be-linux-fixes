Fixes and workarounds for various crashes with Sid Meier's Civilization: Beyond Earth on Linux

💡 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

## Game crashes within 10 turns

The game successfully starts but crashes within 10 turns or so

#### Fix

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

#### Explanation

The CivBE binary requires the shared library libtbb.so.2 (Intel's Threading Building Blocks, now [oneTBB](https://github.com/oneapi-src/oneTBB)). If this isn't installed on the system then Steam seems to automatically use the library from Steam Linux Runtime 1.0 (scout). However, if this libary is installed on the system, the game will use the system library instead. Unfortunately it seems the version of the library included with modern Linux distributions isn't backwards compatible.

The fix copies the library from the Steam Linux Runtime to the game directory so it will always use that version even if a different version is installed on the system.

## Game crashes before it starts when using mods

The game will crash just before starting if any mods are used

#### Install patch

⚠️ This is a work in progress and testing is ongoing

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

#### Uninstall patch

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_
