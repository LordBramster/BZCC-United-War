Pool = {
    -- Handle for generic use.
    Handle = 0,

    -- So we don't need to call GetPosition() multiple times, we can just store it.
    Position = 0,

    -- Another CPU only variable. We want this so we can calculate the distance between the pool and the CPU Recycler for priority use.
    DistanceFromCPURecycler = 0,
}

---@param Handle Handle
---@param Position Vector
---@param DistanceFromCPURecycler integer
---@return Pool
function Pool:New(Handle, Position, DistanceFromCPURecycler)
    ---@type Pool
    local o = {
        Handle = Handle or 0,
        Position = Position or 0,
        DistanceFromCPURecycler = DistanceFromCPURecycler or 0
    }

    setmetatable(o, { __index = self })

    return o
end

return Pool
