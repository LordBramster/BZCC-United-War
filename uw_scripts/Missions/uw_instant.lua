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

-- Fix for finding files outside of this script directory.
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))()

-- Required Globals.
require("_GlobalVariables")

-- Services
local _UWService = require("_UWService")
-- UW Database.
local _UWDatabase = require("_UWDatabase")

local _Session = {
    -- Throwing this at the top as this is probably the most used / important variable in a script for timers and events.
    m_TurnCounter = 0,

    m_GameTPS = 20,

    m_CPUTeamRace = '',
    m_HumanTeamRace = '',
    m_MyGoal = 0,
    m_MyForce = 0,
    m_CompForce = 0,
    m_Difficulty = 0,

    -- This is constantly 1.
    m_PlayerTeam = 1,

    -- This may change if 1.2 features "Like Pilot" are enabled.
    -- If 1.2 is enabled, m_StratTeam will be set to 3.
    m_StratTeam = 1,
    m_CompTeam = 6,
    m_NeutralEnemyTeam = 15,

    m_EnemyRecycler = nil,
    m_Recycler = nil,
    m_Player = nil,
    m_PlayerStartVehicle = nil,

    m_StartDone = false,
    m_CanRespawn = false,
    m_GameOver = false,
    m_PastAIP0 = false,
    m_AwareV13 = false,

    -- Specific game options.
    m_ScrapFieldsEnabled = false,
    m_MineFieldsEnabled = false,
    m_NeutralEnemiesEnabled = false,

    m_AudioIntro = nil,
    m_AudioPlaying = false,
    m_AudioOutro = nil,

    m_Pools = {}
}

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- Utility Functions ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

---@param pos integer
---@param str string
---@param r string
---@return string
function ReplaceCharacter(pos, str, r)
    return str:sub(1, pos - 1) .. r .. str:sub(pos + 1)
end

---@param Min integer
---@param Max integer
function GetRandomInt(Min, Max)
    local retVal = GetRandomFloat(Min, Max + 1);

    if (retVal > Max) then
        return Max;
    end

    return math.floor(retVal);
end

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- SIRBRAMBLEY ---------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function IntroShowObjective()
    SetColorFade(2, 0.75, Make_RGBA(0, 0, 0, 255))

    IFace_Exec("bzgame_script_banners.cfg")
    IFace_Activate("BannerObjectiveNewFade")

    print("LOADED :: bzgame_script_banners.cfg")
    print("PLAYING :: vo_ia_intro_warn.wav")

    -- Present initial VO/objective depending on race & CPU force
    if (_Session.m_HumanTeamRace == FACTIONS.ISDF) then
        AudioMessage("ivrecy04.wav") -- give the rec some love!

        if (_Session.m_CompForce >= 2) then
            _Session.m_AudioIntro = AudioMessage("vo_ia_intro_warn.wav")
            AddObjective(">>> HOSTILE THREAT HIGH >>>\nBE ADVISED.\n\n> DESTROY THE ENEMY BASE.", "CYAN", 10.0)
        else
            _Session.m_AudioIntro = AudioMessage("vo_ia_intro.wav")
            AddObjective(">>> HOSTILE THREAT NEUTRAL >>>\n\n>DESTROY THE ENEMY BASE", "CYAN", 10.0)
        end

        _Session.m_AudioPlaying = true
    else
        _Session.m_AudioIntro = AudioMessage("vo_ia_intro_warn.wav")
        AddObjective(";;; WELCOME, GUARDIAN ;;;\nDESTROY THE HERETICS", "PURPLE", 8.0)
        _Session.m_AudioPlaying = true
    end
end

function IntroDispatchEnemy()

end

function IntroBannerEnd()
    if (_Session.m_AudioPlaying == true and IsAudioMessageDone(_Session.m_AudioIntro)) then
        IFace_Deactivate("BannerObjectiveNewFade")
        _Session.m_AudioPlaying = false
    end
end

---@alias PrintMessageSeverity "INFO" | "WARNING" | "ERROR" | "CRITICAL"
---@param Message string
---@param Severity PrintMessageSeverity
function PrintMessage(Message, Severity)
    print(Severity .. " | " .. Message)
end

