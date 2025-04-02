Clout = {}

-- Table to store player loaded callbacks
Clout.PlayerLoadedCallbacks = {}

-- Detect framework
function Clout.GetFramework()
    if GetResourceState(Config.Frameworks.qb) == 'started' then
        return 'qb', exports['qb-core']:GetCoreObject()
    elseif GetResourceState(Config.Frameworks.esx) == 'started' then
        return 'esx', exports['es_extended']:getSharedObject()
    elseif GetResourceState(Config.Frameworks.ox) == 'started' then
        return 'ox', exports['ox_core']
    elseif GetResourceState(Config.Frameworks.qbox) == 'started' then
        return 'qbox', exports['qbx_core']:GetCoreObject()
    elseif GetResourceState(Config.Frameworks.vrp) == 'started' then
        return 'vrp', nil -- vRP doesn't use exports typically
    end
    return 'unknown', nil
end

-- Initialize framework
local framework, frameworkObj = Clout.GetFramework()
if Config.Debug then
    print('[Clout] Detected framework: ' .. framework)
end

-- Register a callback for when the player loads
function Clout.OnPlayerLoaded(callback)
    table.insert(Clout.PlayerLoadedCallbacks, callback)
end

-- Trigger all registered callbacks
local function triggerPlayerLoadedCallbacks()
    local playerData = Clout.GetPlayerData()
    for _, callback in ipairs(Clout.PlayerLoadedCallbacks) do
        callback(playerData)
    end
end

-- Framework-specific player loaded events
if framework == 'qb' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        triggerPlayerLoadedCallbacks()
    end)
elseif framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        triggerPlayerLoadedCallbacks()
    end)
elseif framework == 'ox' then
    -- OX Core doesn't have a direct equivalent; use a custom check or event if provided
    Citizen.CreateThread(function()
        while true do
            if frameworkObj and Clout.GetPlayerData() then -- Check if player data is available
                triggerPlayerLoadedCallbacks()
                break
            end
            Citizen.Wait(1000)
        end
    end)
elseif framework == 'qbox' then
    RegisterNetEvent('QBX:Client:OnPlayerLoaded', function()
        triggerPlayerLoadedCallbacks()
    end)
elseif framework == 'vrp' then
    -- vRP typically doesn't have a direct client-side event; use a custom approach
    Citizen.CreateThread(function()
        while true do
            if vRP and vRP.getUserId and Clout.GetPlayerData() then
                triggerPlayerLoadedCallbacks()
                break
            end
            Citizen.Wait(1000)
        end
    end)
end

-- Get player data
function Clout.GetPlayerData()
    if framework == 'qb' then
        return frameworkObj.Functions.GetPlayerData()
    elseif framework == 'esx' then
        return frameworkObj.GetPlayerData()
    elseif framework == 'ox' then
        return frameworkObj -- Placeholder; adjust based on OX Core API
    elseif framework == 'qbox' then
        return frameworkObj.Functions.GetPlayerData()
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId()
        return user_id and { id = user_id } or nil -- Basic vRP data
    end
    return nil
end

-- Send notification
function Clout.Notify(message, type, duration)
    type = type or 'info'
    duration = duration or Config.Notify.duration
    if framework == 'qb' or framework == 'qbox' then
        frameworkObj.Functions.Notify(message, type, duration)
    elseif framework == 'esx' then
        frameworkObj.ShowNotification(message)
    elseif GetResourceState('ox_lib') == 'started' then
        exports.ox_lib:notify({title = 'Notification', description = message, type = type, duration = duration})
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(true, false)
    end
end

