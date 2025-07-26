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
    m_GameTPS = 20,

    m_CPUTeamRace = 0,
    m_HumanTeamRace = 0,

    -- This is constantly 1.
    m_PlayerTeam = 1,
    -- This may change if 1.2 features "Like Pilot" are enabled.
    -- If 1.2 is enabled, m_StratTeam will be set to 3.
    m_StratTeam = 1,
    m_CompTeam = 5, -- 6 (MPI)
    m_TurnCounter = 0,
    m_MyGoal = 0,
    m_AwareV13 = 0,
    m_MyForce = 0,
    m_CompForce = 0,
    m_Difficulty = 0,

    m_CustomAIPStr = nil,

    m_EnemyRecycler = nil,
    m_Recycler = nil,
    m_Player = nil,

    m_StartDone = false,
    m_CanRespawn = false,
    m_PastAIP0 = false,
    m_LateGame = false,
    m_HaveArmory = false,
    m_GameOver = false,

    -- SIRBRAMLEY
    m_MySide = 0, -- AwareV12
    m_CPUTeamRaceSelect = 0,  -- ICON CHOICE INSTEAD OF LIST
    m_HumanTeamRaceSelect = 0, -- ICON CHOICE INSTEAD OF LIST
    audioIntro = nil,  -- declare globally
    audioPlaying = true -- declare globally
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
    local racePlayer = _Session.m_HumanTeamRace
    local raceCPU = _Session.m_CPUTeamRace
    local cpuTeam = _Session.m_CompTeam

    print("Player Race: ", racePlayer)
    print("CPU Race: ", raceCPU)
    
    -- Set Teamcolor for CPU based on race
    if racePlayer == raceCPU then
        if raceCPU =="f" then
            SetTeamColor(cpuTeam, 95, 180, 120) -- Light Green for Scions
        elseif raceCPU =="e" then
            SetTeamColor(cpuTeam, 130, 75, 200) -- Light Purple for Hadeans
        elseif raceCPU =="i" then
            SetTeamColor(cpuTeam, 75, 140, 220) -- Light Blue for ISDF
        elseif raceCPU =="j" then
            SetTeamColor(cpuTeam, 20, 150, 255) -- Light Blue for ISDF (Classic)
        else
            SetTeamColor(cpuTeam, 140, 45, 45) -- Red for NA
        end
        print("TEAMCOLOR :: CPU SET")
    else
        print("TEAMCOLOR :: DEFAULT")
    end
end

function IntroShowObjective()
    local racePlayer = _Session.m_HumanTeamRace

    -- Display a fullscreen color fade in at start (SP only)
    SetColorFade(2, 0.75, Make_RGBA(0, 0, 0, 255))

    IFace_Exec("bzgame_script_banners.cfg")
    IFace_Activate("BannerObjectiveNewFade");
    print("LOADED :: bzgame_script_banners.cfg")

    -- Present initial VO/objective depending on race & CPU force
    if racePlayer == "i" then
        AudioMessage("ivrecy04.wav") -- give the rec some love!

        if _Session.m_CompForce >= 2 then
            audioIntro = AudioMessage("vo_ia_intro_warn.wav")
            print("PLAYING :: vo_ia_intro_warn.wav")
            AddObjective(">>> HOSTILE THREAT HIGH >>>\nBE ADVISED.\n\n> DESTROY THE ENEMY BASE.", "CYAN", 10.0)
        else
            audioIntro = AudioMessage("vo_ia_intro.wav")
            print("PLAYING :: vo_ia_intro.wav")
            AddObjective(">>> HOSTILE THREAT NEUTRAL >>>\n\n>DESTROY THE ENEMY BASE", "CYAN", 10.0)
        end

        audioPlaying = true -- because... well duh

    else
        audioIntro = AudioMessage("vo_ia_intro_warn.wav")
        print("PLAYING :: vo_ia_intro_warn.wav")
        AddObjective(";;; WELCOME, GUARDIAN ;;;\nDESTROY THE HERETICS", "PURPLE", 8.0)
        audioPlaying = true -- because... well duh
    end
end

