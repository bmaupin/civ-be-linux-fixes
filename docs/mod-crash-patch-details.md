# Mod crash patch details

#### Process for developing patch

I first ran CivBE (the Beyond Earth binary) with gdb and attempted to start a new game with a mod. The game crashed, so I did a backtrace (`bt`) and this is what I saw:

```
Thread 13 "CivBE" received signal SIGSEGV, Segmentation fault.
0xb2d02d04 in ?? ()
(gdb) bt
#0  0xb2d02d04 in ?? ()
#1  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
#2  0x092efa18 in hks::vm_call_internal(lua_State*, void*, int, hksInstruction const*) ()
#3  0x092bdcae in hksi_lua_pcall(lua_State*, int, int, int) ()
#4  0x0930de3c in Lua::Details::CallWithErrorHandling(lua_State*, unsigned int, unsigned int) ()
#5  0x0930e0e4 in Lua::LoadBuffer(lua_State*, char const*, unsigned int, char const*) ()
#6  0x09319b91 in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
#7  0x0931989e in LuaSystem::LuaStdLibLibrary::lInclude(lua_State*) ()
#8  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
```

I could tell right away that it had something to do with Lua, so next I set breakpoints at FLua_LoadFile to see what Lua file was being loaded during the crash and I started poking around in the Lua scripts, commenting and changing different lines. I found out the game was crashing at affinityquestmanager.lua at one specific line:

```lua
local gameSpeedModifier : number = Game.GetQuestFrequencyPercent() / 100;
```

This got me to thinking there was a problem with one of the Lua scripts and I spent quite a bit of time going down this road, modifying various Lua functions. I could see that the game would crash when mods are loaded any time `Game.GetQuestFrequencyPercent()` was called. And I identified other problematic functions. But ultimately I didn't make any progress on figuring out the cause of the crash.

It kept bugging me that the backtrace had `??`, so I went back to it. I guess normally the function name would go there, so this indicated a problem. `0xb2d02d04` is the address of the instruction it's trying to execute. But there doesn't seem to be anything at that memory address. That seemed like it goes beyond an issue with a Lua script.

So I did some more digging, and interestingly enough, when the game is first loaded there is a shared library at that address:

```
(gdb) info sharedlibrary
From        To          Syms Read   Shared Object Library
...
0xb2ab0b60  0xb2fd2da0  Yes         /home/user/.local/share/Steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/../libCvGameCoreDLL_Expansion1.so
```

But after I load a mod, the address changes:

```
0x6b4b0b60  0x6b9d2da0  Yes         /home/user/share/Steam/steamapps/common/Sid Meier's Civilization Beyond Earth/steamassets/../libCvGameCoreDLL_Expansion1.so
```

As best as I can tell, when mods are loaded, that shared library is unloaded and then loaded again, and so the address changes. But it seems the Lua interpreter is still using the original address when it calls the function, which causes the game to crash. This would explain why those same functions work just fine without mods; the shared library address never changes and everything is where the Lua interpreter expects it to be.

Sure enough, `Game.GetQuestFrequencyPercent()` is in that shared library:

```
(gdb) info function GetQuestFrequencyPercent
All functions matching regular expression "GetQuestFrequencyPercent":

File ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/Lua/CvLuaGame.h:
465: int CvLuaGame::lGetQuestFrequencyPercent(lua_State*);
```

```
$ grep GetQuestFrequencyPercent *
grep: libCvGameCoreDLL_BeyondEarth.so: binary file matches
grep: libCvGameCoreDLL_Expansion1.so: binary file matches
```

Next I thought the fix would be simple; just prevent the CvGameCoreDLL library from being reloaded, right? That way the address would never change. But this functionality is necessary in order to switch between Rising Tide and the base game.

Interestingly enough, if you go into the DLC menu and unload Rising Tide, the CvGameCoreDLL for Rising Tide is unloaded, then the CvGameCoreDLL for the base game is loaded at a different memory address. And the game works fine. Similarly, if you then enable Rising Tide, its CvGameCoreDLL is loaded again, similarly at a different memory address (not the original one). And the game still works fine.

