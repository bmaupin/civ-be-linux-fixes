## Individual bugs and fixes

ⓘ Most of these fixes are included in the [all-in-one patch script](../README.md#all-in-one-patch-script)

### Game crashes without mods

The game can crash just before a match starts, or even 20 turns in. This can be caused by a number of different things.

1. First, run this command and then try again:

   ```
   cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
   ```

   See [here](more-details.md#libtbb) for more information

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

1. If you're using Intel graphics and the game is still crashing, see [iris-workaround.md](iris-workaround.md)

### Game crashes when using mods

The Linux version of Beyond Earth will crash if any mods are used. To fix this:

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

See [here](mod-crash-patch-details.md) for more information.

### The game crashes loading a saved game with mods and different DLC

If this happens, simply load/unload the necessary DLC before loading the saved game.

For example, if you have Rising Tide enabled and you try to load a saved game that was created with a mod and with Rising Tide disabled, the game will crash unless you first unload the Rising Tide DLC before loading the saved game.

### Terrain appears above cities and units, no water or hills are visible

Run this in a terminal:

```
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/ui/ingame/worldview/diplocorner.lua"
sed -i 's/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI")) then/if(Game.IsOption("GAMEOPTION_NO_CULTURE_OVERVIEW_UI") and Controls.CultureOverviewButton) then/' "/home/${USER}/.steam/steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/assets/dlc/expansion1/ui/ingame/worldview/diplocorner.lua"
```

If it continues happening, it may be due to a mod. See [https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219](https://steamcommunity.com/sharedfiles/filedetails/?id=569681601#882219)

See [here](more-details.md#terrain-appears-above-cities-and-units-no-water-or-hills-are-visible) for more information.

### Terrain is black

TODO: What is the fix for this? Possible options:

- [https://steamcommunity.com/app/65980/discussions/0/530646080851443982/](https://steamcommunity.com/app/65980/discussions/0/530646080851443982/)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=54#c144513248279481346](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=54#c144513248279481346)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135507780430381518](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135507780430381518)
- [https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135508662492314124](https://steamcommunity.com/app/65980/discussions/0/626329820749233064/?ctp=58#c135508662492314124)

### Sound issues

This might fix sound issues, such as the game music stopping after a certain time:

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libopenal.so.1 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

See [here](more-details.md#sound-issues) for more information.
