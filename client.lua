Clout = {}

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
        return 'vrp', nil
    end
    return 'unknown', nil
end

local framework, frameworkObj = Clout.GetFramework()
if Config.Debug then
    print('[Clout] Detected framework: ' .. framework)
end

-- Existing player loaded callbacks
Clout.PlayerLoadedCallbacks = {}
function Clout.OnPlayerLoaded(callback)
    table.insert(Clout.PlayerLoadedCallbacks, callback)
end

local function triggerPlayerLoadedCallbacks()
    local playerData = Clout.GetPlayerData()
    for _, callback in ipairs(Clout.PlayerLoadedCallbacks) do
        callback(playerData)
    end
end

if framework == 'qb' then
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        triggerPlayerLoadedCallbacks()
    end)
elseif framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        triggerPlayerLoadedCallbacks()
    end)
elseif framework == 'ox' then
    Citizen.CreateThread(function()
        while true do
            if frameworkObj and Clout.GetPlayerData() then
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

function Clout.GetPlayerData()
    if framework == 'qb' then
        return frameworkObj.Functions.GetPlayerData()
    elseif framework == 'esx' then
        return frameworkObj.GetPlayerData()
    elseif framework == 'ox' then
        return frameworkObj
    elseif framework == 'qbox' then
        return frameworkObj.Functions.GetPlayerData()
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId()
        return user_id and { id = user_id } or nil
    end
    return nil
end

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

-- New function: Execute a command
function Clout.ExecuteCommand(command)
    if framework == 'qb' or framework == 'qbox' then
        ExecuteCommand(command)
    elseif framework == 'esx' then
        ExecuteCommand(command)
    elseif framework == 'ox' then
        ExecuteCommand(command)
    elseif framework == 'vrp' then
        -- vRP might require a different approach for commands
        if vRP then
            vRP.executeCommand(command)
        else
            ExecuteCommand(command)
        end
    else
        ExecuteCommand(command)
    end
end

-- Export the functions
exports('Notify', Clout.Notify)
exports('GetPlayerData', Clout.GetPlayerData)
exports('OnPlayerLoaded', Clout.OnPlayerLoaded)