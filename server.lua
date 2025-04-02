Clout = {}

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

Clout.PlayerLoadedCallbacks = {}
function Clout.OnPlayerLoaded(callback)
    table.insert(Clout.PlayerLoadedCallbacks, callback)
end

local function triggerPlayerLoadedCallbacks(source)
    local playerData = Clout.GetPlayerData(source)
    for _, callback in ipairs(Clout.PlayerLoadedCallbacks) do
        callback(source, playerData)
    end
end

if framework == 'qb' then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
        local source = source
        triggerPlayerLoadedCallbacks(source)
    end)
elseif framework == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function(source, xPlayer)
        triggerPlayerLoadedCallbacks(source)
    end)
elseif framework == 'ox' then
    AddEventHandler('ox:playerLoaded', function(source)
        triggerPlayerLoadedCallbacks(source)
    end)
elseif framework == 'qbox' then
    RegisterNetEvent('QBX:Server:OnPlayerLoaded', function()
        local source = source
        triggerPlayerLoadedCallbacks(source)
    end)
elseif framework == 'vrp' then
    AddEventHandler('vRP:playerSpawn', function(user_id, source, first_spawn)
        if first_spawn then
            triggerPlayerLoadedCallbacks(source)
        end
    end)
end

function Clout.GetPlayerData(source)
    if framework == 'qb' then
        local Player = frameworkObj.Functions.GetPlayer(source)
        return Player and Player.PlayerData
    elseif framework == 'esx' then
        local xPlayer = frameworkObj.GetPlayerFromId(source)
        return xPlayer and xPlayer.getData()
    elseif framework == 'ox' then
        return frameworkObj
    elseif framework == 'qbox' then
        local Player = frameworkObj.Functions.GetPlayer(source)
        return Player and Player.PlayerData
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId(source)
        return user_id and { id = user_id } or nil
    end
    return nil
end

function Clout.HasItem(source, item, count)
    count = count or 1
    if framework == 'qb' or framework == 'qbox' then
        local Player = frameworkObj.Functions.GetPlayer(source)
        local itemData = Player.Functions.GetItemByName(item)
        return itemData and itemData.amount >= count
    elseif framework == 'esx' then
        local xPlayer = frameworkObj.GetPlayerFromId(source)
        return xPlayer.getInventoryItem(item).count >= count
    elseif GetResourceState('ox_inventory') == 'started' then
        local items = exports.ox_inventory:Search(source, 'count', {item})
        return items and items[item] >= count
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId(source)
        return vRP.getInventoryItemAmount(user_id, item) >= count
    end
    return false
end

function Clout.AddItem(source, item, count, metadata)
    if framework == 'qb' or framework == 'qbox' then
        local Player = frameworkObj.Functions.GetPlayer(source)
        return Player.Functions.AddItem(item, count, nil, metadata)
    elseif framework == 'esx' then
        local xPlayer = frameworkObj.GetPlayerFromId(source)
        return xPlayer.addInventoryItem(item, count)
    elseif GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, item, count, metadata)
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId(source)
        return vRP.giveInventoryItem(user_id, item, count)
    end
    return false
end

function Clout.RemoveItem(source, item, count, metadata)
    if framework == 'qb' or framework == 'qbox' then
        local Player = frameworkObj.Functions.GetPlayer(source)
        return Player.Functions.RemoveItem(item, count)
    elseif framework == 'esx' then
        local xPlayer = frameworkObj.GetPlayerFromId(source)
        return xPlayer.removeInventoryItem(item, count)
    elseif GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(source, item, count, metadata)
    elseif framework == 'vrp' then
        local user_id = vRP.getUserId(source)
        return vRP.tryGetInventoryItem(user_id, item, count)
    end
    return false
end

function Clout.CreateUseableItem(itemName, callback)
    if framework == 'qb' or framework == 'qbox' then
        frameworkObj.Functions.CreateUseableItem(itemName, function(source, item)
            callback(source, item)
        end)
    elseif framework == 'esx' then
        frameworkObj.RegisterUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    elseif GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:RegisterUsableItem(itemName, function(source, item)
            callback(source, item)
        end)
    elseif framework == 'vrp' then
        local vRP = exports.vrp
        if vRP then
            vRP.registerInventoryItem(itemName, function(user_id)
                local source = vRP.getUserSource(user_id)
                if source then
                    callback(source, { name = itemName })
                end
            end)
        else
            if Config.Debug then
                print('[Clout] vRP not detected for CreateUseableItem')
            end
        end
    else
        if Config.Debug then
            print('[Clout] No supported framework for CreateUseableItem')
        end
    end
end

-- Export server-side functions
exports('GetFramework', Clout.GetFramework)
exports('GetPlayerData', Clout.GetPlayerData)
exports('HasItem', Clout.HasItem)
exports('AddItem', Clout.AddItem)
exports('RemoveItem', Clout.RemoveItem)
exports('OnPlayerLoaded', Clout.OnPlayerLoaded)
exports('CreateUseableItem', Clout.CreateUseableItem)