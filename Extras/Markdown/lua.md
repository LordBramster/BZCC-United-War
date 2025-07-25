# ////////// UNITED WAR //////////
Learning some Lua shit 🌛

## Functions
Here's what I am using in my `.lua` code.
### Code Header
```lua
--[[
  _    _ _   _ _____ _______ ______ _____   __          __     _____  
 | |  | | \ | |_   _|__   __|  ____|  __ \  \ \        / /\   |  __ \ 
 | |  | |  \| | | |    | |  | |__  | |  | |  \ \  /\  / /  \  | |__) |
 | |  | | . ` | | |    | |  |  __| | |  | |   \ \/  \/ / /\ \ |  _  / 
 | |__| | |\  |_| |_   | |  | |____| |__| |    \  /\  / ____ \| | \ \ 
  \____/|_| \_|_____|  |_|  |______|_____/      \/  \/_/    \_\_|  \_\

Author: SirBrambley (Special thanks to F9Bomber, JJ, GBD, N1, and the entire community)
References:
1. https://steamcommunity.com/sharedfiles/filedetails/?id=1488402495
2. https://www.lua.org/docs.html

]] --
```

### Common Tables
```lua
local Mission = {
    -- INTEGERS --
    TPS = 0,
    MissionTimer = 0,
    TurnCounter = 0,
    -- HANDLES --
    Player,
    Temp,
    -- TEAM --
    EnemyTeam = 6,
    PlayerTeam = 1,
    AllyTeam = 3,
    Ally2Team = 4,
    -- GAME --
    SetupStart = false,
    StartPhase = false,
    ExtractPhase = false,
    GameOver = false
}
```
```lua
local Audio = {
    current = nil, -- handle for playing audio
    isPlaying = false
}
```
```lua
local Dropship = {
    RunSequence = false,
    SpawnTime = nil,
    LandedTime = nil,
    DepartedTime = nil,
    HasSpawned = false,
    HasLanded = false,
    IsDeparting = false,
    HasDeparted = false,
    IsGone = false,
    IsReturning = false
}
```
```lua
local Pathpoint = {
    ExtractionPoint = "extract",  -- "extract_1_X"
    SpawnPlayerPoint = "player",
    DropshipLandRootPoint = "dropship", -- "dropship_1_X"
    DropshipLandCargoSpawnSuffix = "_spawn",
    DropshipLandCargoGotoSuffix = "_goto"
}
```
```lua
local GameMaster = {
    SpawnWave = false,
    SpawnWaveTime = nil,
    currentGoal = nil,
    PlayerNearAnyGoal = false,
    PlayerNearExtraction = false,
    GoalsCompleted = 0
}
```

```lua
local IFace = {
   test_option = "script.menu.test",
   test_vehicle = "script.menu.vehicle",
   leave_menu = "script.menu.exit"
}
```

### Dividers

```lua
----------------------------------------------------------------------------------------
------------------------------------- TEST SECTION -------------------------------------
----------------------------------------------------------------------------------------
```