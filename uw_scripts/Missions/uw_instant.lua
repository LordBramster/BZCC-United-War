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
assert(load(assert(LoadFile("_requirefix.lua")), "_requirefix.lua"))();

-- Required Globals.
require("_GlobalVariables");

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

    m_AudioIntro = nil,
    m_AudioPlaying = true
}

local CHAR_RACE_ISDF = 'i';
local CHAR_RACE_SCION = 'f';
local CHAR_RACE_HADEAN = 'e';

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
    -- Display a fullscreen color fade in at start (SP only)
    SetColorFade(2, 0.75, Make_RGBA(0, 0, 0, 255))

    IFace_Exec("bzgame_script_banners.cfg")
    IFace_Activate("BannerObjectiveNewFade");

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
        IFace_Deactivate("BannerObjectiveNewFade");
        _Session.m_AudioPlaying = false
    end
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Event Driven Functions -------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function InitialSetup()
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- We want bot kill messages as this may be a coop mission.
    WantBotKillMessages();

    PreloadODF("ivrecy");
    PreloadODF("fvrecy");
    PreloadODF("ivrecycpu");
    PreloadODF("fvrecycpu");
end

function Save()
    return _Session;
end

function Load(Session)
    _Session = Session;
end

function AddObject(handle)

end

function DeleteObject(handle)
    local ObjClass = GetClassLabel(handle);

    if (GetTeamNum(handle) == _Session.m_CompTeam) then
        if (ObjClass == "CLASS_ARMORY") then
            _Session.m_HaveArmory = false;
        end
    end
end

function Start()
    -- Do not auto group units.
    SetAutoGroupUnits(false);

    -- Grab the TPS.
    _Session.m_GameTPS = GetTPS();
end

function Update()
    -- Keep track of our player.
    _Session.m_Player = GetPlayerHandle(1);

    -- Keep track of our turn counter.
    _Session.m_TurnCounter = _Session.m_TurnCounter + 1;

    if (_Session.m_StartDone == false) then
        _Session.m_StartDone = true;

        _Session.m_MyGoal = GetInstantGoal();
        _Session.m_CanRespawn = IFace_GetInteger("options.instant.bool0");
        _Session.m_AwareV13 = IFace_GetInteger("options.instant.awarev13");

        -- Set our name for the CPU.
        SetTauntCPUTeamName("CPU");

        -- Taunt.
        DoTaunt(TAUNTS_GameStart);

        if (_Session.m_AwareV13 == 1) then
            _Session.m_CustomAIPStr = IFace_GetString("options.instant.string0");
            _Session.m_CPUTeamRace = string.char(IFace_GetInteger("options.instant.hisrace"));
            _Session.m_HumanTeamRace = string.char(IFace_GetInteger("options.instant.myrace"));
        else
            _Session.m_MySide = IFace_GetInteger("options.instant.bool2");

            if (_Session.m_MySide == 1) then
                _Session.m_CPUTeamRace = string.char(RACE_SCION);
                _Session.m_HumanTeamRace = string.char(RACE_ISDF);
            else
                _Session.m_CPUTeamRace = string.char(RACE_ISDF);
                _Session.m_HumanTeamRace = string.char(RACE_SCION);
            end

            ----------------------------------------------------------------------------------------
            print("Player Force: ", _Session.m_HumanTeamRace)
            print("CPU Race: ", _Session.m_CPUTeamRace)
            print("MySide: ", GetInstantMySide())
            print("m_MySide: ", _Session.m_MySide)
            ----------------------------------------------------------------------------------------

            _Session.m_StratTeam = 3;

            Ally(_Session.m_PlayerTeam, _Session.m_StratTeam)
            Ally(_Session.m_StratTeam, _Session.m_PlayerTeam)
        end

        _Session.m_MyForce = GetInstantMyForce();
        _Session.m_CompForce = GetInstantCompForce();
        _Session.m_Difficulty = GetInstantDifficulty();

        ----------------------------------------------------------------------------------------
        print("MyForce :: ", _Session.m_MyForce)
        print("ComForce :: ", _Session.m_CompForce)
        print("Difficulty :: ", _Session.m_Difficulty)
        ----------------------------------------------------------------------------------------

        local customCPURecycler = IFace_GetString("options.instant.string2");

        if (customCPURecycler ~= nil) then
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace,
                customCPURecycler, "*vrecy", "RecyclerEnemy");
        else
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace,
                "*vrecycpu", "*vrecy", "RecyclerEnemy");
        end

        local customHumanRecycler = IFace_GetString("options.instant.string1");

        if (customHumanRecycler ~= nil) then
            _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace,
                customHumanRecycler, "*vrecy", "Recycler");
        else
            _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, 
                "*vrecy", "*vrecy", "Recycler");
        end
    end
end