function IntroDispatchEnemy()

    -- Base on code for 1.2 Pilot Mode that sends unit to attack player at start
    if (_Session.m_CompForce > 0) then
        Goto(BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmbike", "stage1"), "Recycler");
        if (_Session.m_CompForce > 1) then
            Goto(BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", "stage2"), "Recycler");
            if (_Session.m_CompForce > 2) then
                Goto(BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*varch", "*vmisl", "stage1"), "Recycler");
            end
        end
    end

    print("DONE :: IntroDispatchEnemy")

end

function IntroBannerEnd()
    -- TODO - probably best to optimize
    if audioPlaying == true then
        if IsAudioMessageDone(audioIntro) then
            IFace_Deactivate("BannerObjectiveNewFade");
            -- AddObjective("\nGOOD LUCK.", "CYAN", 3.0)
            audioPlaying = false
        end
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
    local ODFName = GetCfg(handle);
    local ObjClass = GetClassLabel(handle);
    local teamNum = GetTeamNum(handle);
    local isRecyclerVehicle = (ObjClass == "CLASS_RECYCLERVEHICLE" or ObjClass == "CLASS_RECYCLERVEHICLEH");

    if (teamNum == _Session.m_CompTeam) then
        if (isRecyclerVehicle) then
            _Session.m_EnemyRecycler = handle;
        end

        SetSkill(handle, _Session.m_Difficulty + 1);

        if (ObjClass == "CLASS_ARMORY") then
            _Session.m_HaveArmory = true;
        end

        if (_Session.m_HaveArmory) then
            if (string.sub(ODFName, 1, 6) == "ivtank") then
                GiveWeapon(handle, "gspstab_c");
            elseif (string.sub(ODFName, 1, 6) == "fvtank") then
                GiveWeapon(handle, "garc_c");
            end

            if (string.sub(ODFName, 1, 2) == "fv") then
                local randomNumber = GetRandomFloat(1.0);

                if (randomNumber < 0.3) then
                    GiveWeapon(handle, "gshield");
                elseif (randomNumber < 0.6) then
                    GiveWeapon(handle, "gabsorb");
                elseif (randomNumber < 0.9) then
                    GiveWeapon(handle, "gdeflect");
                end
            end
        end
    elseif (teamNum == _Session.m_StratTeam) then
        if (isRecyclerVehicle) then
            _Session.m_Recycler = handle;
        end

        if (_Session.m_MyGoal == 0) then
            ----------------------------------------------------------------------------------------
            -- BROKE OUT INTO MULTIPLE IF'S TO PLAY SPECIFIC AUDIO CLIP
            if (ObjClass == "CLASS_WINGMAN" or ObjClass == "CLASS_MORPHTANK") then
                if _Session.m_StartDone == true then -- ONLY AFTER GAME START IS DONE
                    audioGift = AudioMessage("vo_ia_gift_o.wav")
                end
                SetTeamNum(handle, _Session.m_PlayerTeam);
                SetBestGroup(handle);
            elseif (ObjClass == "CLASS_ASSAULTTANK" or ObjClass == "CLASS_WALKER") then
                if _Session.m_StartDone == true then -- ONLY AFTER GAME START IS DONE
                    audioGift = AudioMessage("vo_ia_gift_h.wav")
                end
                SetTeamNum(handle, _Session.m_PlayerTeam);
                SetBestGroup(handle);
            elseif (ObjClass == "CLASS_SERVICE") then
                if _Session.m_StartDone == true then -- ONLY AFTER GAME START IS DONE
                    audioGift = AudioMessage("vo_ia_gift_s.wav")
                end
                SetTeamNum(handle, _Session.m_PlayerTeam);
                SetBestGroup(handle);
            end
            -- elseif (ObjClass == "CLASS_SCAVENGER") then -- DID NOT EXIST IN INSTANT.DLL MAY BREAK
            --     audioGift = AudioMessage("vo_ia_gift_s.wav")
            --     SetTeamNum(handle, _Session.m_PlayerTeam);
            --     SetBestGroup(handle);
            -- end
            ----------------------------------------------------------------------------------------
        end

        if (ObjClass == "CLASS_ARTILLERY" or ObjClass == "CLASS_BOMBER") then
            if (_Session.m_LateGame == false) then
                _Session.m_LateGame = true;
                SetCPUAIPlan(AIPTypeL);
            end
        end

        SetSkill(handle, 3 - _Session.m_Difficulty);

        if (ObjClass == "CLASS_RECYCLER") then
            if (_Session.m_PastAIP0 == false) then
                _Session.m_PastAIP0 = true;

                local stratChoice = _Session.m_TurnCounter % 2;

                ----------------------------------------------------------------------------------------
                print("m_TurnCounter :: ", _Session.m_TurnCounter)
                print("stratChoice :: ", stratChoice)
                print("m_CPUTeamRace :: ", _Session.m_CPUTeamRace)
                
                if (_Session.m_CPUTeamRace == RACE_SCION) then
                    if (stratChoice == 0) then
                        SetCPUAIPlan(AIPType1);
                        print("AIPType1 :: ", modifiedStratChoice);
                    elseif (stratChoice == 1) then
                        SetCPUAIPlan(AIPType3);
                        print("AIPType3 :: ", modifiedStratChoice);
                    elseif (stratChoice == 2) then
                        SetCPUAIPlan(AIPType2);
                        print("AIPType2 :: ", modifiedStratChoice);
                    end
                else
                    local modifiedStratChoice = stratChoice % 2;

                    if (modifiedStratChoice == 0) then
                        SetCPUAIPlan(AIPType1);
                        print("AIPType1 :: ", modifiedStratChoice);
                    elseif (modifiedStratChoice == 1) then
                        SetCPUAIPlan(AIPType3);
                        print("AIPType3 :: ", modifiedStratChoice);
                    end
                end
                ----------------------------------------------------------------------------------------
            end
        end
    elseif ( _Session.m_AwareV13 == 0 and teamNum == _Session.m_PlayerTeam) then
        -- This block should never happen in normal IA mode, but if for some reason the player has a Scavenger in Pilot mode, 
        -- we should switch the extractor to the right team when it's deployed to prevent breaking.
        if (ObjClass == "CLASS_EXTRACTOR") then
            SetTeamNum(handle, _Session.m_StratTeam);
        end
    end

    if (_Session.m_PastAIP0 == false and (_Session.m_TurnCounter > (180 * _Session.m_GameTPS))) then
        _Session.m_PastAIP0 = true;

        local stratChoice = _Session.m_TurnCounter % 2;

        if (_Session.m_CPUTeamRace == RACE_SCION) then
            if (stratChoice == 0) then
                SetCPUAIPlan(AIPType1);
            elseif (stratChoice == 1) then
                SetCPUAIPlan(AIPType3);
            elseif (stratChoice == 2) then
                SetCPUAIPlan(AIPType2);
            end
        else
            local modifiedStratChoice = stratChoice % 2;

            if (modifiedStratChoice == 0) then
                SetCPUAIPlan(AIPType1);
            elseif (modifiedStratChoice == 1) then
                SetCPUAIPlan(AIPType3);
            end
        end
    end
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

    _Session.m_StartDone = false;
    _Session.m_GameOver = false;
    _Session.m_CompTeam = 5; -- 6 (MPI)
    _Session.m_StratTeam = 1;

    _Session.m_TurnCounter = 0;

    _Session.m_LateGame = false;
    _Session.m_HaveArmory = false;

    PreloadODF("ivrecy");
    PreloadODF("fvrecy");
    PreloadODF("ivrecycpu");
    PreloadODF("fvrecycpu");

    DoTaunt(TAUNTS_GameStart);
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
            -- ----------------------------------------------------------------------------------------
            -- _Session.m_HumanTeamRaceSelect = IFace_GetInteger("options.instant.bool3"); --0=ISDF, 1=SCION, #=OTHER
            -- _Session.m_CPUTeamRaceSelect = IFace_GetInteger("options.instant.bool4"); --0=ISDF, 1=SCION, #=OTHER

            -- if _Session.m_HumanTeamRaceSelect == 0 then
            --     _Session.m_HumanTeamRace = string.char(RACE_ISDF);
            -- elseif _Session.m_HumanTeamRaceSelect == 1 then
            --     _Session.m_HumanTeamRace = string.char(RACE_SCION);
            -- else
            --     _Session.m_HumanTeamRace = string.char(RACE_ISDF);
            -- end

            -- if _Session.m_CPUTeamRaceSelect == 0 then
            --     _Session.m_CPUTeamRace = string.char(RACE_ISDF);
            -- elseif _Session.m_CPUTeamRaceSelect == 1 then
            --     _Session.m_CPUTeamRace = string.char(RACE_SCION);
            -- else
            --     _Session.m_CPUTeamRace = string.char(RACE_ISDF);
            -- end
            -- ----------------------------------------------------------------------------------------
        else
            ----------------------------------------------------------------------------------------
            -- IGNORES MAP INF FILE FACTION MySide=#
            -- if (GetInstantMySide() == 1) then

            _Session.m_MySide = IFace_GetInteger("options.instant.bool2"); -- 0=SCION, 1=ISDF
            if (_Session.m_MySide == 1) then
            ----------------------------------------------------------------------------------------
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

            Ally(3, 1);
            Ally(1, 3);
            
            ----------------------------------------------------------------------------------------
            -- DISPATCH BLOCK MOVED TO END OF m_StartDone == false
            -- Goto(BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", "tankEnemy1"), "Recycler"); -- WORKAROUND?

            -- if (_Session.m_CPUTeamRace == RACE_SCION) then
            --     Attack(BuildObject("fvsent", _Session.m_CompTeam, "tankEnemy1"), _Session.m_Player);
            -- else
            --     Attack(BuildObject("ivmisl", _Session.m_CompTeam, "tankEnemy1"), _Session.m_Player);
            -- end
            ----------------------------------------------------------------------------------------

        end

        _Session.m_MyForce = GetInstantMyForce();
		_Session.m_CompForce = GetInstantCompForce();
		_Session.m_Difficulty = GetInstantDifficulty();

        ----------------------------------------------------------------------------------------
        print("MyForce :: ", _Session.m_MyForce)
		print("ComForce :: ", _Session.m_CompForce)
		print("Difficulty :: ", _Session.m_Difficulty)
        ----------------------------------------------------------------------------------------

        SetupExtraVehicles();

        local customCPURecycler = IFace_GetString("options.instant.string2");

        if (customCPURecycler ~= nil) then
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, customCPURecycler, "*vrecy", "RecyclerEnemy");
        else
            _Session.m_EnemyRecycler = BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vrecycpu", "*vrecy", "RecyclerEnemy");
        end

        local RecPos = GetPosition(_Session.m_EnemyRecycler);

        ----------------------------------------------------------------------------------------
        -- Spawn CPU vehicles.

        -- BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vscav", "*vscav", GetPositionNear(RecPos, 20.0, 40.0));
		-- BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 20.0, 40.0));
		BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 20.0, 40.0));

        if (_Session.m_CompForce > 0) then
            BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vturr", "gtow2"); --vturr
			BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vrckt", "gtow3"); --vturr
			BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vscout", GetPositionNear(RecPos, 20.0, 40.0));
			BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 20.0, 40.0)); --vscout

            if (_Session.m_CompForce > 1) then
                BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vatank", "gtow4"); --vturr
                BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*bspir", "*vatank", "gtow5"); --vturr
                BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0));
                BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0));
                -- BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0));
                -- BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 20.0, 40.0));
                BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 20.0, 40.0)); --vscout

                if (_Session.m_CompForce > 2) then
                    BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 20.0, 40.0));
                    BuildStartingVehicle(_Session.m_CompTeam, _Session.m_CPUTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 20.0, 40.0));
                end
            end
        end
        ----------------------------------------------------------------------------------------

        local customHumanRecycler = IFace_GetString("options.instant.string1");

        if (customHumanRecycler ~= nil) then
            _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, customHumanRecycler, "*vrecy", "Recycler");
        else
            _Session.m_Recycler = BuildStartingVehicle(_Session.m_StratTeam, _Session.m_HumanTeamRace, "*vrecy", "*vrecy", "Recycler");
        end

        RecPos = GetPosition(_Session.m_Recycler);

        -- Set to player team explicity because of pilot mode.
        if (_Session.m_AwareV13 == 1) then
            ----------------------------------------------------------------------------------------
            print("AwareV13 ::", _Session.m_AwareV13)
            -- BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vscav", "*vscav", GetPositionNear(RecPos, 20.0, 40.0)); -- TODO REMOVE
            ----------------------------------------------------------------------------------------
        end
        ----------------------------------------------------------------------------------------
        -- SIRBRAMBLEY
        -- PLAYER FORCE = SMALL
        -- REMOVED TO MAKE PLAYER STARTING FORCE HAVE NOTHING IF "SMALL" FOR HARDCORE PLAYERS
		-- BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 20.0, 40.0));
		-- BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 20.0, 40.0));

        -- PLAYER FORCE = MEDIUM
        if (_Session.m_MyForce > 0) then
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 40.0, 55.0)); -- 20.0, 40.0
			BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 30.0, 55.0)); -- 20.0, 40.0
            BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vscav", "*vscav", GetPositionNear(RecPos, 30.0, 45.0)); -- 20.0, 40.0

            -- PLAYER FORCE = LARGE
            if (_Session.m_MyForce > 1) then
                BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vturr", "*vturr", GetPositionNear(RecPos, 30.0, 45.0)); -- 20.0, 40.0
                BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vsent", "*vmisl", GetPositionNear(RecPos, 30.0, 45.0)); -- 20.0, 40.0

                -- PLAYER FORCE = XLARGE
                if (_Session.m_MyForce > 2) then
                    BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vtank", "*vtank", GetPositionNear(RecPos, 30.0, 45.0)); -- 20.0, 40.0
                    BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 40.0, 55.0)); -- 20.0, 40.0
                    BuildStartingVehicle(_Session.m_PlayerTeam, _Session.m_HumanTeamRace, "*vatank", "*vatank", GetPositionNear(RecPos, 40.0, 55.0)); -- 20.0, 40.0
                end

            end
        end
        ----------------------------------------------------------------------------------------

        if (_Session.m_AwareV13 == 0) then
            if (_Session.m_HumanTeamRace == string.char(RACE_ISDF)) then
                SetAIP("isdfteam.aip", _Session.m_StratTeam);
            else
                SetAIP("scionteam.aip", _Session.m_StratTeam);
            end

        end

        if (_Session.m_PastAIP0 == false) then
            SetCPUAIPlan(AIPType0);
        end

        local PlayerH = GetPlayerHandle(_Session.m_PlayerTeam);
        RemoveObject(PlayerH);
        RespawnPlayer(true);

        SetScrap(_Session.m_CompTeam, 40);
        SetScrap(_Session.m_StratTeam, 40);

        ----------------------------------------------------------------------------------------
        -- SIRBRAMBLEY
        SetRaceTeamColor() -- Forces Teamcolors to CPU when player has same race
        IntroShowObjective() -- Setup initial objective stuffs
        IntroDispatchEnemy() -- TODO ... waiting on fix from JJ for _Session.m_Player; have one goto rec and one goto player
        ----------------------------------------------------------------------------------------

    end

    ----------------------------------------------------------------------------------------
    -- SIRBRAMBLEY
    -- Deactivate the banner once the mission audio is done.
    IntroBannerEnd()
    ----------------------------------------------------------------------------------------

    -- Keep track of games.
    GameConditions();
