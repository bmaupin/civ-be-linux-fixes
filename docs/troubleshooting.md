# Troubleshooting

ⓘ This page has more information for troubleshooting issues not related to a specific bug. See the [readme](../README.md) for specific bugs and fixes.

## Mods aren't loaded when a save game is loaded

When loading a save game that was created using a mod, the mod may not be loaded automatically. This seems to be intended behaviour when a mod does not indicate in its configuration that it affects save games. If you wish to load a particular mod with a saved game, first load the mod through the _Mods_ menu and then load the saved game.

If a particular mod should always be loaded with saved games, the mod developer should update the mod configuration to reflect this by including this in its `.modinfo` file:

```xml
<AffectsSavedGames>1</AffectsSavedGames>
<MinCompatibleSaveVersion>0</MinCompatibleSaveVersion>
```

`MinCompatibleSaveVersion` should be set to the minimum version of the mod that the current version of the mod is compatible with.

⚠️ If `MinCompatibleSaveVersion` isn't in the `.modinfo` file, you will never be able to load a save game created with the mod. Instead, you will always see this message:

> Not all required mods are installed.

## Loading a mod sends the game back to the main menu

If a particular mod requires (or is incompatible with) a DLC that's already loaded, the game will unload/load the needed DLC and then go back to the main menu. Then you will need to go into the _Mods_ menu and load the mod again. This is normal behaviour, at least for the native Linux version.

## The game crashes or has other problems when using mods

Beyond Earth is particularly sensitive to bugs in mods and they can cause the game to crash or exhibit other undesired behaviour such as not properly showing the terrain.

#### Read first

One complication is that in some cases, an error or bug with a mod may not cause the current game to crash. However, an error may cause the next game that's played or loaded to crash unless you first exit Beyond Earth.

This means that:

- In some cases, the game won't crash even if there's an error if you only play one game before exiting Beyond Earth
- If you wish to confirm an error, you can save the game and then load it right away during the same session

#### To troubleshoot

1. First, make sure the mod patch in the [readme](../README.md) is installed

1. Check the [readme](../README.md) for any other fixes that may apply to you

1. The mod may require specific DLC or no DLC to work. Go to the _DLC_ menu in the game to load or unload DLC.

1. Try each mod one at a time in case there are incompatibilities

1. See here for more information: [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601)

#### More info

Some mods are only compatible with the base game or with Rising Tide but don't have this compatibility defined in the mod configuration file. If this is the case, you will need to load/unload the needed DLC in the _DLC_ menu before loading the mod. Mod developers should update mod configuration to include compatibility, for example a mod that requires Rising Tide should have this configuration in its `.modinfo` file:

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

## No dialogue audio from other leaders

If you don't hear the dialogue speech audio from other leaders, this is counterintuitively caused by a setting in the game's video options:

1. Start Beyond Earth

1. In the main menu, go to _Options_ > _Video Options_

1. Check _Show Advanced Options_

1. Set _Leader Scene Quality_ to _Low_ or higher

   ⓘ If _Leader Scene Quality_ is set to _Minimum_, this disables the leader dialogue audio and animations

## Other issues

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
