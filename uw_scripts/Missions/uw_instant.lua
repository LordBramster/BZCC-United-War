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

-- Models
local _Pool = require("_Pool")

local _Session = {
    -- Throwing this at the top as this is probably the most used / important variable in a script for timers and events.
    m_TurnCounter = 0,

    m_GameTPS = 20,

    m_CPUTeamRace = 0,
    m_HumanTeamRace = 0,
    m_MyGoal = 0,
    m_AwareV13 = 0,
    m_MyForce = 0,
    m_CompForce = 0,
    m_Difficulty = 0,

    -- This is constantly 1.
    m_PlayerTeam = 1,

    -- This may change if 1.2 features "Like Pilot" are enabled.
    -- If 1.2 is enabled, m_StratTeam will be set to 3.
    m_StratTeam = 1,
    m_CompTeam = 6,

    m_EnemyRecycler = nil,
    m_Recycler = nil,
    m_Player = nil,

    m_StartDone = false,
    m_CanRespawn = false,
    m_GameOver = false,
    m_PastAIP0 = false,

    m_AudioIntro = nil,
    m_AudioPlaying = false,
    m_AudioOutro = nil,

    m_Pools = {}
}

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- Local Variables -----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

local CHAR_RACE_ISDF = 'i'
local CHAR_RACE_SCION = 'f'
local CHAR_RACE_HADEAN = 'e'

local PATHS = {
    RECYCLER = 'Recycler',
    RECYCLER_ENEMY = 'RecyclerEnemy',
    TURRET_ENEMY_1 = 'turretEnemy1',
    TURRET_ENEMY_2 = 'turretEnemy2',
    GTOW_1 = 'gtow1',
    GTOW_2 = 'gtow2',
    GTOW_3 = 'gtow3',
    GTOW_4 = 'gtow4',
    GTOW_5 = 'gtow5',
    GTOW_6 = 'gtow6'
}

local IFace = {
   TEST_OPTION = "script.menu.test",
   TEST_VEHICLE = "script.menu.vehicleFBX",
   TEST_MYSIDE = "script.menu.myside",

   DIFFICULTY = "script.menu.difficulty",
   MYFORCE = "script.menu.myforce",
   HISFORCE = "script.menu.hisforce",

   LEAVE_MENU = "script.menu.exit"
}

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- Utility Functions ---------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function ReplaceCharacter(pos, str, r)
    return str:sub(1, pos - 1) .. r .. str:sub(pos + 1)
end

---------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------- SIRBRAMBLEY ---------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function SetRaceTeamColor()
    print("Player Race: ", _Session.m_HumanTeamRace)
    print("CPU Race: ", _Session.m_CPUTeamRace)

    if (_Session.m_HumanTeamRace ~= _Session.m_CPUTeamRace) then
        print("TEAMCOLOR :: DEFAULT")
        return
    end

    -- Set Teamcolor for CPU based on race
    if (_Session.m_CPUTeamRace == CHAR_RACE_SCION) then
        SetTeamColor(_Session.m_CompTeam, 95, 180, 120) -- Light Green for Scions
    elseif (_Session.m_CPUTeamRace == CHAR_RACE_HADEAN) then
        SetTeamColor(_Session.m_CompTeam, 130, 75, 200) -- Light Purple for Hadeans
    elseif (_Session.m_CPUTeamRace == CHAR_RACE_ISDF) then
        SetTeamColor(_Session.m_CompTeam, 75, 140, 220) -- Light Blue for ISDF
    elseif (_Session.m_CPUTeamRace == "j") then
        SetTeamColor(_Session.m_CompTeam, 20, 150, 255) -- Light Blue for ISDF (Classic)
    else
        SetTeamColor(_Session.m_CompTeam, 140, 45, 45)  -- Red for NA
    end

    print("TEAMCOLOR :: CPU SET")
end

function IntroShowObjective()
    SetColorFade(2, 0.75, Make_RGBA(0, 0, 0, 255))

    IFace_Exec("bzgame_script_banners.cfg")
    IFace_Activate("BannerObjectiveNewFade")

    print("LOADED :: bzgame_script_banners.cfg")
    print("PLAYING :: vo_ia_intro_warn.wav")

    -- Present initial VO/objective depending on race & CPU force
    if (_Session.m_HumanTeamRace == CHAR_RACE_ISDF) then
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

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
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

function Load(Session)
    _Session = Session
end

function AddObject(handle)
    local classLabel = GetClassLabel(handle)

    if (classLabel == "CLASS_DEPOSIT") then
        _Session.m_Pools[#_Session.m_Pools + 1] = _Pool:New(handle, GetPosition(handle), GetDistance(handle, PATHS.RECYCLER_ENEMY));
    end
end

function DeleteObject(handle)
    local ObjClass = GetClassLabel(handle)

    if (GetTeamNum(handle) == _Session.m_CompTeam) then
        if (ObjClass == "CLASS_ARMORY") then
            _Session.m_HaveArmory = false
        end
    end
end

function Start()
    -- Do not auto group units.
    SetAutoGroupUnits(false)

    -- Grab the TPS.
    _Session.m_GameTPS = GetTPS()

    IFace_EnterMenuMode()
    IFace_Exec("bzgame_script_menu.cfg")
    IFace_Activate("TestPlay")
    CameraReady()
    FreeCamera()
    SetCameraPosition(SetVector(0, 50, 50), SetVector(-90, 15, -20))

    SetInitialConfigVars()
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

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

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

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. _Session.m_CPUTeamRace .. string.sub(AIPTypeExtensions, type, type)

    -- Fallback to old method if none exists.
    if (DoesFileExist(AIPFile) == false) then
        AIPFile = AIPString .. _Session.m_CPUTeamRace .. _Session.m_HumanTeamRace .. string.sub(AIPTypeExtensions, type, type)
    end

    SetAIP(AIPFile .. '.aip', _Session.m_CompTeam)

    if (_Session.m_PastAIP0) then
        DoTaunt(TAUNTS_Random)
    end
end

function SetInitialConfigVars()
   IFace_SetString(IFace.MYFORCE, ConvertIntForceSize(_Session.m_MyForce))
   IFace_SetString(IFace.HISFORCE, ConvertIntForceSize(_Session.m_CompForce))

   if (_Session.m_Difficulty == 1) then
      IFace_Activate("TestDifficultyMedium")
   elseif (_Session.m_Difficulty == 2) then
      IFace_Activate("TestDifficultyHard")
   else
      IFace_Activate("TestDifficultyEasy")
   end
end