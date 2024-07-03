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

#### Workaround

1. Download [`workaround.gdb`](workaround.gdb)
1. Copy it to the game directory (`~/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth`)
1. Right-click the game in Steam > _Properties_
1. Under _General_, set _Launch Options_ to:

   ```
   gdb --batch --command=workaround.gdb --args ./CivBE # %command%
   ```

1. Start the game from Steam

1. If you wish to play with a mod:

   1. Under the _DLC_ menu, load or unload any DLC needed by the mod you wish to use

      ⓘ This process is normally automatic, but this is what causes the crash, so it needs to be done manually with this workaround

   1. Open the _Mods_ menu and play with any mods as desired

👉 Caveats:

- Because this uses gdb to avoid the bug, the initial load of Beyond Earth will be slower. Once a game is started, gdb will detach and performance will return to normal.
- Because gdb detaches after the initial mod load, the workaround will only work once when mods are loaded. To play a new game with mods, you will need to completely exit Beyond Earth and start it again from Steam.

#### Explanation

The game has implemented Rising Tide and the base game as shared "CvGameCoreDLL" libraries so they can be loaded and unloaded at runtime to change between the two.

For example, when the game is first started with Rising Tide enabled, the Rising Tide CvGameCoreDLL is loaded as soon as the game is started. Or if the Rising Tide DLC is disabled in the game through the DLC menu, its CvGameCoreDLL is unloaded and the base game CvGameCoreDLL loaded, and vice-versa. When mods are loaded, the CvGameCoreDLL seems to be unloaded and then loaded again, even if it's the one that's already loaded (which, although inefficient, isn't necessarily a problem).

When a CvGameCoreDLL is loaded, the Lua interpreter seems to have some sort of reference to the memory address where it's loaded so that it is able to call Lua functions in CvGameCoreDLL. When a CvGameCoreDLL is unloaded and a different one is loaded, the memory address in the Lua interpreter is updated.

This all seems to work fine except in one situation: when CvGameCoreDLL is loaded because of mods, the memory address changes but it doesn't seem to be properly updated in the Lua interpreter. So as soon as a game starts and tries to call a Lua function in CvGameCoreDLL, it crashes.

The workaround above works around this by skipping only the unload/load of CvGameCoreDLL that happens when mods are used.

#### Other approaches

A shared library wrapper would be nice but won't work in this case because the functions that need to be overridden are in the base game binary and not in a shared library.

Another idea I had was to create a shared library with the function override, then add it to the binary using [statifier](https://sourceforge.net/projects/statifier/), then update the binary and modify all calls to the overridden function to instead call the function in the shared library. However, statifier is all-or-nothing; it will attempt to make all shared libraries used by the binary static, which isn't a viable option since the CvGameCoreDLL libraries need to remain shared librairies. Not to mention it's overkill.

Binary instrumentation such as [Dyninst](https://github.com/dyninst/dyninst/) might work but I'm not sure how feasible it would be to create a patch since the binary seems to differ each time Steam installs it (maybe some kind of security mechanism). And even then, there would likely be a significant performance hit.

The last approach considered would be a patch to the binary. This may still be possible but would take a significant amount of time to create.