end

function PlayerEjected(DeadObjectHandle)
    return DoEjectPilot;
end

function PlayerDied(DeadObjectHandle, bSniped)
    if (IsPerson(DeadObjectHandle) == false and bSniped == false) then
        return DoEjectPilot;
    end

    if (_Session.m_CanRespawn == 1 and IsAlive(_Session.m_Recycler)) then
        RespawnPlayer(false);
    else
        FailMission(GetTime() + 3.0);
    end

    return DLLHandled;
end

function ObjectKilled(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle) == false) then
        local bWasDeadPilot = IsPerson(DeadObjectHandle);

        if (bWasDeadPilot) then
            return DoEjectPilot;
        end

        return DLLHandled;
    end

    return PlayerDied(DeadObjectHandle, false);
end

function ObjectSniped(DeadObjectHandle, KillersHandle)
    if (IsPlayer(DeadObjectHandle) == false) then
        return DLLHandled;
    end

    return PlayerDied(DeadObjectHandle, true);
end

---------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------- Mission Related Logic --------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------

function RespawnPlayer(isGameStart)
    local recyclerPosition = GetPosition(_Session.m_Recycler);
    local respawnPosition = GetPositionNear(recyclerPosition, 10, 50);

    -- Prevent spawning within stuff.
    local PlayerODF = "";

    if (isGameStart) then
        PlayerODF = _Session.m_HumanTeamRace .. "vscout";
    else
        respawnPosition.y = respawnPosition.y + 50;
        PlayerODF = _Session.m_HumanTeamRace .. "spilo";
    end

    local PlayerH = BuildObject(PlayerODF, _Session.m_PlayerTeam, respawnPosition);
    SetAsUser(PlayerH, _Session.m_PlayerTeam);
    AddPilotByHandle(PlayerH);

    -- Taunt.
    if (isGameStart == false) then
        DoTaunt(TAUNTS_HumanShipDestroyed);
    end
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

