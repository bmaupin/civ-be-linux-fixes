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

## Crash

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
