local _UWDatabase = require("_UWDatabase")
local _Pool = require("_Pool")
local _NeutralBase = require("_NeutralBase")

UWService = {}

---@param factionId integer
---@return Faction
function UWService:GetFactionById(factionId)
    return _UWDatabase.Factions[factionId]
end

---@return Faction
function UWService:GetPlayerFaction()
    -- Lua doesn't index at 0, but the race values in the .CFG are (0, 1) so we need to make sure that we + 1 to conform with Lua standards.
    -- ISDF: 0 + 1 = 1
    -- Scion: 1 + 1 = 2
    return _UWDatabase.Factions[IFace_GetInteger(_UWDatabase.IFaceVariables.MYSIDE) + 1]
end

---@return Faction
function UWService:GetCPUFaction()
    -- Lua doesn't index at 0, but the race values in the .CFG are (0, 1) so we need to make sure that we + 1 to conform with Lua standards.
    -- ISDF: 0 + 1 = 1
    -- Scion: 1 + 1 = 2
    return _UWDatabase.Factions[IFace_GetInteger(_UWDatabase.IFaceVariables.HIS_SIDE) + 1]
end

---@param poolHandle Handle
function UWService:RegisterMapPool(poolHandle)
    _UWDatabase.Pools[#_UWDatabase.Pools + 1] = _Pool:New(poolHandle, GetPosition(poolHandle), GetDistance(poolHandle, _UWDatabase.Paths.RECYCLER_ENEMY))
end

---@param compTeam integer
---@param humanTeamRace string
---@param compTeamRace string
function UWService:SetCPUTeamColor(compTeam, humanTeamRace, compTeamRace)
    print("SETTING TEAM COLORS")

    if (humanTeamRace ~= compTeamRace) then
        return
    end

    print("TEAM COLOR SET")

    -- Set Teamcolor for CPU based on race
    if (compTeamRace == RACE_SCION) then
        SetTeamColor(compTeam, 95, 180, 120) -- Light Green for Scions
    elseif (compTeamRace == RACE_ISDF) then
        SetTeamColor(compTeam, 75, 140, 220) -- Light Blue for ISDF
    elseif (compTeamRace == RACE_ISDF_C) then
        SetTeamColor(compTeam, 20, 150, 255) -- Light Blue for ISDF (Classic)
    else
        SetTeamColor(compTeam, 140, 45, 45)  -- Red for NA
    end
end

---@param neutralTeam integer
---@param faction Faction
---@param spawnPath string
function UWService:CreateNeutralBase(neutralTeam, faction, spawnPath)
    _NeutralBase:SpawnOutpost(neutralTeam, faction, spawnPath)
end

return UWService