# Research into crashing with mods

## To do

- [x] Deleting the MODS directory before starting the game
- [x] Deleting the cache directory before starting the game
- [x] Mods with and without Lua
- [x] Local mods
- [x] Steam workshop mods
- [x] With and without DLC
- [x] Check Lua logs
- [x] Comment out Gameplayutilities include from affinityquestmanager.lua
- [x] Add a bunch of print statements to gameplayutilities.lua
- [x] Add a guard to prevent gameplayutilities.lua from being loaded more than once
- [ ] Check Lua scripts to see what is related to mods
  - Look for `Modding`
- [x] Disabled ASLR
- [ ] Examine how CvModdingFrameworkAppSide::SetActiveDLCandMods is called
  - [x] Document different call flows
  - [ ] Document CvModdingFrameworkAppSide::SetActiveDLCandMods parameters used in different call flows
  - [ ] See what's called after CvModdingFrameworkAppSide::SetActiveDLCandMods related to changing CvGameCoreDLL address in Lua interpreter
    - Nothing in SetupDLL or parent, not sure about lActivateAllowedDLC,
- [x] Try calling cvLuaModdingLibrary::lDeactivateMods before cvLuaModdingLibrary::lActivateEnabledMods?
- [ ] Try calling cvLuaModdingLibrary::lActivateAllowedDLC after cvLuaModdingLibrary::lActivateEnabledMods?
  - Why not, it gets called at startup and **twice** after changing DLC

## Current theory: Shared library location

#### Important

- Loading/unloading DLC through the main menu works fine, and calls the same functions
- Loading a mod (but not starting a game), then going back to the main menu, the game plays fine

#### Location of bug

- Lua function `Modding.ActivateAllowedDLC()` seems to reload DLC, but it works
- Lua function `Modding.ActivateEnabledMods()` reloads DLC in a way that causes the crash

- CvModdingFrameworkAppSide::SetActiveDLCandMods
  - Maybe something different is done when we're using mods versus when we're not
- Caller of CvModdingFrameworkAppSide::SetActiveDLCandMods
  - CvModdingFrameworkAppSide::SetActiveDLCandMods is run multiple times when mods aren't used. Maybe a necessary step is skipped?
- Something done after CvModdingFrameworkAppSide::SetActiveDLCandMods
  - Maybe the bug happens after CvModdingFrameworkAppSide::SetActiveDLCandMods, e.g. a necessary step is skipped when using mods, or alternatively

LuaSystem::LuaStdLibLibrary::RefreshIncludeFileList is called after LoadCvGameCoreDLL. My guess is this is what updates the references in the Lua interpreter

#### Cause

The game is crashing when certain Lua calls are made, such as `Game.GetQuestFrequencyPercent()`.

- These Lua calls call functions in CvGameCoreDLL
- CvGameCoreDLL is loaded when the game starts at a certain address
- When mods are used, CvGameCoreDLL is unloaded and then loaded again at a different address
  - I think this is probably to account for the fact that mods could use the expansion or the base game, so this is supposed to handle either
- But when the crash happens, the address seems to be in the original memory address range of CvGameCoreDLL, not the new range. Is this the cause of the crash?

## Fixes/workarounds

#### Idea 1: Update Lua references

The obvious fix would be that Lua should update its references to the new memory address. Maybe there's some kind of function that can be called to do this.

But CvModdingFrameworkAppSide::SetActiveDLCandMods is already calling LuaSystem::LuaStdLibLibrary::RefreshIncludeFileList ...

#### Idea 2: Prevent CvGameCoreDLL unload