function GameConditions()

    if (_Session.m_GameOver == false) then
        if (IsAlive(_Session.m_EnemyRecycler) == false) then
            -- Check to see if the DLL Team slot is filled first.
            local DLLHandle = GetObjectByTeamSlot(_Session.m_CompTeam, DLL_TEAM_SLOT_RECYCLER);

            if (IsAround(DLLHandle)) then
                _Session.m_EnemyRecycler = DLLHandle;
            else
                ----------------------------------------------------------------------------------------
                -- New outro for win condition
                IFace_Exec("bzgame_script_banners.cfg")
                IFace_Activate("BannerObjectiveWinFade");
                SetMusicIntensity(1)
                StartSoundEffect("music_win.wav") -- begin victory music

                ClearObjectives()
                AddObjective(">>> WELL DONE COMMANDER >>>\n\nYou kicked their ass.", "GREEN", 8.0)
                audioOutro = AudioMessage("vo_ia_outro_win.wav")
                SucceedMission(GetTime() + 10, "instantw.txt");
                ----------------------------------------------------------------------------------------

                -- Taunt for game over.
                -- DoTaunt(TAUNTS_CPURecyDestroyed);
                -- SucceedMission(GetTime() + 5, "instantw.txt");
                
                _Session.m_GameOver = true;
            end
        elseif (IsAlive(_Session.m_Recycler) == false) then
            -- Check to see if the DLL Team slot is filled first.
            local DLLHandle = GetObjectByTeamSlot(_Session.m_StratTeam, DLL_TEAM_SLOT_RECYCLER);

            if (IsAround(DLLHandle)) then
                _Session.m_Recycler = DLLHandle;
            else
                -- Taunt for game over.
                DoTaunt(TAUNTS_HumanRecyDestroyed);
                SucceedMission(GetTime() + 5, "instantl.txt");
                _Session.m_GameOver = true;
            end
        end
    end
