FactionLoadout = {
    -- The model that will be displayed in the Loadout section of the United War Mission Prep Screen.
    Model = '',

    -- The ODF that will be given to the player when they start the mission.
    ODF = ''
}

---@param Model string
---@param ODF string
function FactionLoadout:New(Model, ODF)
    local o = {}

    o.Model = Model or 0
    o.ODF = ODF or 0

    setmetatable(o, { __index = self })

    return o
end

return FactionLoadout;