- Tried returning early from CvGameCoreDLL but that causes a crash:

  ```
  (gdb) return (unsigned char)0
  Make selected stack frame return now? (y or n) y
  #0  0x08a5cd87 in CvModdingFrameworkAppSide::LoadCvGameCoreDLL() ()
  (gdb) cont
  Continuing.
  [New Thread 0xa9bdbac0 (LWP 293098)]
  [Thread 0xa9bdbac0 (LWP 293098) exited]

  Thread 13 "CivBE" received signal SIGSEGV, Segmentation fault.
  CvDllDatabaseUtility::ValidateGameDatabase (this=0xbacdb230) at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvDllDatabaseUtility.cpp:506
  506	../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvDllDatabaseUtility.cpp: No such file or directory.
  ```

  ```
  (gdb) return (unsigned char)1
  Make selected stack frame return now? (y or n) y
  #0  0x08a5cd87 in CvModdingFrameworkAppSide::LoadCvGameCoreDLL() ()
  (gdb) continue
  Continuing.
  [New Thread 0xb37ffac0 (LWP 309594)]
  [Thread 0xb37ffac0 (LWP 309594) exited]

  Thread 13 "CivBE" received signal SIGSEGV, Segmentation fault.
  CvDllDatabaseUtility::ValidateGameDatabase (this=0xb61af230) at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvDllDatabaseUtility.cpp:506
  506	../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvDllDatabaseUtility.cpp: No such file or directory.
  ```

- Is there something that's freeing the memory to the original CvGameCoreDLL

- Try next:

  - Break at start of LoadCvGameCoreDLL

    ```
    break *0x08a5c850
    ```

  - Return 0

    ```
    return (int)0
    ```

  Works!!

- Interesting note: loading/unloading the Rising Tide DLC manually in the game menu also changes the address, but playing a normal game (without mods) works fine. So there's something in the functionality specific to mods that is broken.

  - Loading/unloading DLC

- Ideas for workaround patch:
  - LoadCvGameCoreDLL needs to be called once. Modify it so that subsequent calls it returns??
  - Alternatively, modify SetActiveDLCandMods so it doesn't call LoadCvGameCoreDLL

## Workflow

#### Comparing different workflows

When game is first loaded

1. CivBEApp::SetupDLL
   1. cvContentPackageIDList::cvContentPackageIDList
   1. CvModdingFrameworkAppSide::GetAvailableDLC
   1. CvModdingFrameworkAppSide::SetActiveDLCandMods
      - ,,,0,1

```
#0  0x08a5f4c2 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
#1  0x089f9436 in CivBEApp::SetupDLL() ()
#2  0x089f6d4b in CivBEApp::AsynchInit(unsigned int) ()
#3  0x089f6910 in CivBEApp::Tick(AppHost::TickInfo const*) ()
#4  0x0903b6e8 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#5  0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#6  0x089f0ff8 in WinMain ()
```

When clicking Continue after the game first loads

1. cvLuaModdingLibrary::lActivateAllowedDLC
   1. cvContentPackageIDList::cvContentPackageIDList
   1. GameCore::GetPreGame
   1. CvModdingFrameworkAppSide::SetActiveDLCandMods
   - ,,,0, 0

Deactivate or activate any number of DLC in main menu, also when returning from Mods menu to main menu

1. cvLuaContentManager::lSetActive
   1. CvModdingFrameworkAppSide::DeactivateMods
      1. cvContentPackageIDList::cvContentPackageIDList
      1. cvContentPackageManager::GetAllPackageIDs
      1. cvContentPackageIDList::Remove
      1. SetActiveDLCandMods
         - ,,,0, 0
1. cvLuaModdingLibrary::lActivateAllowedDLC > CvModdingFrameworkAppSide::SetActiveDLCandMods
   - ,,,0, 0
1. cvLuaModdingLibrary::lActivateAllowedDLC > CvModdingFrameworkAppSide::SetActiveDLCandMods
   - ,,,0, 0

```
#0  0x08a5f4c2 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
#1  0x08a6188f in CvModdingFrameworkAppSide::DeactivateMods() ()
#2  0x08c30b85 in cvLuaContentManager::lSetActive(lua_State*) ()
```

Loading a mod through the Mods menu

1. cvLuaModdingLibrary::lActivateEnabledMods > CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods
   1. cvContentPackageIDList::cvContentPackageIDList
   1. GetActiveDLCForMods
   1. SetActiveDLCandMods
      - ,,,0, 0

#### Activating/Deactivating DLC through the main menu

This calls the same functions as when mods are loaded, but works

