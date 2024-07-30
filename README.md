Fixes and workarounds for various bugs with Sid Meier's Civilization: Beyond Earth on Linux

💡 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

## All-in-one patch script

Use the provided all-in-one patch script to apply all of the fixes listed below:

1. Download the patch script: [patchcivbe.sh](patchcivbe.sh)

1. (Optional) Open the patch script and comment out any undesired changes

1. Run the patch script

   ```
   ./patchcivbe.sh
   ```

   ⓘ It will default to `"/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth"` for the Beyond Earth installation directory. If you have it installed somewhere else you can provide it as a parameter to the script, e.g.

   ```
   ./patchcivbe.sh /some/other/path
   ```

⚠️ If you uninstall the game or verify the integrity of the game files, the patches will be uninstalled and will need to be re-applied.

## Uninstall

To uninstall the all-in-one patch script or undo any other changes below:

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_

## Individual bugs and fixes

### Game starts but crashes within 10 turns

The game successfully starts but crashes within 10 turns or so

#### Fix

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

#### Explanation

The CivBE binary requires the shared library libtbb.so.2 ([Threading Building Blocks](https://github.com/oneapi-src/oneTBB)). Steam seems to automatically use the library from Steam Linux Runtime but if it's installed on the system Steam will use that instead, and the system library seems to cause the crash.

This copies the library from the Steam Linux Runtime to the game directory which ensures it's always used.

Interestingly enough, Civ 5 includes this file; I'm not sure why they didn't do the same for Beyond Earth: [https://steamdb.info/depot/282301/](https://steamdb.info/depot/282301/)

### Game crashes before it starts when using mods

The game will crash just before starting if any mods are used

#### Fix

⚠️ This is not a proper fix, only a workaround; it may have unintended consequences.

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

   ⓘ The patch will also enable acheivements when playing with mods. If you don't want this behaviour, change `32` in the last line of the patch to `31` and re-apply it. See [https://github.com/bmaupin/civ5-cheevos-with-mods](https://github.com/bmaupin/civ5-cheevos-with-mods) for more information.

#### Explanation

The game has implemented Rising Tide and the base game as shared "CvGameCoreDLL" libraries so they can be loaded and unloaded at runtime to change between the two.

For example, when the game is first started with Rising Tide enabled, the Rising Tide CvGameCoreDLL is loaded as soon as the game is started. Or if the Rising Tide DLC is disabled in the game through the DLC menu, its CvGameCoreDLL is unloaded and the base game CvGameCoreDLL loaded, and vice-versa. When mods are loaded, the CvGameCoreDLL seems to be unloaded and then loaded again, even if it's the one that's already loaded (which, although inefficient, isn't necessarily a problem).

When a CvGameCoreDLL is loaded, the Lua interpreter seems to have some sort of reference to the memory address where it's loaded so that it is able to call Lua functions in CvGameCoreDLL. When a CvGameCoreDLL is unloaded and a different one is loaded, the memory address in the Lua interpreter is updated.

This all seems to work fine except in one situation: when CvGameCoreDLL is loaded because of mods, the memory address changes but it doesn't seem to be properly updated in the Lua interpreter. So as soon as a game starts and tries to call a Lua function in CvGameCoreDLL, it crashes.

The patch works around this by skipping the unload/load of CvGameCoreDLL in certain situations. Originally I was going to skip it when mods are in use, but I was concerned that this would break mods that require or are incompatible with the currently loaded DLC. So instead, the patch instead checks if the currently activated DLC match the DLC that are needed. If they match, there should be no need to unload/load CvGameCoreDLL and so it's skipped.

I filed a support ticket with Aspyr but they said "Unfortunately we are not able to assist with bugs that arise when using community mods." 🤷‍♂️

For more details, see [docs/mod-crash-patch-details.md](docs/mod-crash-patch-details.md)

### The game crashes loading a saved game with mods and different DLC

For example, if you have Rising Tide enabled and you try to load a saved game that was created with a mod and with Rising Tide disabled, the game will crash. This crash seems to be unrelated to the crash mentioned above that happens when trying to start any game using mods, and so the patch for that issue does not fix this one.

#### Workaround

Thankfully there's a workaround: simply load/unload the necessary DLC before loading the saved game. For example, if the saved game was created without Rising Tide, unload the Rising Tide DLC in the _DLC_ menu first and then load the saved game.

### Terrain is not displayed correctly

> The Terrain appears above cities and units, no water or hills are visible.

([https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219))

In addition, this bug seems to prevent the game from exiting normally. The game will continue running after it's exited and you must press _Stop_ in Steam to stop it.

#### Fix

```
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/ui/ingame/worldview/diplocorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/dlc/expansion1/ui/ingame/worldview/diplocorner.lua"
```

If it continues happening, it may be due to a mod. See here for more information: [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219)

#### Explanation

This terrain bug seems to appear any time there are errors with Lua scripts. This normally occurs with mods but unfortunately, the game ships with a Lua error, and so this bug will occur without any mods installed.

The Lua error in question seems to be a reference to a "culture overview UI" button. As best as I can tell, this code was copied from Civ 5 as this button doesn't even seem to exist in Beyond Earth.

The bug also seems to exist in the non-Linux versions of the game but I'm not sure if they exhibit the same behaviour.

### Sound issues

I haven't been able to reproduce this myself but I have seen reports of users mentioning audio issues, such as the game music will completely stop after a certain time.

#### Fix

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

#### Explanation

As with the libtbb.so.2 fix above, this is a required library that isn't included in the game, and it's possible there could be a library compatibility issue with a system library.

## Troubleshooting

ⓘ This section is for other unexpected behaviour not necessarily related to a specific bug

#### Mods aren't loaded when a save game is loaded

When loading a save game that was created using a mod, the mod may not be loaded automatically. This seems to be intended behaviour when a mod does not indicate in its configuration that it affects save games. If you wish to load a particular mod with a saved game, first load the mod through the _Mods_ menu and then load the saved game.

If a particular mod should always be loaded with saved games, the mod developer should update the mod configuration to reflect this by including this in its `.modinfo` file:

```xml
<AffectsSavedGames>1</AffectsSavedGames>
<MinCompatibleSaveVersion>0</MinCompatibleSaveVersion>
```

`MinCompatibleSaveVersion` should be set to the minimum version of the mod that the current version of the mod is compatible with.

⚠️ If `MinCompatibleSaveVersion` isn't in the `.modinfo` file, you will never be able to load a save game created with the mod. Instead, you will always see this message:

> Not all required mods are installed.

#### Loading a mod sends the game back to the main menu

If a particular mod requires (or is incompatible with) a DLC that's already loaded, the game will unload/load the needed DLC and then go back to the main menu. Then you will need to go into the _Mods_ menu and load the mod again. This is normal behaviour, at least for the native Linux version.

#### The game crashes or has problems with a particular mod

Some mods are only compatible with the base game or with Rising Tide but don't have this compatibility defined in the mod configuration file. If this is the case, you will need to load/unload the needed DLC in the _DLC_ menu before loading the mod. Again, this behaviour is unrelated to this patch but worth noting. Mod developers should update mod configuration to include compatibility, for example a mod that requires Rising Tide should have this configuration in its `.modinfo` file:

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

For more help on troubleshooting issues with mods, see [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601)

#### No dialogue audio from other leaders

If you don't hear the dialogue speech audio from other leaders, this is counterintuitively caused by a setting in the game's video options:

1. Start Beyond Earth

1. In the main menu, go to _Options_ > _Video Options_

1. Check _Show Advanced Options_

1. Set _Leader Scene Quality_ to _Low_ or higher

   ⓘ If _Leader Scene Quality_ is set to _Minimum_, this disables the leader dialogue audio and animations

#### Other issues

If you're experiencing another issue, make sure the game isn't missing any needed libraries

1. List the shared libraries needed, e.g.

   ```
   cd ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth
   ldd CivBE
   ```

1. Look for any missing libraries in the output, e.g.

   ```
   libopenal.so.1 => not found
   ```

1. If possible, copy the missing library from the Steam Linux runtime, e.g.

   ```
   cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
   ```

1. If the Steam Linux runtime doesn't have the missing library, install it on your system using your package manager

   👉 Make sure to install the 32-bit version of library as the game is 32-bit

For more information, see [https://wiki.archlinux.org/title/Steam/Game-specific_troubleshooting#Civilization:\_Beyond_earth](https://wiki.archlinux.org/title/Steam/Game-specific_troubleshooting#Civilization:_Beyond_earth)
