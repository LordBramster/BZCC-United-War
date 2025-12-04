-- This isn't an actual database. This is a mock of a concept to store data at runtime to assist with
-- data manipulation and function execution. We will follow the basic CRUD principles (Create, Read, Update, Delete).
local _Faction = require("_Faction")
local _FactionLoadout = require("_FactionLoadout")
local _Pool = require("_Pool")

UWDatabase = {
    Factions = {},
    Paths = {},

    IFaceVariables = {},
    CRCVariables = {},

    Pools = {}
}

function UWDatabase:Initialize()
    self:SeedData()
end

-- Adds an object or record to the specified table stored in the "database".
function UWDatabase:Create(tableName, record)
    local recordCount = #UWDatabase[tableName]
    UWDatabase[tableName][recordCount + 1] = record
end

function UWDatabase:Update(tableName, record)
    -- TODO: Implement this if needed.
end

function UWDatabase:Delete(tableName, record)
    -- TODO: Implement this if needed.
end

function UWDatabase:SeedData()
    print("Seeding UWDatabase Data")

    UWDatabase.Paths = {
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

    UWDatabase.IFaceVariables = {
        MYSIDE = "script.menu.myside",
        HIS_SIDE = "script.menu.hisside",

        DIFFICULTY = "script.menu.difficulty",
        MYFORCE = "script.menu.myforce",
        HISFORCE = "script.menu.hisforce",

        OBSTRUCTED_POOLS = "script.menu.obstructedpools",
        SCRAP_FIELDS = "script.menu.scrapfields",
        BIOMETAL_METEORS = "script.menu.biometalmeteors",
        ADVANCED_DEPOSIT = "script.menu.advanceddeposit",
        CAPTURABLE_BUILDINGS = "script.menu.capturablebuildings",

        NEUTRAL_ENEMIES = "script.menu.neutralenemies",
        MINEFIELDS = "script.menu.minefields",
        DISTRESS_CALLS = "script.menu.distresscalls",

        VEHICLE = "script.menu.vehicle",
        PILOT_PRIMARY = "script.menu.pilotprimary",
        PILOT_EQUIPMENT = "script.menu.pilotequipment",
        VEHICLE_FBX = "script.menu.vehicleFBX",
        PILOT_PRIMARY_FBX = "script.menu.pilotPrimaryFBX",
        PILOT_EQUIPMENT_FBX = "script.menu.pilotEquipmentFBX",

        VEHICLE_CHANGED = "script.menu.vehicleChanged",
        PRIMARY_WEAPON_CHANGED = "script.menu.pilotPrimaryChanged",
        EQUIPMENT_CHANGED = "script.menu.pilotEquipmentChanged",
        FACTION_CHANGED = "script.menu.factionChanged",
        ENEMY_FACTION_CHANGED = "script.menu.EnemyFactionChanged",

        BEGIN_GAME = "script.menu.beginGame"
    }

    UWDatabase.CRCVariables = {
        ["script_menu_vehicle_changed"] = CalcCRC(self.IFaceVariables.VEHICLE_CHANGED),
        ["script_menu_pilot_primary_changed"] = CalcCRC(self.IFaceVariables.PRIMARY_WEAPON_CHANGED),
        ["script_menu_pilot_equipment_changed"] = CalcCRC(self.IFaceVariables.EQUIPMENT_CHANGED),
        ["script_menu_faction_changed"] = CalcCRC(self.IFaceVariables.FACTION_CHANGED),
        ["script_menu_enemy_faction_changed"] = CalcCRC(self.IFaceVariables.ENEMY_FACTION_CHANGED),
        ["script_menu_game_start"] = CalcCRC(self.IFaceVariables.BEGIN_GAME)
    }

    -- Unique IFace Commands that we need to set up to match the CRC table.
    IFace_CreateCommand(self.IFaceVariables.VEHICLE_CHANGED)
    IFace_CreateCommand(self.IFaceVariables.PRIMARY_WEAPON_CHANGED)
    IFace_CreateCommand(self.IFaceVariables.EQUIPMENT_CHANGED)
    IFace_CreateCommand(self.IFaceVariables.FACTION_CHANGED)
    IFace_CreateCommand(self.IFaceVariables.ENEMY_FACTION_CHANGED)
    IFace_CreateCommand(self.IFaceVariables.BEGIN_GAME)

    -- Specify factions here that will be used across the mod.
    local ISDF = _Faction:New(1, 'i', 'ISDF', {
        ["Scout"] = _FactionLoadout:New('ivscout00.fbx', 'ivscout'),
        ["Recon"] = _FactionLoadout:New('ivmbik00.fbx', 'ivmbike'),
        ["Tank"] = _FactionLoadout:New('ivtank00.fbx', 'ivtank'),
        ["Missile Tank"] = _FactionLoadout:New('ivmisl00.fbx', 'ivmisl_dm'),
        ["Assault Tank"] = _FactionLoadout:New('ivatnk00.fbx', 'ivatank'),
        ["Walker"] = _FactionLoadout:New('ivwalk_skel.fbx', 'ivwalk'),
        ["Pulse / Sniper"] = _FactionLoadout:New('iwrifl_cockpit_skel.fbx', 'igsnip_c'),
        ["Bazooka / Rocket"] = _FactionLoadout:New('igbzka_skel_0.12.xsi', 'igbzka_c'),
        ["Shotgun"] = _FactionLoadout:New('iwrifl_cockpit_skel.fbx', 'igshot_c'),
        ["Jetpack"] = _FactionLoadout:New('igjetp00.fbx', 'igjetp'),
        ["Grenade Launcher"] = _FactionLoadout:New('iggren00.fbx', 'iggren'),
        ["Satchel Charge"] = _FactionLoadout:New('igsatc00_0.12.xsi', 'igsatc')
    })

    local Scion = _Faction:New(2, 'f', 'Scion', {
        ["Scout"] = _FactionLoadout:New('fvscout_skel.fbx', 'fvscout'),
        ["Recon"] = _FactionLoadout:New('fvsent_skel.fbx', 'fvsent'),
        ["Tank"] = _FactionLoadout:New('fvtank_skel.fbx', 'fvtank'),
        ["Missile Tank"] = _FactionLoadout:New('fvlancer_skel.fbx', 'fvarch'),
        ["Assault Tank"] = _FactionLoadout:New('fvtitan_skel.fbx', 'fvatank'),
        ["Walker"] = _FactionLoadout:New('fvwalk_skel.fbx', 'fvwalk'),
        ["Pulse / Sniper"] = _FactionLoadout:New('fwrifl_cockpit_stand_0.12.xsi', 'fgsnip_c'),
        ["Bazooka / Rocket"] = _FactionLoadout:New('fwbzka_cockpit_stand_0.12.xsi', 'fgbzka_c'),
        ["Shotgun"] = _FactionLoadout:New('fwrifl_cockpit_stand_0.12.xsi', 'fgbzka_c'), -- Scion doesn't have a Shotgun, so I've defaulted to the bazooka for now. Perhaps something new can be made for this? :)
        ["Jetpack"] = _FactionLoadout:New('fgjetp00_0.12.fbx', 'fgjetp'),
        ["Grenade Launcher"] = _FactionLoadout:New('fggren00_0.12.xsi', 'fggren'),
        ["Satchel Charge"] = _FactionLoadout:New('fgsatc00_0.12.xsi', 'fgsatc')
    })

    local ISDFClassic = _Faction:New(1, 'j', 'ISDF (Classic)', {
        ["Scout"] = _FactionLoadout:New('ivscout_arsvetus00.xsi', 'jvscout'),
        ["Recon"] = _FactionLoadout:New('ivmbik_arsvetus00.xsi', 'jvmbike'),
        ["Tank"] = _FactionLoadout:New('ivtank_arsvetus00.xsi', 'jvtank'),
        ["Missile Tank"] = _FactionLoadout:New('ivmisl_arsvetus00.xsi', 'jvmisl'),
        ["Assault Tank"] = _FactionLoadout:New('ivatnk_arsvetus00.xsi', 'jvatank'),
        ["Walker"] = _FactionLoadout:New('ivwalk_arsvetus_skel.xsi', 'jvwalk'),
        ["Pulse / Sniper"] = _FactionLoadout:New('iwrifl_cockpit_skel.fbx', 'igsnip_c'),
        ["Bazooka / Rocket"] = _FactionLoadout:New('igbzka_skel_0.12.xsi', 'igbzka_c'),
        ["Shotgun"] = _FactionLoadout:New('iwrifl_cockpit_skel.fbx', 'igshot_c'),
        ["Jetpack"] = _FactionLoadout:New('igjetp00.fbx', 'igjetp'),
        ["Grenade Launcher"] = _FactionLoadout:New('iggren00.fbx', 'iggren'),
        ["Satchel Charge"] = _FactionLoadout:New('igsatc00_0.12.xsi', 'igsatc')
    })

    UWDatabase.Factions = { ISDF, Scion, ISDFClassic }
end

return UWDatabase
