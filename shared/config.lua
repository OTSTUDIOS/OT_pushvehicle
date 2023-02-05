Config = {}


Config.Framework = 'OX' -- Framework to use. ESX, QBCORE, OX
Config.target = false -- Use target system for vehicle push (disables TextUI)
Config.targetSystem = 'ox_target' -- Target System to use. ox_target, ox_target2
Config.Usebones = true -- Use bones for vehicle push
Config.PushKey = 'E' -- Key to push vehicle
Config.TurnRightKey = 'D' -- Keys to turn the vehicle while pushing it.
Config.TurnLeftKey = 'A' -- Keys to turn the vehicle while pushing it.
Config.TextUI = true -- Use Text UI for vehicle push
Config.useOTSkills = true -- Use OT Skills for XP gain from pushing vehicles. Found here: https://otstudios.tebex.io
Config.maxReward = 20 -- Max amount of xp that can be gained from pushing a vehicle per push.
Config.healthMin = 2000.0 -- Minimum health of vehicle to be able to push it.

Config.blacklist = { -- blacklist vehicle models from being pushed.
    [`phantom`] = true
}