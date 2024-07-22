Fixes and workarounds for various bugs with Sid Meier's Civilization: Beyond Earth on Linux

💡 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

## Game starts but crashes within 10 turns

The game successfully starts but crashes within 10 turns or so

#### Fix

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

#### Explanation

The CivBE binary requires the shared library libtbb.so.2 ([Threading Building Blocks](https://github.com/oneapi-src/oneTBB)). Steam seems to automatically use the library from Steam Linux Runtime but if it's installed on the system Steam will use that instead, and the system library seems to cause the crash.

This copies the library from the Steam Linux Runtime to the game directory which ensures it's always used.

## Game crashes before it starts when using mods

The game will crash just before starting if any mods are used

#### Fix

⚠️ This is a work in progress and testing is ongoing

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

   ⓘ The patch will also enable acheivements when playing with mods. If you don't want this behaviour, change `32` in the last line of the patch to `31` and re-apply it. See [https://github.com/bmaupin/civ5-cheevos-with-mods](https://github.com/bmaupin/civ5-cheevos-with-mods) for more information.

To uninstall the patch:

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_

#### Caveats

- This is not a proper fix, only a workaround. It may have unintended consequences.
- Testing is ongoing. I've only tested it with a couple simple mods so far.
- If a particular mod requires (or is incompatible with) a DLC that's already loaded, the game will unload/load the needed DLC and then go back to the main menu. Then you will need to go into the Mods menu and load the mod again. As best as I can tell this is normal behaviour and not related to this patch.
- Some mods are only compatible with the base game or with Rising Tide but don't have this compatibility defined in the mod configuration file. If this is the case, you will need to load/unload the needed DLC in the DLC menu before loading the mod. Again, this behaviour is unrelated to this patch but worth noting. Mod developers should update mod configuration to include compatibility, for example a mod that requires Rising Tide should have this configuration in its `.modinfo` file:

  ```xml
  <Dependencies>
    <Dlc id="54D2B257-C591-4045-8F17-A69F033166C7" minversion="0" maxversion="9999" />
  </Dependencies>
  ```

  Or for a mod that requires the base game:

  ```xml
  <Blocks>
    <Dlc id="54D2B257-C591-4045-8F17-A69F033166C7" minversion="0" maxversion="9999" />
  </Blocks>
  ```

#### Explanation

The game has implemented Rising Tide and the base game as shared "CvGameCoreDLL" libraries so they can be loaded and unloaded at runtime to change between the two.

For example, when the game is first started with Rising Tide enabled, the Rising Tide CvGameCoreDLL is loaded as soon as the game is started. Or if the Rising Tide DLC is disabled in the game through the DLC menu, its CvGameCoreDLL is unloaded and the base game CvGameCoreDLL loaded, and vice-versa. When mods are loaded, the CvGameCoreDLL seems to be unloaded and then loaded again, even if it's the one that's already loaded (which, although inefficient, isn't necessarily a problem).

When a CvGameCoreDLL is loaded, the Lua interpreter seems to have some sort of reference to the memory address where it's loaded so that it is able to call Lua functions in CvGameCoreDLL. When a CvGameCoreDLL is unloaded and a different one is loaded, the memory address in the Lua interpreter is updated.

This all seems to work fine except in one situation: when CvGameCoreDLL is loaded because of mods, the memory address changes but it doesn't seem to be properly updated in the Lua interpreter. So as soon as a game starts and tries to call a Lua function in CvGameCoreDLL, it crashes.

The patch works around this by skipping the unload/load of CvGameCoreDLL in certain situations. Originally I was going to skip it when mods are in use, but I was concerned that this would break mods that require or are incompatible with the currently loaded DLC. So instead, the patch instead checks if the currently activated DLC match the DLC that are needed. If they match, there should be no need to unload/load CvGameCoreDLL and so it's skipped.

For more details, see [docs/mod-crash-patch-details.md](docs/mod-crash-patch-details.md)

## Terrain is not displayed correctly

> The Terrain appears above cities and units, no water or hills are visible.

([https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219))

In addition, this bug seems to prevent the game from exiting normally. The game will continue running after it's exited and you must press _Stop_ in Steam to stop it.

#### Fix

```
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/steamassets/assets/ui/ingame/worldview/diplocorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "${game_directory}/steamassets/assets/dlc/expansion1/ui/ingame/worldview/diplocorner.lua"
```

If it continues happening, it may be due to a mod. See here for more information: [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219)

#### Explanation

This terrain bug seems to appear any time there are errors with Lua scripts. This normally occurs with mods but unfortunately, the game (at least the Linux version) ships with a Lua error, and so this bug will occur without any mods installed.

The Lua error in question seems to be a reference to a "culture overview UI" button. As best as I can tell, this code was copied from Civ 5 as this button doesn't even seem to exist in Beyond Earth.