So the problematic behaviour seems to be specific to mods for some reason.

Since a lot of the game's UI is in Lua, I found the Mods screen is controlled by modsbrowser.lua. It has a call to `Modding.ActivateEnabledMods()`. Replacing this with `Modding.ActivateAllowedDLC()` (which I found in another Lua file) made it so that the crash didn't happen. But mods weren't loaded either.

Loading and unloading shared libraries happens via the `dlclose` function, so I set a breakpoint on it:

```
(gdb) break dlclose
```

Then I ran the program and tried to load a mod. It hit the breakpoint and I did a backtrace:

```
Thread 13 "CivBE" hit Breakpoint 2, 0xf7481990 in dlclose () from /lib/i386-linux-gnu/libc.so.6
(gdb) bt
#0  0xf7481990 in dlclose () from /lib/i386-linux-gnu/libc.so.6
#1  0x08a074b2 in GameCore::UnloadDLL() ()
#2  0x08a5cd87 in CvModdingFrameworkAppSide::LoadCvGameCoreDLL() ()
#3  0x08a5ff30 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
#4  0x08a6160b in CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods() ()
#5  0x08c57f2a in cvLuaModdingLibrary::lActivateEnabledMods(lua_State*) ()
#6  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
```

Thankfully the original function names seem to have been left in the binary so it made debugging much easier.

Once I got that far, I started poking around with these functions, setting various breakpoints, to try to figure out at what point I could skip the reloading of CvGameCoreDLL.

I thought maybe I could skip `dlclose`, but that didn't work. I finally did an early return from `LoadCvGameCoreDLL` and that worked. However, I couldn't mod `LoadCvGameCoreDLL` to always return early because it's also used when the game is first started in order to ... well, load CvGameCoreDLL :)

So that brought me to `SetActiveDLCandMods`. I wondered if I could modify it to skip `LoadCvGameCoreDLL`. However, I found out that `SetActiveDLCandMods` is also used in many other situations, such as:

- When the game is first loaded, to load DLC
- Any time DLC is changed from the DLC menu
- When save games are loaded

... and so on.

Here's an example of when it's called when CivBE first starts:

```
Thread 13 "CivBE" hit Breakpoint 1, 0x08a5f4c2 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
(gdb) bt
#0  0x08a5f4c2 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
#1  0x089f9436 in CivBEApp::SetupDLL() ()
```

So I knew I needed to skip `LoadCvGameCoreDLL` in `SetActiveDLCandMods`, but only when mods were loaded. But then I thought that what if a mod is loaded that requires a different DLC? For example, let's say I start the game with Rising Tide, but I'm playing a mod that's not compatible with Rising Tide. If I block `LoadCvGameCoreDLL` when mods are used, then it will prevent the game from swapping out the Rising Tide CvGameCoreDLL with the base game CvGameCoreDLL.

I also tested loading a mod that required a different DLC that what was loaded, and surprisingly it worked! Unfortunately I don't think it's a common situation so it doesn't help much, but it did mean I could limit the scope of the workaround.

In the end, I came up with three ideas:

1. Skip LoadCvGameCoreDLL when mods are in use and when the DLC needed by a mod is already loaded
1. Skip LoadCvGameCoreDLL when the DLC needed by a mod is already loaded
1. Skip LoadCvGameCoreDLL when mods are in use

I think #1 would be ideal since that's the exact situation that seems to cause the crash. Unfortunately I knew I wouldn't have much space for the patch I wanted to create (more on that soon). I felt #3 would be doable too but then it might have problems with mods that required a different DLC, so that was the last resort.

So I decided I would try #2 first, and if I felt I had enough space I would try #1.

At this point I needed to look closer at SetActiveDLCandMods. gdb was helpful but Ghidra was even more helpful at this point. I noticed a lot of calls to "stopwatch" functions. It seems these are some kind of performance logs that end up in stopwatch.log in the game's logs folder.

