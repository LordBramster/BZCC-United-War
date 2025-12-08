function InitAIPLua(team)
    AIPUtil.print(team, "Starting Lua Conditions for Scion Team AIP");
end

function ServicePodCondition(team, time)
    if (AIPUtil.GetScrap(team, false) < 2) then
        return false, "Team " .. team .. " does not have enough scrap to build a Service Pod."
    end

    if (DoesServicePodExist(team, time)) then
        return false, "A Service Pod is already present on the Recycler pad."
    end

    if (DoesServiceBayExist(team, time)) then
        return false, "A Service Bay already exists for team " .. team .. ". Service Pods are not needed."
    end

    return true, "Building Service Pod..."
end

function DoesServiceBayExist(team, time)
    return AIPUtil.CountUnits(team, "VIRTUAL_CLASS_SUPPLYDEPOT", "sameteam", true) > 0;
end

function DoesServicePodExist(team, time)
    return AIPUtil.CountUnits(team, "apserv", "sameteam", true) > 0;
end