- CvModdingFrameworkAppSide::SetActiveDLCandMods > CvModdingFrameworkAppSide::LoadCvGameCoreDLL > GameCore::LoadDLL
- CvModdingFrameworkAppSide::SetActiveDLCandMods is called multiple times

- Called from CvModdingFrameworkAppSide::DeactivateMods when DLC is unchecked

#### When loading a mod

- CvModdingFrameworkAppSide::SetActiveDLCandMods > CvModdingFrameworkAppSide::LoadCvGameCoreDLL > GameCore::LoadDLL
- CvModdingFrameworkAppSide::SetActiveDLCandMods is only called once

1. CvModdingFrameworkAppSide::SetActiveDLCandMods calls CvModdingFrameworkAppSide::LoadCvGameCoreDLL
1. CvModdingFrameworkAppSide::LoadCvGameCoreDLL
   1. Calls GameCore::UnloadDLL to unload CvGameCoreDLL
   1. Calls GameCore::LoadDLL to load CvGameCoreDLL

```
#0  0x08a07482 in GameCore::UnloadDLL() ()
#1  0x08a5cd87 in CvModdingFrameworkAppSide::LoadCvGameCoreDLL() ()
#2  0x08a5ff30 in CvModdingFrameworkAppSide::SetActiveDLCandMods(cvContentPackageIDList const&, std::__1::list<ModAssociations::ModInfo, std::__1::allocator<ModAssociations::ModInfo> > const&, bool, bool) ()
#3  0x08a6160b in CvModdingFrameworkAppSide::ActivateModsAndDLCForEnabledMods() ()
#4  0x08c57f2a in cvLuaModdingLibrary::lActivateEnabledMods(lua_State*)
    ()
#5  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
#6  0x092efa18 in hks::vm_call_internal(lua_State*, void*, int, hksInstruction const*) ()
#7  0x092bdcae in hksi_lua_pcall(lua_State*, int, int, int) ()
#8  0x0930de3c in Lua::Details::CallWithErrorHandling(lua_State*, unsigned int, unsigned int) ()
#9  0x09235a04 in ForgeUI::ButtonControlBase::CallDelegates(unsigned int)
    ()
#10 0x09236162 in ForgeUI::ButtonControlBase::ProcessMouse(ForgeUI::InputStruct const&, bool, FGXVector2 const&) ()
#11 0x09235b2d in ForgeUI::ButtonControlBase::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#12 0x091a7b61 in ForgeUI::ControlBase::BaseProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#13 0x091a7a7b in ForgeUI::ControlBase::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#14 0x091a7b61 in ForgeUI::ControlBase::BaseProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#15 0x091a7a7b in ForgeUI::ControlBase::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#16 0x091a7b61 in ForgeUI::ControlBase::BaseProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#17 0x091a7a7b in ForgeUI::ControlBase::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
--Type <RET> for more, q to quit, c to continue without paging--
#18 0x091a3d55 in ForgeUI::ContextBase::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#19 0x091e3fb3 in ForgeUI::LuaContext::ProcessInput(ForgeUI::InputStruct const&, FGXVector2 const&) ()
#20 0x091c18fa in ForgeUI::ForgeUI_UIManager::ProcessInput(ForgeUI::InputStruct) ()
#21 0x08b3b51b in UIManager::ProcessInput(ForgeUI::InputStruct) ()
#22 0x091bc35b in ForgeUI::ProcessAppHostEvent(AppHost::Message const*)
    ()
#23 0x089f7f31 in CivBEApp::OnMessage(AppHost::Message*) ()
#24 0x09039834 in AppHost::_INTERNAL::WndProcEx(HWND__*, unsigned int, unsigned int, long, long (*)(HWND__*, unsigned int, unsigned int, long)) ()
#25 0x0903a149 in AppHost::_INTERNAL::WndProc(HWND__*, unsigned int, unsigned int, long) ()
#26 0x089c3469 in CallWindowProcW ()
#27 0x089c3343 in DispatchMessageW ()
#28 0x0903b513 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#29 0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#30 0x089f0ff8 in WinMain ()
#31 0x08987301 in ?? ()
#32 0x089bfcb5 in ThreadHANDLE::ThreadProc(void*) ()
#33 0xf7486c01 in ?? () from /lib/i386-linux-gnu/libc.so.6
#34 0xf752372c in ?? () from /lib/i386-linux-gnu/libc.so.6
```

