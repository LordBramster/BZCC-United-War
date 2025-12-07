Faction = {
    -- The ID (Primary Key) that represents the Faction
    ID = 0,

    -- The first character of the Faction name. E.G i for ISDF, f for Scion.
    Char = '',

    -- The name fo the Faction. E.G ISDF, or Scion.
    Name = '',

    -- Loadouts, specific to the UW starter window, but can be used elsewhere.
    -- Recommend populating this with the `FactionLoadout` object.
    FactionLoadouts = {}
}

---@param ID integer
---@param Char string
---@param Name string
---@param FactionLoadouts table
---@return Faction
function Faction:New(ID, Char, Name, FactionLoadouts)
    ---@type Faction
    local o = {
        ID = ID or 0,
        Char = Char or 0,
        Name = Name or 0,
        FactionLoadouts = FactionLoadouts or 0
    }

    setmetatable(o, { __index = self })

    return o
end

return Faction