Next I started looking at the code around where SetActiveDLCandMods was calling LoadCvGameCoreDLL:

```
$ objdump -S --start-address=0x08a5fef3 CivBE | less
...
 8a5fef3:       e8 34 bc 60 00          call   906bb2c <_ZNK12Localization16StringDictionary21NotifyDatabaseUpdatedEv@@Base>
 8a5fef8:       89 34 24                mov    %esi,(%esp)
 8a5fefb:       e8 48 74 24 00          call   8ca7348 <_ZN11cvStopWatchD1Ev@@Base>
 8a5ff00:       8d 83 a7 00 d4 fe       lea    -0x12bff59(%ebx),%eax
 8a5ff06:       89 44 24 04             mov    %eax,0x4(%esp)
 8a5ff0a:       8d b4 24 d0 01 00 00    lea    0x1d0(%esp),%esi
 8a5ff11:       89 34 24                mov    %esi,(%esp)
 8a5ff14:       c7 44 24 08 00 00 00    movl   $0x0,0x8(%esp)
 8a5ff1b:       00
 8a5ff1c:       e8 9b 73 24 00          call   8ca72bc <_ZN11cvStopWatchC1EPKcS1_@@Base>
 8a5ff21:       8b 84 24 40 08 00 00    mov    0x840(%esp),%eax
 8a5ff28:       89 04 24                mov    %eax,(%esp)
 8a5ff2b:       e8 20 c9 ff ff          call   8a5c850 <_ZN25CvModdingFrameworkAppSide17LoadCvGameCoreDLLEv@@Base>
 8a5ff30:       89 34 24                mov    %esi,(%esp)
 8a5ff33:       e8 10 74 24 00          call   8ca7348 <_ZN11cvStopWatchD1Ev@@Base>
 8a5ff38:       8d 83 d1 00 d4 fe       lea    -0x12bff2f(%ebx),%eax
```

Between `0x8a5ff00` and `0x8a5ff21` everything seems to be related to these stopwatch calls, so I set them all to `NOP` (`0x90`). Unfortunately this caused a crash after the call to LoadCvGameCoreDLL. I think because the following call is freeing the memory for the stopwatch function. So I set `0x8a5ff30` to `0x8a5ff38` to `NOP` as well. That worked, and I confirmed that stopwatch.log had one less line in it. But now I had some space to work with.

At that point I had to do a lot more poking around in SetActiveDLCandMods. I spent some time looking at the contents of the function parameters sent to it to see what kind of useful information would be in there. The first parameter is some kind of state object that had information on what mods and DLC were currently activated, among other things. The second parameter is the list of DLC needed. And the third parameter contains the list of enabled mods.

Then I found a function that compared two lists of DLC. All that was left was to figure out the assembly code to compare the list of activated DLC versus the list of needed DLC, and if they're the same to skip LoadCvGameCoreDLL. This took a lot of trial and error but ChatGPT helped immensely.

#### Steps used to create the patch file

ⓘ Since plain text files are easier to work with, this method uses plain text patch files, which is possible because we're working with small files and the length of the files isn't being changed.

- Create a patch file manually

  Patch files are pretty straightforward, each line has an address, byte, and optional comment, e.g.

  ```
  00a17f00: 8b # mov    0x844(%esp),%eax ; Put the address of list of needed DLC in $eax
  00a17f01: 84
  ```

- Or, edit the file with a hex editor and create the patch file using `xxd`:

  ```
  comm -13 <(xxd -c1 CivBE.bak) <(xxd -c1 CivBE) > CivBE.patch
  ```

  - `xxd -c1` dumps the files into hexadecimal text values, one byte per line
  - `comm -13` shows only the lines in the second file that differ from the first file

To apply the patch:

```
xxd -c1 -r CivBE.patch ~/.steam/steam/steamapps/common/Sid\ Meier\'s\ Civilization\ Beyond\ Earth/CivBE
```