## Crash

#### Backtrace

```
#0  0xb1f02d04 in ?? ()
#1  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
#2  0x092efa18 in hks::vm_call_internal(lua_State*, void*, int, hksInstruction const*) ()
#3  0x092bdcae in hksi_lua_pcall(lua_State*, int, int, int) ()
#4  0x0930de3c in Lua::Details::CallWithErrorHandling(lua_State*, unsigned int, unsigned int) ()
#5  0x0930e0e4 in Lua::LoadBuffer(lua_State*, char const*, unsigned int, char const*) ()
#6  0x09319b91 in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
#7  0x0931989e in LuaSystem::LuaStdLibLibrary::lInclude(lua_State*) ()
#8  0x09a6a058 in int hks::execute<(HksBytecodeSharingMode)0>(lua_State*, hksInstruction const*, int) ()
#9  0x092efa18 in hks::vm_call_internal(lua_State*, void*, int, hksInstruction const*) ()
#10 0x092bdcae in hksi_lua_pcall(lua_State*, int, int, int) ()
#11 0x0930de3c in Lua::Details::CallWithErrorHandling(lua_State*, unsigned int, unsigned int) ()
#12 0x0930e0e4 in Lua::LoadBuffer(lua_State*, char const*, unsigned int, char const*) ()
#13 0x0931687b in LuaSystem::LuaScriptSystem::pLoadFile(lua_State*) ()
#14 0x092ef967 in hks::vm_call_internal(lua_State*, void*, int, hksInstruction const*) ()
#15 0x092bdcae in hksi_lua_pcall(lua_State*, int, int, int) ()
#16 0x092efba0 in hksi_lua_cpcall(lua_State*, int (*)(lua_State*), void*) ()
#17 0x09310168 in Lua::Details::CCallWithErrorHandling(lua_State*, int (*)(lua_State*), void*) ()
#18 0x093166d0 in LuaSystem::LuaScriptSystem::LoadFile(lua_State*, wchar_t const*) ()
#19 0x08d73c2c in CvDLLScriptSystem::LoadFile(lua_State*, char const*) ()
#20 0x6a49ca79 in CvQuestLuaContext::Init (this=0x6e889e00) at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvQuests.cpp:1123
#21 0x6a238b20 in CvGame::reset (this=0xb1661e00, eHandicap=<optimized out>, bConstructorCall=<optimized out>)
    at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvGame.cpp:1402
#22 0x6a239e36 in CvGame::init (this=0xb1661e00, eHandicap=HANDICAP_DummyEnum_01) at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvGame.cpp:219
#23 0x6a2047c9 in CvDllGame::Init (this=0xdaf16270, eHandicap=HANDICAP_DummyEnum_01)
    at ../../../Civ5/Src/App/CvGameCoreDLL_Expansion1/CvDllGame.cpp:309
#24 0x08d746a8 in CvInitMgr::InitGame() ()
#25 0x08d75f65 in CvInitMgr::GameCoreNew() ()
#26 0x08d3b7ae in NetInitGame::Execute(FNetSessionIFace*) const ()
#27 0x0910b2fd in FNetMessage::Process(FNetSessionIFace*) const ()
#28 0x08adaa74 in NetProxy::HandleMessage(FNetMessage&) ()
#29 0x08ae3abf in NetProxySessionCallbacks::MessageReceived(FNetMessage&) ()
#30 0x09131ece in FNetSession::HandleMessage(FNetMessage&) ()
#31 0x09131d6c in FNetSession::MessageReceived(FNetMessage&, bool) ()
#32 0x09140212 in FNetCallbacksENet::MessageReceived(long, unsigned char const*, unsigned int, bool) ()
#33 0x09128665 in FNetAccessENet::Update() ()
#34 0x09132157 in FNetSession::ProcessNetwork() ()
#35 0x0912aed3 in FNetMessageSync::Update(float) ()
#36 0x0912f039 in FNetSession::Update(float) ()
#37 0x08ad7091 in NetProxy::Update(float) ()
#38 0x08a05392 in CivBEGameApp::UpdateNetwork(float) const ()
#39 0x08ad1fbc in MainMenuState::Update(float) ()
#40 0x089f7b05 in CivBEApp::OnIdle() ()
#41 0x089f6859 in CivBEApp::Tick(AppHost::TickInfo const*) ()
#42 0x0903b6e8 in AppHost::RunApp(int, char**, AppHost::Application*) ()
#43 0x0903a8d0 in AppHost::RunApp(char*, AppHost::Application*) ()
#44 0x089f0ff8 in WinMain ()
#45 0x08987301 in ?? ()
#46 0x089bfcb5 in ThreadHANDLE::ThreadProc(void*) ()
#47 0xf7486c01 in ?? () from /lib/i386-linux-gnu/libc.so.6
#48 0xf752372c in ?? () from /lib/i386-linux-gnu/libc.so.6
```

