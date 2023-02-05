local ped = cache.ped
local pushing, remotepush = false, false
local vehiclepushing, keybind = nil, nil
local uiThreadRunning = false
local uiOpen = false

if Config.TextUI then
    if not Config.target then
        uiOpen = false
        local function uiThread()
            if uiThreadRunning then return end
            uiThreadRunning = true
            while uiThreadRunning do
                local sleep = 200
                if pushing then
                    sleep = 500
                    if uiOpen then
                        lib.hideTextUI()
                        uiOpen = false
                    end
                else
                    local coords = GetEntityCoords(ped)
                    local vehicle = lib.getClosestVehicle(coords, 5.0, false)
                    if not vehicle then
                        if uiOpen then
                            lib.hideTextUI()
                            uiOpen = false
                        end
                    else
                        local model = GetEntityModel(vehicle)
                        if Config.blacklist[model] then
                            if uiOpen then
                                lib.hideTextUI()
                                uiOpen = false
                            end
                        else
                            local health = GetVehicleEngineHealth(vehicle) <= Config.healthMin and true or false
                            if health then
                                local min, max = GetModelDimensions(model)
                                local size = max - min
                                local bonnet = #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (size.y / 2), 0.0)) < 1.45 and true or false
                                local trunk = #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (-size.y / 2), 0.0)) < 1.45 and true or false
                                if trunk or bonnet then
                                    if not uiOpen then
                                        lib.showTextUI(string.format('Hold [%s] to push vehicle', GetControlInstructionalButton(0, joaat('+' .. keybind.name) | 0x80000000, true):sub(3)))
                                        uiOpen = true
                                    end
                                else
                                    if uiOpen then
                                        lib.hideTextUI()
                                        uiOpen = false
                                    end
                                end
                            end
                        end
                    end
                end
                Wait(sleep)
            end
            if uiOpen then
                lib.hideTextUI()
                uiOpen = false
            end
        end
        CreateThread(uiThread)
    
        lib.onCache('vehicle', function(value)
            if value then
                uiThreadRunning = false
            else
                CreateThread(uiThread)
            end
        end)
    end
end

lib.onCache('ped', function(value)
    ped = value
end)

local function startMove(netid, direction)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    remotepush = true
    while remotepush do
        Wait(5)
        SetVehicleForwardSpeed(vehicle, direction == 'trunk' and 1.0 or -1.0)
        if NetworkGetEntityOwner(vehicle) ~= cache.playerId then
            remotepush = false
            return TriggerServerEvent('OT_pushvehicle:updateOwner', netid, direction)
        end
    end
end
RegisterNetEvent('OT_pushvehicle:startMove', startMove)

local function stopMove()
    remotepush = false
end
RegisterNetEvent('OT_pushvehicle:stopMove', stopMove)

local function startTurn(netid, direction)
    if direction ~= 'left' and direction ~= 'right' then return end
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    SetVehicleSteeringAngle(vehicle, direction == 'left' and 30.0 or direction == 'right' and -30.0)
end
RegisterNetEvent('OT_pushvehicle:startTurn', startTurn)

local function stopTurn(netid)
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    SetVehicleSteeringAngle(vehicle, 0.0)
end
RegisterNetEvent('OT_pushvehicle:stopTurn', stopTurn)

local function startPushing(vehicle)
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local size = max - min
    local coords = GetEntityCoords(cache.ped)
    local closest = #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (size.y / 2), 0.0)) < #(coords - GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (-size.y / 2), 0.0)) and 'bonnet' or 'trunk'
    local start = lib.callback.await('OT_pushvehicle:startPushing', false, NetworkGetNetworkIdFromEntity(vehicle), closest)
    if start then
        vehiclepushing = vehicle
        pushing = true
        AttachEntityToEntity(cache.ped, vehicle, 0, 0.0, closest == 'trunk' and min.y - 0.6 or -min.y + 0.4, closest == 'trunk' and min.z + 1.1 or max.z / 2, 0.0, 0.0, closest == 'trunk' and 0.0 or 180.0, 0.0, false, false, true, 0, true)
        lib.requestAnimDict('missfinale_c2ig_11')
        TaskPlayAnim(cache.ped, 'missfinale_c2ig_11', 'pushcar_offcliff_m', 1.5, 1.5, -1, 35, 0, false, false, false)
    end