---@param playerFaction Faction
function SwapVehicleModelInMenu(playerFaction)
    local chosenVehicle = IFace_GetString(_UWDatabase.IFaceVariables.VEHICLE)

    if (chosenVehicle == nil) then
        PrintMessage("Unable to read IFace value for " .. _UWDatabase.IFaceVariables.VEHICLE, "ERROR")
        return
    end

    local vehicleRecord = playerFaction.FactionLoadouts[chosenVehicle]

    if (vehicleRecord == nil) then
        PrintMessage(
            "Vehicle Record not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    local vehicleRecordModel = vehicleRecord.Model

    if (vehicleRecordModel == nil) then
        PrintMessage(
            "Vehicle Record FBX not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    _Session.m_PlayerStartVehicle = vehicleRecord.ODF
    IFace_SetString(_UWDatabase.IFaceVariables.VEHICLE_FBX, vehicleRecordModel)
    PrintMessage("Setting " .. _UWDatabase.IFaceVariables.VEHICLE_FBX .. " to " .. vehicleRecordModel, "INFO")
end

---@param playerFaction Faction
function SwapPilotPrimaryModelInMenu(playerFaction)
    local chosenPrimary = IFace_GetString(_UWDatabase.IFaceVariables.PILOT_PRIMARY)

    if (chosenPrimary == nil) then
        PrintMessage("Unable to read IFace value for " .. _UWDatabase.IFaceVariables.PILOT_PRIMARY, "ERROR")
        return
    end

    local primaryRecord = playerFaction.FactionLoadouts[chosenPrimary]

    if (primaryRecord == nil) then
        PrintMessage(
            "Primary Weapon Record not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    local primaryRecordModel = primaryRecord.Model

    if (primaryRecordModel == nil) then
        PrintMessage(
            "Primary Weapon Record FBX not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    IFace_SetString(_UWDatabase.IFaceVariables.PILOT_PRIMARY_FBX, primaryRecordModel)
    PrintMessage("Setting " .. _UWDatabase.IFaceVariables.PILOT_PRIMARY_FBX .. " to " .. primaryRecordModel, "INFO")
end

---@param playerFaction Faction
function SwapPilotEquipmentModelInMenu(playerFaction)
    local chosenEquipment = IFace_GetString(_UWDatabase.IFaceVariables.PILOT_EQUIPMENT)

    if (chosenEquipment == nil) then
        PrintMessage("Unable to read IFace value for " .. _UWDatabase.IFace.PILOT_PRIMARY, "ERROR")
        return
    end

    local equipmentRecord = playerFaction.FactionLoadouts[chosenEquipment]

    if (equipmentRecord == nil) then
        PrintMessage(
            "Equipment Record not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    local equipmentRecordModel = equipmentRecord.Model

    if (equipmentRecordModel == nil) then
        PrintMessage(
            "Equipment Record FBX not found for: " ..
            playerFaction.Name ..
            " please consult the mission script and fix this!",
            "ERROR")
        return
    end

    IFace_SetString(_UWDatabase.IFaceVariables.PILOT_EQUIPMENT_FBX, equipmentRecordModel)
    PrintMessage("Setting " .. _UWDatabase.IFaceVariables.PILOT_EQUIPMENT_FBX .. " to " .. equipmentRecordModel, "INFO")
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    -- Start by initializing the UW Database.
    _UWDatabase:Initialize()

    -- Do not auto group units.
    SetAutoGroupUnits(false)

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages()

    PreloadODF("ivrecy")
    PreloadODF("fvrecy")
    PreloadODF("ivrecycpu")
    PreloadODF("fvrecycpu")
end

function Save()
    return _Session
end

---@param Session table
function Load(Session)
    _Session = Session
end

---@param Handle Handle
function AddObject(Handle)
    local classLabel = GetClassLabel(Handle)
    local team = GetTeamNum(Handle)

    if (classLabel == "CLASS_DEPOSIT") then
        _UWService:RegisterMapPool(Handle)
        return
    end

    if (team == _Session.m_StratTeam) then
        if (_Session.m_AwareV13 == false) then
            if (classLabel == "CLASS_HOVER" or classLabel == "CLASS_WINGMAN"
                or classLabel == "CLASS_MORPHTANK" or classLabel == "CLASS_ASSAULTTANK"
                or classLabel == "CLASS_SERVICE"or classLabel == "CLASS_WALKER") then
                SetTeamNum(Handle, _Session.m_PlayerTeam)
                SetBestGroup(Handle)
            end
        end
    end
end

---@param handle Handle
function DeleteObject(handle)

end

function Start()
    -- Do not auto group units.
    SetAutoGroupUnits(false)

    -- Grab the TPS.
    _Session.m_GameTPS = GetTPS()

    -- Set the CPU Taunt Name here
    SetTauntCPUTeamName("CPU")

    -- Enter the menu to set the game up
    IFace_EnterMenuMode()
    IFace_Exec("bzgame_script_menu.cfg")
    IFace_Activate("InstantOptions")
    CameraReady()
    FreeCamera()
    SetCameraPosition(SetVector(0, 75, 0), SetVector(-90, 15, -20))
end

function Update()
    -- Keep track of our player.
    _Session.m_Player = GetPlayerHandle(1)

    -- Keep track of our turn counter.
    _Session.m_TurnCounter = _Session.m_TurnCounter + 1

    -- if (_Session.m_StartDone == false) then
    --     _Session.m_StartDone = true

    --     _Session.m_MyGoal = GetInstantGoal()
    --     _Session.m_CanRespawn = IFace_GetInteger("options.instant.bool0")
    --     _Session.m_AwareV13 = IFace_GetInteger("options.instant.awarev13")

    --     -- Set our name for the CPU.
    --     SetTauntCPUTeamName("CPU")

    --     -- Taunt.
    --     DoTaunt(TAUNTS_GameStart)

    --     if (_Session.m_AwareV13 == 1) then
    --         _Session.m_CustomAIPStr = IFace_GetString("options.instant.string0")
    --         _Session.m_CPUTeamRace = string.char(IFace_GetInteger("options.instant.hisrace"))
    --         _Session.m_HumanTeamRace = string.char(IFace_GetInteger("options.instant.myrace"))
    --     else
    --         _Session.m_MySide = IFace_GetInteger("options.instant.bool2")

    --         if (_Session.m_MySide == 1) then
    --             _Session.m_CPUTeamRace = string.char(RACE_SCION)
    --             _Session.m_HumanTeamRace = string.char(RACE_ISDF)
    --         else
    --             _Session.m_CPUTeamRace = string.char(RACE_ISDF)
    --             _Session.m_HumanTeamRace = string.char(RACE_SCION)
    --         end

    --         ----------------------------------------------------------------------------------------
    --         print("MySide: ", GetInstantMySide())
    --         print("m_MySide: ", _Session.m_MySide)
    --         ----------------------------------------------------------------------------------------

    --         _Session.m_StratTeam = 3

    --         Ally(_Session.m_PlayerTeam, _Session.m_StratTeam)
    --         Ally(_Session.m_StratTeam, _Session.m_PlayerTeam)
    --     end

    --     _Session.m_MyForce = GetInstantMyForce()
    --     _Session.m_CompForce = GetInstantCompForce()
    --     _Session.m_Difficulty = GetInstantDifficulty()

    --     ----------------------------------------------------------------------------------------
    --     print("MyForce :: ", _Session.m_MyForce)
    --     print("ComForce :: ", _Session.m_CompForce)
    --     print("Difficulty :: ", _Session.m_Difficulty)
    --     ----------------------------------------------------------------------------------------

    --     local customCPURecycler = IFace_GetString("options.instant.string2")

    --     if (customCPURecycler ~= nil) then
    --         _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, customCPURecycler, "*vrecy", PATHS.RECYCLER_ENEMY)
    --     else
    --         _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vrecycpu", "*vrecy", PATHS.RECYCLER_ENEMY)
    --     end

    --     local RecPos = GetPosition(_Session.m_EnemyRecycler)

    --     ----------------------------------------------------------------------------------------
    --     -- Spawn CPU vehicles.
    --     ----------------------------------------------------------------------------------------
    --     BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", PATHS.TURRET_ENEMY_1)
    --     BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", PATHS.TURRET_ENEMY_2)

    --     if (_Session.m_CompForce > 0) then
    --         BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vturr", PATHS.GTOW_2)
    --         BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vrckt", PATHS.GTOW_3)
    --         BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vscout", GetPositionNear(RecPos, 20.0, 40.0))
    --         BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 20.0, 40.0))

    --         if (_Session.m_CompForce > 1) then
    --             BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vatank", PATHS.GTOW_4)
    --             BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vatank", PATHS.GTOW_5)
    --             BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0))
    --             BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0))
    --             BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 20.0, 40.0))

    --             if (_Session.m_CompForce > 2) then
    --                 BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 20.0, 40.0))
    --                 BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 20.0, 40.0))
    --             end
    --         end
    --     end

    --     local customHumanRecycler = IFace_GetString("options.instant.string1")

    --     if (customHumanRecycler ~= nil) then
    --         _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, customHumanRecycler, "*vrecy", PATHS.RECYCLER)
    --     else
    --         _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, "*vrecy", "*vrecy", PATHS.RECYCLER)
    --     end

    --     RecPos = GetPosition(_Session.m_Recycler)

    --     ----------------------------------------------------------------------------------------
    --     -- SIRBRAMBLEY
    --     -- PLAYER FORCE = SMALL
    --     -- REMOVED TO MAKE PLAYER STARTING FORCE HAVE NOTHING IF "SMALL" FOR HARDCORE PLAYERS
    --     ----------------------------------------------------------------------------------------

    --     -- PLAYER FORCE = MEDIUM
    --     if (_Session.m_MyForce > 0) then
    --         BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 40.0, 55.0))
    -- 		BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 30.0, 55.0))
    --         BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vscav", "*vscav", GetPositionNear(RecPos, 30.0, 45.0))

    --         -- PLAYER FORCE = LARGE
    --         if (_Session.m_MyForce > 1) then
    --             BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 30.0, 45.0))
    --             BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 30.0, 45.0))

    --             -- PLAYER FORCE = XLARGE
    --             if (_Session.m_MyForce > 2) then
    --                 BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 30.0, 45.0))
    --                 BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 40.0, 55.0))
    --                 BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 40.0, 55.0))
    --             end
    --         end
    --     end

    --     ----------------------------------------------------------------------------------------
    --     -- Handle AIPs
    --     ----------------------------------------------------------------------------------------
    --     if (_Session.m_AwareV13 == 0) then
    --         if (_Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
    --             SetAIP("isdfteam.aip", _Session.m_StratTeam)
    --         else
    --             SetAIP("scionteam.aip", _Session.m_StratTeam)
    --         end
    --     end

    --     if (_Session.m_PastAIP0 == false) then
    --         SetCPUAIPlan(AIPType0)
    --     end

    --     ----------------------------------------------------------------------------------------
    --     -- Handle Player Spawning
    --     ----------------------------------------------------------------------------------------

    --     local PlayerH = GetPlayerHandle(_Session.m_PlayerTeam)
    --     RemoveObject(PlayerH)

    --     PlayerH = BuildObject(_Session.m_HumanTeamRace .. "vscout", _Session.m_PlayerTeam, GetPositionNear(RecPos, 10, 50))
    --     SetAsUser(PlayerH, _Session.m_PlayerTeam)
    --     AddPilotByHandle(PlayerH)

    --     SetScrap(_Session.m_CompTeam, 40)
    --     SetScrap(_Session.m_StratTeam, 40)

    --     ----------------------------------------------------------------------------------------
    --     -- SIRBRAMBLEY
    --     ----------------------------------------------------------------------------------------
    --     SetRaceTeamColor() -- Forces Teamcolors to CPU when player has same race
    --     IntroShowObjective() -- Setup initial objective stuffs
    --     IntroDispatchEnemy() -- TODO ... waiting on fix from JJ for _Session.m_Player; have one goto rec and one goto player
    -- end

    ----------------------------------------------------------------------------------------
    -- SIRBRAMBLEY
    -- Deactivate the banner once the mission audio is done.
    ----------------------------------------------------------------------------------------
    IntroBannerEnd()

    -- Keep track of games.
    if (_Session.m_StartDone) then
        GameConditions()
    end
end

function PlayerEjected(DeadObjectHandle)
    return DoEjectPilot
end

function PlayerDied(DeadObjectHandle, bSniped)
    if (IsPerson(DeadObjectHandle) == false and bSniped == false) then
        return DoEjectPilot
    end

    if (_Session.m_CanRespawn == 1 and IsAlive(_Session.m_Recycler)) then
        RespawnPlayer(false)
    else
        FailMission(GetTime() + 3.0)
    end

    return DLLHandled
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle)) then
        return PlayerDied(DeadObjectHandle, false)
    end

    if (IsPerson(DeadObjectHandle)) then
        return DoEjectPilot
    end

    return DLLHandled
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle)) then
        return PlayerDied(DeadObjectHandle, true)
    end

    return DLLHandled
