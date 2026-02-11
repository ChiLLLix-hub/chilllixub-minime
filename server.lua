-- Store all active mini peds
-- Format: activePeds[serverSource][pedId] = {scale, boneIndex, offset, appearance}
local activePeds = {}

-- Helper function to broadcast to all clients except the sender
local function BroadcastToOthers(sourceId, eventName, ...)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local playerSource = tonumber(playerId)
        if playerSource ~= sourceId then
            TriggerClientEvent(eventName, playerSource, ...)
        end
    end
end

-- Helper function to broadcast to all clients
local function BroadcastToAll(eventName, ...)
    TriggerClientEvent(eventName, -1, ...)
end

-- Spawn mini ped
RegisterNetEvent('minime:server:spawn', function(pedId, scale, boneIndex, offset, appearance, animKey)
    local src = source
    
    -- Initialize player's ped table if it doesn't exist
    if not activePeds[src] then
        activePeds[src] = {}
    end
    
    -- Store ped data
    activePeds[src][pedId] = {
        scale = scale,
        boneIndex = boneIndex,
        offset = offset,
        appearance = appearance,
        animKey = animKey
    }
    
    -- Broadcast to all other clients
    BroadcastToOthers(src, 'minime:client:spawn', src, pedId, scale, boneIndex, offset, appearance, animKey)
    
    print(string.format('[MiniMe] Player %d spawned mini ped %d with animation: %s', src, pedId, animKey or 'none'))
end)

-- Update mini ped scale
RegisterNetEvent('minime:server:updateScale', function(pedId, newScale)
    local src = source
    
    if activePeds[src] and activePeds[src][pedId] then
        -- Update stored data
        activePeds[src][pedId].scale = newScale
        
        -- Broadcast to all other clients
        BroadcastToOthers(src, 'minime:client:updateScale', src, pedId, newScale)
        
        print(string.format('[MiniMe] Player %d updated scale for ped %d to %.2f', src, pedId, newScale))
    end
end)

-- Update mini ped attachment
RegisterNetEvent('minime:server:updateAttachment', function(pedId, boneIndex, offset)
    local src = source
    
    if activePeds[src] and activePeds[src][pedId] then
        -- Update stored data
        activePeds[src][pedId].boneIndex = boneIndex
        activePeds[src][pedId].offset = offset
        
        -- Broadcast to all other clients
        BroadcastToOthers(src, 'minime:client:updateAttachment', src, pedId, boneIndex, offset)
        
        print(string.format('[MiniMe] Player %d updated attachment for ped %d', src, pedId))
    end
end)

-- Update mini ped animation
RegisterNetEvent('minime:server:updateAnimation', function(pedId, animKey)
    local src = source
    
    if activePeds[src] and activePeds[src][pedId] then
        -- Update stored data
        activePeds[src][pedId].animKey = animKey
        
        -- Broadcast to all other clients
        BroadcastToOthers(src, 'minime:client:updateAnimation', src, pedId, animKey)
        
        print(string.format('[MiniMe] Player %d updated animation for ped %d to: %s', src, pedId, animKey or 'none'))
    end
end)

-- Delete single mini ped
RegisterNetEvent('minime:server:delete', function(pedId)
    local src = source
    
    if activePeds[src] and activePeds[src][pedId] then
        -- Remove from storage
        activePeds[src][pedId] = nil
        
        -- Broadcast to all other clients
        BroadcastToOthers(src, 'minime:client:delete', src, pedId)
        
        print(string.format('[MiniMe] Player %d deleted mini ped %d', src, pedId))
    end
end)

-- Delete all mini peds for a player
RegisterNetEvent('minime:server:deleteAll', function()
    local src = source
    
    if activePeds[src] then
        -- Get list of ped IDs before clearing
        local pedIds = {}
        for pedId, _ in pairs(activePeds[src]) do
            table.insert(pedIds, pedId)
        end
        
        -- Clear from storage
        activePeds[src] = {}
        
        -- Broadcast to all other clients
        BroadcastToOthers(src, 'minime:client:deleteAllForPlayer', src)
        
        print(string.format('[MiniMe] Player %d deleted all mini peds', src))
    end
end)

-- Request sync of all active peds (for newly joined players or players getting close)
RegisterNetEvent('minime:server:requestSync', function()
    local src = source
    
    -- Send all active peds to the requesting client
    TriggerClientEvent('minime:client:syncAll', src, activePeds)
    
    print(string.format('[MiniMe] Sent sync data to player %d', src))
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if activePeds[src] then
        -- Broadcast deletion to all clients
        BroadcastToAll('minime:client:deleteAllForPlayer', src)
        
        -- Clean up storage
        activePeds[src] = nil
        
        print(string.format('[MiniMe] Player %d disconnected, cleaned up mini peds', src))
    end
end)

-- Clean up on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Clear all data
        activePeds = {}
        print('[MiniMe] Server stopped, cleared all mini ped data')
    end
end)
