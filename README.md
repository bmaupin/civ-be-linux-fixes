Various fixes and workarounds for Sid Meier's Civilization: Beyond Earth on Linux

📌 [See my other Civ projects here](https://github.com/search?q=user%3Abmaupin+topic%3Acivilization&type=Repositories)

💡 Much of the information here may also apply to the Steam Deck

## All-in-one patch script

👉 For a quick and easy fix for most common problems, run this script. Or see below for specific fixes or general troubleshooting.

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

To uninstall the all-in-one patch script or other fixes below:

1. Open Steam and go to _Library_

1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

1. _Installed Files_ > _Verify integrity of game files_

## Individual bugs and fixes

### Game crashes without mods

The game can crash just before a match starts, or even 20 turns in. This can be caused by a number of different things.

1. First, run this command and then try again:

   ```
   cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
   ```

   See [here](docs/more-details.md#libtbb) for more information

1. If it's still crashing, run this in a terminal to get the number of cores your system has:

   ```
   nproc --all
   ```

1. If you have more than 8 cores:

   1. Open Steam and go to _Library_

   1. Find _Sid Meier's Civilization: Beyond Earth_ and right-click on it > _Properties_

   1. Under _Launch Options_, add this:

      ```
      taskset -c 0-7 %command%
      ```

   Source: [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=68#c830448456536458481](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=68#c830448456536458481)

### Game crashes when using mods

The Linux version of Beyond Earth will always crash just before starting if any mods are used. To fix this:

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

See [here](docs/mod-crash-patch-details.md) for more information.

### The game crashes loading a saved game with mods and different DLC

If this happens, simply load/unload the necessary DLC before loading the saved game.

For example, if you have Rising Tide enabled and you try to load a saved game that was created with a mod and with Rising Tide disabled, the game will crash unless you first unload the Rising Tide DLC before loading the saved game.

### Terrain appears above cities and units, no water or hills are visible

In addition, this bug seems to prevent the game from exiting normally. The game will continue running after it's exited and you must press _Stop_ in Steam to stop it.

If this happens, run this fix:

```
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/ui/ingame/worldview/diplocorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/dlc/expansion1/ui/ingame/worldview/diplocorner.lua"
```

If it continues happening, it may be due to a mod. See [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219)

See [here](docs/more-details.md#terrain-appears-above-cities-and-units-no-water-or-hills-are-visible) for more information.

### Terrain is black

TODO: What is the fix for this? Possible options:

- [https://steamcommunity.com/app/65980/discussions/0/530646080851443982/](https://steamcommunity.com/app/65980/discussions/0/530646080851443982/)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=54#c144513248279481346](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=54#c144513248279481346)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135507780430381518](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135507780430381518)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135508662492314124](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135508662492314124)

### Sound issues

This might fix sound issues, such as the game music will completely stop after a certain time:

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

See [here](docs/more-details.md#sound-issues) for more information.

## Troubleshooting other issues

See [here](docs/troubleshooting.md)