end

function ProcessCommand(CRC)
    local playerFaction = _UWService:GetPlayerFaction()

    if (CRC == _UWDatabase.CRCVariables["script_menu_faction_changed"]) then
        SwapVehicleModelInMenu(playerFaction)
        SwapPilotPrimaryModelInMenu(playerFaction)
        SwapPilotEquipmentModelInMenu(playerFaction)
    elseif (CRC == _UWDatabase.CRCVariables["script_menu_vehicle_changed"]) then
        SwapVehicleModelInMenu(playerFaction)
    elseif (CRC == _UWDatabase.CRCVariables["script_menu_pilot_primary_changed"]) then
        SwapPilotPrimaryModelInMenu(playerFaction)
    elseif (CRC == _UWDatabase.CRCVariables["script_menu_pilot_equipment_changed"]) then
        SwapPilotEquipmentModelInMenu(playerFaction)
    elseif (CRC == _UWDatabase.CRCVariables["script_menu_game_start"]) then
        SetupMission()
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function SetupMission()
    ----------------------------------------------------------------------------------------
    -- Close the menu and set the camera back to normal
    ----------------------------------------------------------------------------------------
    IFace_ExitMenuMode()
    IFace_Deactivate("InstantOptions")
    FreeFinish()
    CameraFinish()

    ----------------------------------------------------------------------------------------
    -- Set important pre-setup variables.
    ----------------------------------------------------------------------------------------
    _Session.m_HumanTeamRace = _UWService:GetPlayerFaction().Char
    _Session.m_CPUTeamRace = _UWService:GetCPUFaction().Char
    _Session.m_AwareV13 = IFace_GetInteger(_UWDatabase.IFaceVariables.MODE) > 0
    _Session.m_ScrapFieldsEnabled = IFace_GetInteger(_UWDatabase.IFaceVariables.SCRAP_FIELDS) > 0
    _Session.m_NeutralEnemiesEnabled = IFace_GetInteger(_UWDatabase.IFaceVariables.NEUTRAL_ENEMIES) > 0
    _Session.m_MineFieldsEnabled = IFace_GetInteger(_UWDatabase.IFaceVariables.MINEFIELDS) > 0

    ----------------------------------------------------------------------------------------
    -- Get map paths to spawn objects based on chosen options.
    ----------------------------------------------------------------------------------------
    local mapPaths = GetAiPaths()
    local scrapFieldPaths = {}
    local neutralEnemyPaths = {}
    local mineFieldPaths = {}

    PrintMessage("PROCESSING MAP PATHS", "INFO")

    if (mapPaths ~= nil) then
        for i = 1, #mapPaths do
            local path = mapPaths[i]

            -- Check to see if specific paths match.
            if (_Session.m_MineFieldsEnabled and path:find(_UWDatabase.Paths.MINE_FIELD_SUBSTRING)) then
                mineFieldPaths[#mineFieldPaths + 1] = path
            elseif (_Session.m_ScrapFieldsEnabled and path:find(_UWDatabase.Paths.SCRAP_FIELD_SUBSTRING)) then
                scrapFieldPaths[#scrapFieldPaths + 1] = path
            elseif (_Session.m_NeutralEnemiesEnabled and path:find(_UWDatabase.Paths.NEUTRAL_ENEMY_SUBSTRING)) then
                neutralEnemyPaths[#neutralEnemyPaths + 1] = path
            end

            PrintMessage("PATH: " .. path .. " PROCESSED", "INFO")
        end
    end

    PrintMessage("FINISHED PROCESSING MAP PATHS", "INFO")

    ----------------------------------------------------------------------------------------
    -- Handle 1.2 mode
    ----------------------------------------------------------------------------------------
    if (_Session.m_AwareV13 == false) then
        _Session.m_StratTeam = 3

        if (_Session.m_HumanTeamRace == RACE_ISDF) then
            _Session.m_CPUTeamRace = RACE_SCION
            SetAIP("isdfteam_uw.aip", _Session.m_StratTeam)
        else
            _Session.m_CPUTeamRace = RACE_ISDF
            SetAIP("scionteam_uw.aip", _Session.m_StratTeam)
        end

        Ally(_Session.m_PlayerTeam, _Session.m_StratTeam)
        Ally(_Session.m_StratTeam, _Session.m_PlayerTeam)
    end

    ----------------------------------------------------------------------------------------
    -- Set Team Colours
    ----------------------------------------------------------------------------------------
    _UWService:SetCPUTeamColor(_Session.m_CompTeam, _Session.m_HumanTeamRace, _Session.m_CPUTeamRace)

    ----------------------------------------------------------------------------------------
    -- Handle Player Spawning
    ----------------------------------------------------------------------------------------
    local playerHandle = GetPlayerHandle(_Session.m_PlayerTeam)
    RemoveObject(playerHandle)

    playerHandle = BuildObject(_Session.m_PlayerStartVehicle, _Session.m_PlayerTeam, GetPositionNear(_UWDatabase.Paths.RECYCLER, 10, 50))
    SetAsUser(playerHandle, _Session.m_PlayerTeam)
    AddPilotByHandle(playerHandle)

    local customHumanRecycler = IFace_GetString("options.instant.string1")

    if (customHumanRecycler ~= nil) then
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam,  _Session.m_HumanTeamRace, customHumanRecycler, "*vrecy", _UWDatabase.Paths.RECYCLER)
    else
        _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, "*vrecy", "*vrecy", _UWDatabase.Paths.RECYCLER)
    end

    SetScrap(_Session.m_StratTeam, 40)

    ----------------------------------------------------------------------------------------
    -- Handle CPU Spawning
    ----------------------------------------------------------------------------------------
    local customCPURecycler = IFace_GetString("options.instant.string2")

    if (customCPURecycler ~= nil) then
        _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, customCPURecycler, "*vrecy", _UWDatabase.Paths.RECYCLER_ENEMY)
    else
        _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vrecycpu", "*vrecy", _UWDatabase.Paths.RECYCLER_ENEMY)
    end

    BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", _UWDatabase.Paths.TURRET_ENEMY_1)
    BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", _UWDatabase.Paths.TURRET_ENEMY_2)

    SetScrap(_Session.m_CompTeam, 40)
    DoTaunt(TAUNTS_GameStart)

    ----------------------------------------------------------------------------------------
    -- Neutral Enemies (If Enabled)
    ----------------------------------------------------------------------------------------
    if (_Session.m_NeutralEnemiesEnabled and #neutralEnemyPaths > 0) then
        -- Get this value. 1 is "RANDOM", 2 is "ALL". 
        -- If "RANDOM" is chosen, we will only spawn a fraction of enemies based on the available paths.
        -- If "FULL" is chosen, we will populate all paths with a "neutral base".
        local neutralEnemiesOption = IFace_GetInteger(_UWDatabase.IFaceVariables.NEUTRAL_ENEMIES);

        for i = 1, #neutralEnemyPaths do
            _UWService:CreateNeutralBase(_Session.m_NeutralEnemyTeam, _UWDatabase.Factions[GetRandomInt(1, #_UWDatabase.Factions)], neutralEnemyPaths[i])
        end
    end

    ----------------------------------------------------------------------------------------
    -- Mine Fields (If Enabled)
    ----------------------------------------------------------------------------------------
    if (_Session.m_MineFieldsEnabled and #mineFieldPaths > 0) then
        for i = 1, #mineFieldPaths do
            local path = mineFieldPaths[i]
            local randomCount = GetRandomInt(8, 10)
            local radius = 5

            for j = 1, randomCount do
                local pos = GetPositionNear(path, radius, radius)
                BuildObject("proxmine_unlimited", _Session.m_CompTeam, pos)
                radius = radius + 5
            end
        end
    end

    ----------------------------------------------------------------------------------------
    -- Scrap Fields (If Enabled)
    ----------------------------------------------------------------------------------------
    if (_Session.m_ScrapFieldsEnabled and #scrapFieldPaths > 0) then
        for i = 1, #scrapFieldPaths do
            local path = scrapFieldPaths[i]
            local randomCount = GetRandomInt(5, 10)
            local radius = 5

            for j = 1, randomCount do
                local pos = GetPositionNear(path, radius, radius)
                BuildObject("npscrx", 0, pos)
                radius = radius + 5
            end
        end
    end

    ----------------------------------------------------------------------------------------
    -- Handle AIPs
    ----------------------------------------------------------------------------------------
    if (_Session.m_PastAIP0 == false) then
        SetCPUAIPlan(AIPType0)
    end
end

function RespawnPlayer()
    local recyclerPosition = GetPosition(_Session.m_Recycler)
    local respawnPosition = GetPositionNear(recyclerPosition, 10, 50)
    respawnPosition.y = respawnPosition.y + 50

    local PlayerODF = _Session.m_HumanTeamRace .. "spilo"
    local PlayerH = BuildObject(PlayerODF, _Session.m_PlayerTeam, respawnPosition)
    SetAsUser(PlayerH, _Session.m_PlayerTeam)
    AddPilotByHandle(PlayerH)

    DoTaunt(TAUNTS_HumanShipDestroyed)
end

function BuildStartingVehicle(aTeam, aRace, ODF1, ODF2, Where)
    local TempODF = ReplaceCharacter(1, ODF1, aRace)

    if (DoesODFExist(TempODF) == false) then
        TempODF = ReplaceCharacter(1, ODF2, aRace)
    end

    local h = BuildObject(TempODF, aTeam, Where)

    if (aTeam == _Session.m_PlayerTeam) then
        SetBestGroup(h)
    end

    return h
end

function GameConditions()
    if (_Session.m_GameOver) then
        return
    end

    if (IsAlive(_Session.m_EnemyRecycler) == false) then
        local DLLHandle = GetObjectByTeamSlot(_Session.m_CompTeam, DLL_TEAM_SLOT_RECYCLER)

        if (IsAround(DLLHandle)) then
            _Session.m_EnemyRecycler = DLLHandle
            return
        end

        ----------------------------------------------------------------------------------------
        -- New outro for win condition
        ----------------------------------------------------------------------------------------
        IFace_Exec("bzgame_script_banners.cfg")
        IFace_Activate("BannerObjectiveWinFade")
        SetMusicIntensity(1)
        StartSoundEffect("music_win.wav") -- begin victory music

        _Session.m_AudioOutro = AudioMessage("vo_ia_outro_win.wav")

        ClearObjectives()
        AddObjective(">>> WELL DONE COMMANDER >>>\n\nYou kicked their ass.", "GREEN", 8.0)
        SucceedMission(GetTime() + 10, "instantw.txt")

        _Session.m_GameOver = true
    elseif (IsAlive(_Session.m_Recycler) == false) then
        local DLLHandle = GetObjectByTeamSlot(_Session.m_StratTeam, DLL_TEAM_SLOT_RECYCLER)

        if (IsAround(DLLHandle)) then
            _Session.m_Recycler = DLLHandle
            return
        end

        DoTaunt(TAUNTS_HumanRecyDestroyed)
        FailMission(GetTime() + 5, "instantl.txt")

        _Session.m_GameOver = true
    end
end

function SetCPUAIPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3
    end

    local AIPFile
    local AIPString

    if (_Session.m_CustomAIPStr ~= nil) then
        AIPString = _Session.m_CustomAIPStr
    else
        AIPString = StockAIPNameBase
    end

    local typeSubString = string.sub(AIPTypeExtensions, type + 1, type + 1)

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. _Session.m_CPUTeamRace .. typeSubString

    -- Fallback to old method if none exists.
    if (DoesFileExist(AIPFile) == false) then
        AIPFile = AIPString .. _Session.m_CPUTeamRace .. _Session.m_HumanTeamRace .. typeSubString
    end

    SetAIP(AIPFile .. '.aip', _Session.m_CompTeam)

    if (_Session.m_PastAIP0) then
        DoTaunt(TAUNTS_Random)
    end
end