end

function SetCPUAIPlan(type)
    if (type < AIPType0 or type >= MAX_AIP_TYPE) then
        type = AIPType3;
    end

    local AIPFile;
    local AIPString;

    if (_Session.m_CustomAIPStr ~= nil) then
        AIPString = _Session.m_CustomAIPStr;
    else
        AIPString = StockAIPNameBase;
    end

    -- First pass, try to find an AIP that is designed to use Provides for enemy team, thus it only cares about CPU Race. This makes adding races much easier.
    AIPFile = AIPString .. _Session.m_CPUTeamRace .. string.sub(AIPTypeExtensions, type, type);

    -- Fallback to old method if none exists.
    if (DoesFileExist(AIPFile) == false) then
        AIPFile = AIPString .. _Session.m_CPUTeamRace .. _Session.m_HumanTeamRace .. string.sub(AIPTypeExtensions, type, type);
    end

    SetAIP(AIPFile .. '.aip', _Session.m_CompTeam);

    if (_Session.m_PastAIP0) then
        DoTaunt(TAUNTS_Random);
    end
end

function SetupExtraVehicles()
    local AIPaths = GetAiPaths();

    for key, value in pairs(AIPaths) do
        local normalizedString = string.lower(value);

        -- Check if the path starts with MPI and then process it.
        if (string.sub(normalizedString, 1, 3) == "mpi") then
            -- Used for ODFs.
            local ODF1;
            local ODF2;

            -- Find the index of the first underscore.
            local underscore = string.find(normalizedString, "_");

            -- Misformat! No _ found! Bail!
            if (underscore == nil) then
                return;
            end

            local underscore2 = string.find(normalizedString, "_", underscore + 1);

            if (underscore2 == nil) then
                ODF1 = string.sub(normalizedString, underscore + 1);
            else
                ODF1 = string.sub(normalizedString, underscore + 1, underscore2 - 1);
                ODF2 = string.sub(normalizedString, underscore2 + 1);
            end

            -- Check the first 4 letters for what team this should be spawned for.
            local teamDiscrim = string.sub(normalizedString, 1, 4);

            if (teamDiscrim == "mpic") then
                if (ODF1 ~= nil) then
                    ODF1 = ReplaceCharacter(1, ODF1, _Session.m_CPUTeamRace);
                    BuildObject(ODF1, _Session.m_CompTeam, normalizedString);
                elseif (ODF2 ~= nil) then
                    ODF2 = ReplaceCharacter(1, ODF2, _Session.m_CPUTeamRace);
                    BuildObject(ODF2, _Session.m_CompTeam, normalizedString);
                end
            elseif (teamDiscrim == "mpih") then
                if (ODF1 ~= nil) then
                    ODF1 = ReplaceCharacter(1, ODF1, _Session.m_HumanTeamRace);
                    SetBestGroup(BuildObject(ODF1, _Session.m_StratTeam, normalizedString));
                elseif (ODF2 ~= nil) then
                    ODF2 = ReplaceCharacter(1, ODF2, _Session.m_HumanTeamRace);
                    SetBestGroup(BuildObject(ODF2, _Session.m_StratTeam, normalizedString));
                end
            end
        end
    end
end