#### Game.GetQuestFrequencyPercent()

Game is crashing in affinityquestmanager.lua on this line

```lua
local gameSpeedModifier : number = Game.GetQuestFrequencyPercent() / 100;
```

Hack; replace with:

```lua
local gameSpeedModifier = 1;
```

- Game.GetQuestFrequencyPercent() is in libCvGameCoreDLL_Expansion1.so at `0x00512d04`
  - But memory address during crash is at `0xb2d02d04` ...
  - A difference of `0xB27F0000`
- Changing it to `Game:GetQuestRewardPercent()` crashes at `0xb2d02d54
  - ... which is at `00512d54`
- libCvGameCoreDLL_Expansion1.so is at `0x666b0b60  0x66bd2da0`
- 0x666b0b60 + 0x00512d04 = 0x66BC3864

Getting around that crashes at `0xb2afa660`

- - = `30A660`

#### Game.GetGameSpeedType()

Crashing at the top of QuestRewards.lua

Hack: replace:

```lua
local gameSpeedType = Game.GetGameSpeedType();
```

with

```lua
local gameSpeedType = GameInfo.GameSpeeds["GAMESPEED_STANDARD"].ID;
```

#### Stopwatch.log

[197.309] , Discovering Base Game Maps, 0.000205
[225.142] , Discovering Base Game Maps, 0.000211
[225.143] , Discovering Base Game Map Scripts, 0.000533
[225.143] , Discovering Modder Map Scripts, 0.000057

#### Debug

Thread 13 "CivBE" hit Breakpoint 1, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\gameplay\lua\serializationutilities.lua"

Thread 13 "CivBE" hit Breakpoint 1, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\gameplayutilities.lua"

Thread 13 "CivBE" hit Breakpoint 1, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\affinityquestmanager.lua"

Thread 13 "CivBE" hit Breakpoint 1, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\gameplayutilities.lua"

## Without mods

#### Stopwatch.log

```
[208.057] , Discovering Base Game Maps, 0.000429
[229.319] , Discovering Base Game Maps, 0.000428
[229.320] , Discovering Base Game Map Scripts, 0.000688
[229.320] , Discovering Modder Map Scripts, 0.000133
[667.369] , CvMapGenerator - GetMapInitData(), 0.000002
[667.993] , CvMapGenerator - GenerateRandomMap(), 0.615459
[667.999] , CvMapGenerator - GetGameInitialItemsOverrides(), 0.000003
```

### Debug

Thread 10 "CivBE" hit Breakpoint 2, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\gameplay\lua\serializationutilities.lua"

Thread 10 "CivBE" hit Breakpoint 2, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\gameplayutilities.lua"

Thread 10 "CivBE" hit Breakpoint 2, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\affinityquestmanager.lua"

Thread 10 "CivBE" hit Breakpoint 2, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\dlc\expansion1\Gameplay\lua\gameplayutilities.lua"

Thread 10 "CivBE" hit Breakpoint 2, 0x093199eb in LuaSystem::FLua_LoadFile(lua_State*, wchar_t const*) ()
(gdb)
"Assets\gameplay\lua\stationquestmanager.lua"
