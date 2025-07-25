--[[
  _    _ _   _ _____ _______ ______ _____   __          __     _____  
 | |  | | \ | |_   _|__   __|  ____|  __ \  \ \        / /\   |  __ \ 
 | |  | |  \| | | |    | |  | |__  | |  | |  \ \  /\  / /  \  | |__) |
 | |  | | . ` | | |    | |  |  __| | |  | |   \ \/  \/ / /\ \ |  _  / 
 | |__| | |\  |_| |_   | |  | |____| |__| |    \  /\  / ____ \| | \ \ 
  \____/|_| \_|_____|  |_|  |______|_____/      \/  \/_/    \_\_|  \_\

Author: SirBrambley (Special thanks to JJ, F9Bomber, GBD, and the community)
References:
1. https://steamcommunity.com/sharedfiles/filedetails/?id=1488402495
2. https://www.lua.org/docs.html

]] --

local Mission = {
   --Integers--
   TPS = 0,
   MissionTimer = 0,
   TurnCounter = 0,
   --Handles--
   Recycler,
   enemyRecycler,
   Player,
   Temp,
   --Team--
   EnemyTeam = 6,
   PlayerTeam = 1,
   AllyTeam = 3,
   Ally2Team = 4,
   --Booleans--
   recyclerPresent = false,
   recyclerDeployed = false,
   recyclerIsAlive = false,
   enemyRecyclerDeployed = false,
   enemyRecyclerIsAlive = false,
   NotAroundBool = false,
   -- GAME --
   m_StartMenu = true,
   m_StartDone = false,
   m_GameTimer = nil,
   m_SpawnWave = false,
   m_SpawnWaveTime = nil,
   m_GameOver = false,
   M_Extraction = false,
   --Dropship--
   DropshipSequence = false,
   DropshipSpawnTime = nil,
   DropshipLandedTime = nil,
   DropshipDepartedTime = nil,
   DropshipSpawned = false,
   DropshipLanded = false,
   DropshipDeparting = false,
   DropshipDeparted = false,
   DropshipGone = false,
   DropshipReturning = false,
   DropshipPath = nil,
   --Objectives--
   Goal = nil,
   NearAnyGoal = false,
   ObjectivesDone = 0,
   NearExtraction = false,
   -- AUDIO --
   audioIntro = nil,  -- declare globally
   audioPlaying = true -- declare globally
}

local GoalSpawn = {
   --Booleans--
   spawn1Taken = false,
   spawn2Taken = false,
   spawn3Taken = false,
   spawn4Taken = false,
   spawn5Taken = false,
   spawn6Taken = false,
   spawn7Taken = false,
   spawn8Taken = false,
   spawn9Taken = false
}

local Goal = {}

local IFace = {
   test_option = "script.menu.test",
   test_vehicle = "script.menu.vehicle",
   test_vehicleFBX = "script.menu.vehicleFBX",
   test_myside = "script.menu.myside",

   difficulty = "script.menu.difficulty",
   myforce = "script.menu.myforce",
   hisforce = "script.menu.hisforce",

   leave_menu = "script.menu.exit"
}

local LookupStartVehicle = {
   ["Scout"] = {
      classnames = {"fvscout", "ivscout"},
      models = {"fvscout_skel.fbx", "ivscout00.fbx"}
   },
   ["Recon"] = {
      classnames = {"fvsent", "ivmbike"},
      models = {"fvsent_skel.fbx", "ivmbik00.fbx"}
   },
   ["Tank"] = {
      classnames = {"fvtank", "ivtank"},
      models = {"fvtank_skel.fbx", "ivtank00.fbx"}
   },
   ["Missile Tank"] = {
      classnames = {"fvarch", "ivmisl_dm"},
      models = {"fvlancer_skel.fbx", "ivmisl00.fbx"}
   },
   ["Assault Tank"] = {
      classnames = {"fvatank", "ivatank"},
      models = {"fvtitan_skel.fbx", "ivatnk00.fbx"}
   },
   ["Walker"] = {
      classnames = {"fvwalk", "ivwalk"},
      models = {"fvwalk_skel.fbx", "ivwalk_skel.fbx"}
   }
}

-- REQUIRED --
function Save()
   return Mission
end

-- REQUIRED --
function Load(...)
   if select("#", ...) > 0 then
      Mission = ...
   end
end

 -- REQUIRED: This function is called when an object appears in the game. --
function AddObject(handle)
end

 -- REQUIRED: This function is called when an object is deleted in the game. --
function DeleteObject(handle)
   local ObjODF = GetOdf(handle);
   
   if (GetTeamNum(handle) == Mission.EnemyTeam) then
      if (ObjODF == "fostand02.odf") then --unnamed_fostand01
         ObjectiveDestroyed()
         Mission.ObjectivesDone = Mission.ObjectivesDone + 1
      end
   end
end

-- REQUIRED: This function is called upon loading of the game --
function InitialSetup()
   Mission.TPS = EnableHighTPS()

   -- AllowRandomTracks(true)

	local preloadODF = {
		"ivscav",
		"ivdrop",
	}

   -- local preloadAudios = {
   -- }

	for k,v in pairs(preloadODF) do
		PreloadODF(v)
	end
end

-- REQUIRED: This function is called upon the first frame --
function Start()
   local rollGoalSpawnCount = 0
   local rollGoalSpawn = 0

   Mission.m_MyForce = GetInstantMyForce();
   Mission.m_CompForce = GetInstantCompForce();
   Mission.m_Difficulty = GetInstantDifficulty();
   Mission.Player = GetPlayerHandle(1)

   SetAutoGroupUnits(false)

   SetupAlliesTeams()
   SpawnGoals()
   SpawnAllyStartingVehicles()
   BeginDropshipSequence("dropship_1") -- TODO
   StartCockpitTimer(300, 240, 270) -- 300s=5mins, 240=4mins, 270=4:30mins
   -- Goto(BuildObject("ivcargo00", Mission.Ally2Team, "tank1"), "RecyclerEnemy", 1)

   IFace_EnterMenuMode()
   IFace_Exec("bzgame_script_menu.cfg")
   IFace_Activate("TestPlay")
   iface_startmenuvehicle_prev = IFace_GetString(IFace.test_vehicleFBX);
   CameraReady()
   FreeCamera()
   SetCameraPosition(SetVector(0, 50, 50), SetVector(-90, 15, -20)) -- SetVector(0, 100, 0)
   -- SetCameraPosition(SetVector(0, 100, 100), SetVector(-90, 15, -20)) -- SetVector(0, 100, 0)

   SetInitialConfigVars()
end

 -- REQUIRED: This function runs on every frame. --
function Update()
   Mission.TurnCounter = Mission.TurnCounter + 1 -- required
   Mission.Player = GetPlayerHandle(1) -- track player

   if not Mission.m_StartMenu then -- IF NOT IN START MENU
      ----------------------------------------------------------------------------------------
      if (Mission.m_StartDone == false) then
         Mission.m_StartDone = true

         PreparePlayerShip(Mission.Player) -- SET PLAYER SHIP BASED ON SELECTION IN AWARE_V12

         -- Display a fullscreen color fade in at start (SP only)
         -- SetColorFade(2, 0.75, Make_RGBA(0, 0, 0, 255))
         SetColorFade(6, 0.75, Make_RGB(0, 0, 0, 255));

         -- SHOW OBJECTIVE BANNER
         -- IFace_EnterMenuMode()
         IFace_Exec("bzgame_script_banners.cfg")
         -- IFace_FadeIn("BannerObjectiveNewFade"); -- MAYBE GBD WILL ADD ONE DAY
         IFace_Activate("BannerObjectiveNewFade");

         -- PLAY INTRO
         Mission.audioIntro = AudioMessage("vo_ia_goal_intro.wav")
         Mission.audioPlaying = true -- because... well duh
         AddObjective(">>> HOSTILE THREAT HIGH >>>\n\n>DESTROY ALL OBJECTIVES.\n", "CYAN", 10.0)

         -- AddScrap(1, 20)

         Mission.m_SpawnWaveTime = GetTimeNowSeconds() -- START COUNTING TO SPAWN MORE UNITS
         Mission.m_SpawnWave = false

      end
      ----------------------------------------------------------------------------------------

      if Mission.audioPlaying then
         IntroBannerEnd()
      end

      ----------------------------------------------------------------------------------------
      RunDropshipCargoSequence() -- TODO
      
      if Mission.m_SpawnWave then
         SpawnMoreEnemyUnits()
         Mission.m_SpawnWave = false
         Mission.m_SpawnWaveTime = GetTimeNowSeconds()
         AddObjective(">>> MORE HOSTILES DETECTED >>>", "RED", 8.0)
      else
         Mission.m_SpawnWave = WaitUntilTime(Mission.m_SpawnWaveTime, 120) --180 TODO
      end
      ----------------------------------------------------------------------------------------
      GameEndConditions()

   else -- WAIT UNTIL START MENU DONE
      local currTime = GetTime()

      iface_startmenutest = IFace_GetInteger(IFace.test_option);           -- GET TEST OPTION
      iface_startmenuvehicle = IFace_GetString(IFace.test_vehicle);        -- GET VEHICLE ODF NAME
      iface_startmenuvehicleFBX = IFace_GetString(IFace.test_vehicleFBX);  -- GET VEHICLE MODEL NAME
      iface_startmenurace = IFace_GetInteger(IFace.test_myside);           -- GET PLAYER RACE
      iface_startmenuexit = IFace_GetInteger(IFace.leave_menu);

      playerVehicleFBX = GetUnitModelFilename(iface_startmenuvehicle, iface_startmenurace)
      -- playerVehicleODF = GetUnitClassName(iface_startmenuvehicle, iface_startmenurace) --TODO: UNUSED

      -- print("vehicleSelected=" .. iface_startmenuvehicle)
      -- -- print("vehicleClass=" .. playerVehicleODF) --TODO: UNUSED
      -- print("vehicleModel=" .. playerVehicleFBX)
      -- print("vehicleClassPrev=" .. iface_startmenuvehicle_prev)

      if playerVehicleFBX == iface_startmenuvehicle_prev then
         print("NOT A NEW MODEL :: " .. playerVehicleFBX)
      else
         -- SET STRING ONCE (USING PREV CHECK) TO UPDATE VIEWER IN UI
         IFace_SetString(IFace.test_vehicleFBX, playerVehicleFBX)
         iface_startmenuvehicle_prev = iface_startmenuvehicleFBX
         print("SHOW NEW MODEL :: " .. playerVehicleFBX)
      end

      -- EXIT MENU IF BUTTON IS PRESSED AND VAR IS UPDATED
      if iface_startmenuexit == 1 then
         
         -- DEACTIVATE CONFIG'S CUSTOM WINDOW
         IFace_Deactivate("TestPlay")
         -- CLOSE MENU SCALING
         IFace_ExitMenuMode();

         -- DEACTIVATE CONFIG'S CUSTOM DIFFICULTY IMAGE
         if Mission.m_Difficulty == 1 then
            IFace_Deactivate("TestDifficultyMedium")
         elseif Mission.m_Difficulty == 2 then
            IFace_Deactivate("TestDifficultyHard")
         else
            IFace_Deactivate("TestDifficultyEasy")
         end

         -- CLEANUP CAMERA
         FreeFinish()
         CameraFinish()

         -- END LOOP
         Mission.m_StartMenu = false
      end

   end -- START MENU LOOP

end

----------------------------------------------------------------------------------------
-- GOAL SETUP
local function isAllSpotsTaken()
   for i = 1, 9 do
       if not GoalSpawn["spawn" .. i .. "Taken"] then
           return false
       end
   end
   return true
end

function GetUnitClassName(humanName, race)
   local entry = LookupStartVehicle[humanName]
   if entry and entry.classnames and entry.classnames[race + 1] then
       return entry.classnames[race + 1]
   else
       return nil
   end
end


function GetUnitModelFilename(humanName, race)
   local entry = LookupStartVehicle[humanName]
   if entry and entry.models and entry.models[race + 1] then
       return entry.models[race + 1]
   else
       return nil
   end
end

function SetInitialConfigVars()
   IFace_SetString(IFace.myforce, ConvertIntForceSize(Mission.m_MyForce))
   IFace_SetString(IFace.hisforce, ConvertIntForceSize(Mission.m_CompForce))
   -- IFace_SetString(IFace.difficulty, ConvertIntDifficulty(Mission.m_Difficulty))

   if Mission.m_Difficulty == 1 then
      IFace_Activate("TestDifficultyMedium")
   elseif Mission.m_Difficulty == 2 then
      IFace_Activate("TestDifficultyHard")
   else
      IFace_Activate("TestDifficultyEasy")
   end
end

function ConvertIntForceSize(force)
   if force == 1 then
      return "Light"
   elseif force == 2 then
      return "Medium"
   elseif force == 3 then
      return "Heavy"
   else
      return "None"
   end
end

function ConvertIntDifficulty(difficulty)
   if difficulty == 1 then
      return "icon_menu_skill_m.tga"
   elseif difficulty == 2 then
      return "icon_menu_skill_h.tga"
   else
      return "icon_menu_skill_e.tga"
   end
end

function IntroBannerEnd()
   if IsAudioMessageDone(Mission.audioIntro) then
      Mission.audioPlaying = false

      -- UI
      IFace_Deactivate("BannerObjectiveNewFade");
      IFace_ExitMenuMode();

      SpawnEnemyStartingVehicles()
   end
end

function ObjectiveDestroyed()
   AddObjective(">>> OBJECTIVE DESTROYED, WEEL DONE >>>", "GREEN", 8.0)
   AudioMessage("vo_ia_goal_x.wav")
end

function SetupAlliesTeams()
   Ally(Mission.AllyTeam, Mission.PlayerTeam);
   Ally(Mission.Ally2Team, Mission.PlayerTeam);
   Ally(Mission.PlayerTeam, Mission.AllyTeam);
   Ally(Mission.PlayerTeam, Mission.Ally2Team);
   Ally(Mission.AllyTeam, Mission.Ally2Team);
   Ally(Mission.Ally2Team, Mission.AllyTeam);

   SetTeamColor(Mission.AllyTeam, 75, 140, 220) -- Light Blue for ISDF
   SetTeamNameForStat(Mission.AllyTeam, "Allies")
   SetTeamNameForStat(Mission.Ally2Team, "Allies")
   SetTeamNameForStat(Mission.PlayerTeam, "Your Squad")

end

function WaitUntilTime(prevTime, waitTime)
   local currentTime = GetTimeNowSeconds()
   if (currentTime - prevTime) >= waitTime then
      return true
   end
   return false
end

function GetTimeNowSeconds()
   return TurnsToSeconds(Mission.TurnCounter)
end

function BeginDropshipSequence(dropshipPath)
   Mission.DropshipSequence = true
   Mission.DropshipPath = dropshipPath

   -- CLEAR ALL DROPSHIP VALUES FOR SAFETY
   Mission.DropshipSpawnTime = nil
   Mission.DropshipLandedTime = nil
   Mission.DropshipDepartedTime = nil
   Mission.DropshipSpawned = false
   Mission.DropshipLanded = false
   Mission.DropshipDeparting = false
   Mission.DropshipDeparted = false
   Mission.DropshipGone = false
   Mission.DropshipReturning = false

   Mission.DropshipSpawnTime = GetTimeNowSeconds() -- gives us the time that this sequence started
   SpawnDropshipLanding(dropshipPath) -- start sequence @ "dropship_1"
end

function RunDropshipCargoSequence()

   if not Mission.m_GameOver then -- DON'T DO ANYTHING IF THE GAME IS OVER
      -- DROPSHIP SEQUENCE
      if Mission.DropshipSequence then
         if not Mission.DropshipLanded then
            Mission.DropshipLanded = WaitUntilTime(Mission.DropshipSpawnTime, 18)-- wait #secs since this sequence started
         else
            if not Mission.DropshipSpawned then
               AddObjective("- Dropship has landed.", "YELLOW", 5.0)
               RemoveDropshipHandle("unnamed_ivdrop_land")
               SpawnDropshipLandedCargo("ivdrop", Mission.DropshipPath)
               Mission.DropshipSpawned = true -- prevents multiple spawning over and over
               Mission.DropshipLandedTime = GetTimeNowSeconds()
               AddObjective("- Dropship has delivered it's cargo.", "YELLOW", 5.0)
               AddScrap(1, 10)
            else
               if not Mission.DropshipDeparting then
                  Mission.DropshipDeparting = WaitUntilTime(Mission.DropshipLandedTime, 10) -- waiting until take off
               else
                  if not Mission.DropshipDeparted then
                     TakeoffDropshipLanded("unnamed_ivdrop")
                     Mission.DropshipDeparted = true
                     Mission.DropshipDepartedTime = GetTimeNowSeconds()
                     AddObjective("- Dropship is departing.", "RED", 5.0)
                  else
                     if not Mission.DropshipGone then
                        Mission.DropshipGone = WaitUntilTime(Mission.DropshipDepartedTime, 30) -- waiting until it flys far away
                     else
                        RemoveDropshipHandle("unnamed_ivdrop")
                        Mission.DropshipGone = true
                        AddObjective("- Dropship returned to orbit.", "GREEN", 5.0)
                        
                        -- REPEAT
                        Mission.DropshipSequence = false
                        Mission.DropshipReturnTime = GetTimeNowSeconds()
                     end
                  end
               end
            end
         end
      else -- START OVER AGAIN in 35 SECONDS
         if not Mission.DropshipReturning then
            Mission.DropshipReturning = WaitUntilTime(Mission.DropshipReturnTime, 35) -- WILL START IF YOU DO NOT HAVE THIS DISABLED AT START
         else
            -- RANDOMLY CHOOSE NEXT LOCATION
            local rollNextDropship = GetRandomInt(1, 2)
            ClearObjectives()

            if rollNextDropship == 1 then
               BeginDropshipSequence("dropship_1")
               AddObjective("- Dropship landing at SITE-01.", "YELLOW", 5.0)
            else
               BeginDropshipSequence("dropship_2")
               AddObjective("- Dropship landing at SITE-02.", "YELLOW", 5.0)
            end
         end
      end -- DROPSHIP SEQUENCE END
   end -- IF NOT GAME OVER END
end

function RunDropshipExtractSequence()
   if not Mission.DropshipLanded then
      Mission.DropshipLanded = WaitUntilTime(Mission.DropshipSpawnTime, 18)
   else
      if not Mission.DropshipSpawned then
         ClearObjectives()
         AddObjective(">>> DROPSHIP HAS LANDED.\nEXTRACT IMMEDIATELY", "RED", 5.0)
         RemoveDropshipHandle("unnamed_ivdrop_land")
         SpawnDropshipLanded("ivdrop", Mission.DropshipPath)
         Mission.DropshipSpawned = true -- prevents multiple spawning over and over
         Mission.DropshipLandedTime = GetTimeNowSeconds()
      end
   end
end

function SpawnDropshipLanding(dropPath)
   local dropship = BuildObject("ivdrop_land", Mission.Ally2Team, dropPath)
   SetAngle(dropship, 0)
   SetAnimation(dropship, "land", 1)
   StartSoundEffect("droppass.wav", dropship)
end

function RemoveDropshipHandle(getHandle)
   local foo = GetHandle(getHandle) --unnamed_ivdrop_land
   RemoveObject(foo)
end

function SpawnDropshipLandedCargo(bODF, spawnPathRoot)
   local cargo = SpawnRandomCargo(spawnPathRoot .. "_spawn")  -- TODO SPAWN ARGS: dropship_#_spawn

   local dropship = BuildObject(bODF, Mission.Ally2Team, spawnPathRoot)
   SetObjectiveName(dropship, "Dropship Arrived");
   SetObjectiveOn(dropship)
   SetAngle(dropship, 0)
   SetAnimation(dropship, "deploy", 1)
   StartSoundEffect("dropdoor.wav", dropship)
   Goto(cargo, spawnPathRoot .. "_goto", 0)  -- TODO SPAWN ARGS: dropship_#_goto
end

function SpawnDropshipLanded(bODF, spawnPathRoot)
   local dropship = BuildObject(bODF, Mission.Ally2Team, spawnPathRoot)
   SetObjectiveName(dropship, "Dropship Arrived");
   SetObjectiveOn(dropship)
   SetAngle(dropship, 0)
   SetAnimation(dropship, "deploy", 1)
   StartSoundEffect("dropdoor.wav", dropship)
end

function TakeoffDropshipLanded(getHandle)
   local dropship = GetHandle(getHandle) --"unnamed_ivdrop"
   SetObjectiveOff(dropship)
   SetAnimation(dropship, "takeoff", 1);
   StartSoundEffect("dropleav.wav", dropship);
end

function SpawnRandomCargo(cargoSpawn)
   local rollCargo = GetRandomInt(1, 5)
   -- TODO
   if rollCargo == 1 then
      return BuildObject("ivmisldm", Mission.PlayerTeam, cargoSpawn)
   elseif rollCargo == 2 then
      return BuildObject("ivtank13", Mission.PlayerTeam, cargoSpawn)
   elseif rollCargo == 3 then
      return BuildObject("ivscout", Mission.PlayerTeam, cargoSpawn)
   elseif rollCargo == 4 then
      return BuildObject("ivmbike", Mission.PlayerTeam, cargoSpawn)
   else
      return BuildObject("ivscav", Mission.PlayerTeam, cargoSpawn)
   end
end

function SpawnAllyStartingVehicles()
   -- BuildObject("ivscav", Mission.PlayerTeam, "Recycler")

   -- PLAYER FORCE = MEDIUM+
   if (Mission.m_MyForce > 0) then
      BuildObject("ivscout", Mission.PlayerTeam, "tank1")

      -- PLAYER FORCE = LARGE+
      if (Mission.m_MyForce > 1) then
         BuildObject("ivmisl", Mission.PlayerTeam, "tank2")

         -- PLAYER FORCE = XLARGE+
         if (Mission.m_MyForce > 2) then
            BuildObject("ivtank", Mission.PlayerTeam, "tank3")
         end

      end
   end
end

function SpawnEnemyStartingVehicles()
   if (Mission.m_CompForce > 0) then
      Attack(BuildObject("fvsent", Mission.EnemyTeam, "tankEnemy1"), Mission.Player, 1)
      Attack(BuildObject("fvscout", Mission.EnemyTeam, "turretEnemy1"), Mission.Player, 1)
      BuildObject("fvturr", Mission.EnemyTeam, "hold1")
      BuildObject("fvsent", Mission.EnemyTeam, "stage1")
      BuildObject("fvsent", Mission.EnemyTeam, "stage2")
      if (Mission.m_CompForce > 1) then
         Attack(BuildObject("fvarch", Mission.EnemyTeam, "tankEnemy2"), Mission.Player, 1)
         Attack(BuildObject("fvscout", Mission.EnemyTeam, "turretEnemy2"), Mission.Player, 1)
         BuildObject("fvturr", Mission.EnemyTeam, "gtow4")
         BuildObject("fvsent", Mission.EnemyTeam, "stage3")
         BuildObject("fvsent", Mission.EnemyTeam, "hold2")
         if (Mission.m_CompForce > 2) then
            Attack(BuildObject("fvtank", Mission.EnemyTeam, "tankEnemy3"), Mission.Player, 1)
            BuildObject("fbspir", Mission.EnemyTeam, "gtow5")
            BuildObject("fbspir", Mission.EnemyTeam, "gtow3")
         end
      end
   end
end


function PreparePlayerShip(playerHandle)
   -- local getPlayerSide = GetInstantMySide() -- GetVarItemInt("options.instant.bool2") -- TODO
   -- 0=SCION, 1=ISDF to mimic MySide=# from Aware_V12/13
   SpawnPlayerShip(playerHandle, GetUnitClassName(iface_startmenuvehicle, iface_startmenurace)) --getPlayerSide
end

function SpawnPlayerShip(playerHandle, playerODF)
   local tempPlayerHandle = GetPlayerHandle();
   SetAsUser(BuildObject(playerODF, 1, playerHandle), 1);
   RemoveObject(tempPlayerHandle);    
end

function SpawnMoreEnemyUnits()
   if (Mission.m_CompForce > 0) then
      Attack(BuildObject("fvsent", Mission.EnemyTeam, "tankEnemy1"), Mission.Player, 1)
      Attack(BuildObject("fvscout", Mission.EnemyTeam, "turretEnemy1"), Mission.Player, 1)
      if (Mission.m_CompForce > 1) then
         Attack(BuildObject("fvarch", Mission.EnemyTeam, "tankEnemy2"), Mission.Player, 1)
         Attack(BuildObject("fvarch", Mission.EnemyTeam, "turretEnemy2"), Mission.Player, 1)
         if (Mission.m_CompForce > 2) then
            Attack(BuildObject("fvtank", Mission.EnemyTeam, "tankEnemy3"), Mission.Player, 1)
            Attack(BuildObject("fvtank", Mission.EnemyTeam, "tankEnemy3"), Mission.Player, 1)
         end
      end
   end
end

function SpawnGoals()
   local rollGoalSpawnCount = 0
   
   if Mission.m_Difficulty == 0 then
      rollGoalSpawnCount = GetRandomInt(1, 2)
   elseif Mission.m_Difficulty == 1 then
      rollGoalSpawnCount = GetRandomInt(2, 6)
   else
      rollGoalSpawnCount = GetRandomInt(3, 6)
   end

   -- print("rollGoalSpawnCount :: ", rollGoalSpawnCount)

   local spawned = 0

   while spawned < rollGoalSpawnCount and not isAllSpotsTaken() do
      local rollGoalSpawnPos = GetRandomInt(1, 9)
      local spawnKey = "spawn" .. rollGoalSpawnPos .. "Taken"

      if not GoalSpawn[spawnKey] then
            local spawnPath = "goal_" .. rollGoalSpawnPos
            local goal = BuildObject("fostand02", Mission.EnemyTeam, spawnPath) --ibpgen
            table.insert(Goal, goal)

            --   print("spawnPath :: " .. spawnPath)
            GoalSpawn[spawnKey] = true
            spawned = spawned + 1
       end
   end
end

function IsPlayerNearGoals()
   -- Mission.NearAnyGoal = false  -- reset at the beginning of each check
   if Mission.NearAnyGoal == false then
      for _, goal in ipairs(Goal) do
         if GetDistance(Mission.Player, goal) < 150.0 then
            if not Mission.NearAnyGoal then
               AddObjective("YOU ARE ON TOP OF THE OBJECTIVE.\nDESTROY IT...", "RED", 6.0)
            end
            Mission.NearAnyGoal = true
            break  -- we found one nearby, no need to keep checking
         end
      end
   else
      for _, goal in ipairs(Goal) do
         if GetDistance(Mission.Player, goal) > 150.0 then
            if Mission.NearAnyGoal then
               Mission.NearAnyGoal = false
            end
         end
      end
   end
end

-- Credit to Nielk1 for this.
function GetRandomInt(Min, Max)
   local retVal = GetRandomFloat(Min, Max + 1);

   if (retVal > Max) then
       return Max;
   end

   return math.floor(retVal);
end

function BuildStartingVehicle(aTeam, aRace, ODF1, ODF2, Where)
   local TempODF = ReplaceCharacter(1, ODF1, aRace);

   if (DoesODFExist(TempODF) == false) then
       TempODF = ReplaceCharacter(1, ODF2, aRace);
   end

   local h = BuildObject(TempODF, aTeam, Where);

   if (aTeam == _Session.m_PlayerTeam) then
       SetBestGroup(h);
   end

   return h;
end

function IsPlayerWithinDistance(handleOrPath, distance)

   if GetDistance(Mission.Player, handleOrPath) <= distance then
      return true;
   else
      return false;
   end

end

function GameWinSequence()
   -- New outro for win condition
   IFace_Exec("bzgame_script_banners.cfg")
   IFace_Activate("BannerObjectiveWinFade");

   SetMusicIntensity(1)
   StartSoundEffect("music_win.wav") -- begin victory music
   audioOutro = AudioMessage("vo_ia_outro_win.wav")

   ClearObjectives()
   AddObjective(">>> WELL DONE COMMANDER >>>\n\nYOU KICKED ASS...", "GREEN", 8.0)
   BeginDropshipSequence("dropship_2")
end

function GameLoseSequence()
   ClearObjectives()
   AddObjective(">>> MISSION FAILED >>>\n\nYOU SUCK.", "RED", 8.0)
end

function GameEnd(isWin, waitEnd, msg) -- 15, "instantw.txt"
   if isWin then
      SucceedMission(GetTime() + waitEnd, msg)
   else
      FailMission(GetTime() + waitEnd, msg)
   end
end

----------------------------------------------------------------------------------------

-- RECOMMENDED: keep track of win/lose conditions
function GameEndConditions()
   if not Mission.m_GameOver then
      if Mission.ObjectivesDone >= 2 then
         GameWinSequence()
         Mission.m_GameOver = true
      end
   else
      if not Mission.DropshipLanded then
         Mission.DropshipLanded = WaitUntilTime(Mission.DropshipSpawnTime, 18)
      else
         if not Mission.DropshipSpawned then
            ClearObjectives()
            AddObjective(">>> DROPSHIP HAS LANDED.\nEXTRACT IMMEDIATELY", "RED", 5.0)
            RemoveDropshipHandle("unnamed_ivdrop_land")
            SpawnDropshipLanded("ivdrop", Mission.DropshipPath)
            Mission.DropshipSpawned = true -- prevents multiple spawning over and over
            Mission.DropshipLandedTime = GetTimeNowSeconds()
         else
            if not Mission.NearExtraction then
               local dis = GetDistance(Mission.Player, "dropship_2_spawn")
               print("DISTANCE :: " .. dis)
               if dis <= 30 then
                  Mission.NearExtraction = true
               else
                  Mission.NearExtraction = false
               end
            else
               if not Mission.M_Extraction then
                  ClearObjectives()
                  AddObjective("- EXTRACTION COMPLETE", "GREEN", 5.0)
                  TakeoffDropshipLanded("unnamed_ivdrop")
                  Mission.M_Extraction = true
                  SucceedMission(GetTime() + 5, "instantw.txt")
               end
            end
         end
      end
   end
end
