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

### Game crashes before it starts or within a few seconds

1. Get the number of cores your system has:

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

### Game starts but crashes within 10 turns

If the game successfully starts but crashes within 10 turns or so, run this command

```
cp ~/.local/share/Steam/ubuntu12_32/steam-runtime/usr/lib/i386-linux-gnu/libtbb.so.2 ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/
```

For more information, see [docs/libtbb-details.md](docs/libtbb-details.md)

### Game crashes before it starts when using mods

The Linux version of Beyond Earth will always crash just before starting if any mods are used. To fix this:

1. Download [CivBE.patch](CivBE.patch)
1. Apply the patch

   ```
   xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
   ```

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

See [here](docs/troubleshooting.md)