end

local function stopPushing()
    TriggerServerEvent('OT_pushvehicle:stopPushing', NetworkGetNetworkIdFromEntity(vehiclepushing))
    vehiclepushing = nil
    pushing = false
    DetachEntity(cache.ped, true, false)
    ClearPedTasks(cache.ped)
end

keybind = lib.addKeybind({
    name = 'pushvehicle',
    description = 'Push broken down vehicle',
    defaultKey = 'E',
    onPressed = function(self)
        if Config.target then return end
        if pushing then return end
        local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 4, false)
        if not vehicle then return end
        startPushing(vehicle)
    end,
    onReleased = function(self)
        if Config.target then return end
        if not vehiclepushing then return end
        stopPushing()
    end
})

lib.addKeybind({
    name = 'pushvehicle_left',
    description = 'Turn left',
    defaultKey = Config.TurnLeftKey,
    onPressed = function(self)
        if not pushing then return end
        TriggerServerEvent('OT_pushvehicle:startTurn', NetworkGetNetworkIdFromEntity(vehiclepushing), 'left')
    end,
    onReleased = function(self)
        if not pushing then return end
        TriggerServerEvent('OT_pushvehicle:stopTurn', NetworkGetNetworkIdFromEntity(vehiclepushing))
    end
})

lib.addKeybind({
    name = 'pushvehicle_right',
    description = 'Turn right',
    defaultKey = Config.TurnRightKey,
    onPressed = function(self)
        if not pushing then return end
        TriggerServerEvent('OT_pushvehicle:startTurn', NetworkGetNetworkIdFromEntity(vehiclepushing), 'right')
    end,
    onReleased = function(self)
        if not pushing then return end
        TriggerServerEvent('OT_pushvehicle:stopTurn', NetworkGetNetworkIdFromEntity(vehiclepushing))
    end
})

if Config.target then
	local options = {
		{
			name = 'startPushing',
			icon = Config.Intrunkicon,
			label = 'Start Pushing',
			onSelect = function(data)
				startPushing(data.entity)
			end,
			action = function(entity)
				startPushing(entity)
			end,
			canInteract = function(entity)
                if pushing then return false end
				return true
			end
		},
        {
			name = 'stopPushing',
			icon = Config.Intrunkicon,
			label = 'Stop Pushing',
			onSelect = function(data)
				stopPushing()
			end,
			action = function(entity)
				stopPushing()
			end,
			canInteract = function(entity)
                if not pushing then return false end
				return true
			end
		}
	}
	local targetSystem = string.lower(Config.targetSystem)
	if targetSystem == 'qtarget' then
		if Config.Usebones then
			exports[targetSystem]:AddTargetBone({'boot', 'bonnet'}, {
				options = options,
				distance = Config.MaxDistance
			})
		else
			exports[targetSystem]:Vehicle({
				options = options,
				distance = Config.MaxDistance
			})
		end
	elseif targetSystem == 'ox_target' then
		if Config.Usebones then
			for i = 1, #options do
				options[i].bones = { 'bonnet', 'boot' }
			end
			exports[targetSystem]:addGlobalVehicle(options)
		else
			exports[targetSystem]:addGlobalVehicle(options)
		end
	elseif targetSystem == 'qb-target' then
		if Config.Usebones then
			exports[targetSystem]:AddTargetBone({'boot', 'bonnet'}, {
				options = options,
				distance = Config.MaxDistance
			})
		else
			exports[targetSystem]:AddGlobalVehicle({
				options = options,
				distance = Config.MaxDistance
			})
		end
	end
end