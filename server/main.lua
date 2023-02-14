local pushing = {}
local beingpushed = {}
local skilltrack = {}

lib.callback.register('OT_pushvehicle:startPushing', function(source, netid, direction)
    if netid == nil or direction == nil then return end
    if pushing[source] then return false end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if beingpushed[netid] then return false end
    local owner = NetworkGetEntityOwner(vehicle)
    beingpushed[netid] = source
    pushing[source] = owner
    if Config.useOTSkills then skilltrack[source] = os.time() end
    TriggerClientEvent('OT_pushvehicle:startMove', owner, netid, direction, NetworkGetNetworkIdFromEntity(GetPlayerPed(source)))
    return true
end)

RegisterNetEvent('OT_pushvehicle:stopPushing', function(netid)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('OT_pushvehicle:stopMove', pushing[src])
    pushing[src] = nil
    beingpushed[netid] = nil
    if Config.useOTSkills then
        local xpgain = math.round((os.time() - skilltrack[src]) / 1.5)
        if xpgain >= 2.0 then exports.OT_skills:addXP(src, 'strength', xpgain <= Config.maxReward and xpgain or Config.maxReward) end
        skilltrack[src] = nil
    end
end)

RegisterNetEvent('OT_pushvehicle:startTurn', function(netid, direction)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('OT_pushvehicle:startTurn', pushing[src], netid, direction)
end)

RegisterNetEvent('OT_pushvehicle:stopTurn', function(netid)
    local src = source
    if not pushing[src] then return end
    TriggerClientEvent('OT_pushvehicle:stopTurn', pushing[src], netid)
end)

RegisterNetEvent('OT_pushvehicle:updateOwner', function(netid, direction)
    local src = source
    if not beingpushed[netid] then return end
    if not pushing[beingpushed[netid]] then return end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    local owner = NetworkGetEntityOwner(vehicle)
    pushing[beingpushed[netid]] = owner
    if not pushing[beingpushed[netid]] then return end
    TriggerClientEvent('OT_pushvehicle:startMove', owner, netid, direction)
end)

RegisterNetEvent('OT_pushvehicle:detach', function(netid)
    if not beingpushed[netid] then return end
    if not pushing[beingpushed[netid]] then return end
    TriggerClientEvent('OT_pushvehicle:detach', beingpushed[netid])
end)
