Troubleshooting various crashes with Sid Meier's Civilization: Beyond Earth on Linux.

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

⚠️ Work in progress: [docs/notes/mod-crash.md](docs/notes/mod-crash.md)

ⓘ Mod support seems to have been added in December 2014 but very quickly afterwards users were reporting that starting any game with mods would make the game crash.