NeutralBase = {
    ---@type integer
    TeamNumber = 0,

    ---@type Faction
    Faction = nil,

    ---@type string
    SpawnPath = '',

    ---@type string[]
    UnitRoster = {
        "Scout",
        "Recon",
        "Tank",
        "Missile Tank",
        "Assault Tank"
    },

    BaseLayouts = {
        {
            { "ibpgen", SetVector(0, 0, 0) },
            { "ibgtow", SetVector(-32, 0, 32) },
            { "ibgtow", SetVector(32, 0, -32) },
        }
    }
}

local function CreateCircle(count, origin, radius)
    local points = {}
    local increment = (2 * math.pi) / count
    local current = 0

    for i = 1, count do
        local x = math.cos(current) * radius + origin.x
        local z = math.sin(current) * radius + origin.z
        local y = TerrainFindFloor(x, z)

        current = current + increment
        points[#points+1] = SetVector(x, y, z)
    end

    return points
end

function NeutralBase:SpawnOutpost(teamNumber, faction, spawnPath)
    self.TeamNumber = teamNumber
    self.Faction = faction
    self.SpawnPath = spawnPath

    -- Test
    local baseLayout = self.BaseLayouts[1]

    for i = 1, #baseLayout do
        local building = baseLayout[i]
        local ODF = building[1]
        local buildingVector = building[2]

        local spawnPoint = GetPosition(self.SpawnPath)
        spawnPoint.x = spawnPoint.x + buildingVector.x
        spawnPoint.z = spawnPoint.z + buildingVector.z
        spawnPoint.y = TerrainFindFloor(spawnPoint.x, spawnPoint.z)

        BuildObject(ODF, self.TeamNumber, spawnPoint)
    end

    -- Create a path around the base for enemies to patrol.
    local pos = GetPosition(spawnPath)
    local patrolPathName = spawnPath .. "_patrol"
    CreatePath(patrolPathName, pos.x, pos.z)

    -- Grab a circle from the function above.
    local circlePoints = CreateCircle(6, pos, 100)

    for i = 1, #circlePoints do
        local circlePoint = circlePoints[i]
        AddPathPoint(patrolPathName, circlePoint.x, circlePoint.z)
    end

    -- Attempt to remove the first path point.
    RemovePathPoint(patrolPathName, 0)

    for i = 1, 3 do
        local unitToBuild = self.Faction.FactionLoadouts[self.UnitRoster[math.ceil(GetRandomFloat(1, #self.UnitRoster))]].ODF
        local unit = BuildObject(unitToBuild, self.TeamNumber, GetPositionNear(self.SpawnPath, 30, 30))
        SetRandomHeadingAngle(unit)
        Patrol(unit, patrolPathName)
    end
end

return NeutralBase
