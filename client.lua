local QBCore = exports['qb-core']:GetCoreObject()
-- Store peds by player server ID and ped ID
-- Format: spawnedPeds[serverSource][pedId] = {ped, scale, boneIndex, offset}
local spawnedPeds = {}

-- Configuration
local Config = {
    DefaultScale = 1.0,
    MinScale = 0.1,
    MaxScale = 2.0,
    MaxPedId = 999,
    SyncDelayMs = 1000,
    -- Predefined animations/scenarios
    Animations = {
        sitchair = {type = "scenario", name = "PROP_HUMAN_SEAT_CHAIR"},
        sitchair2 = {type = "scenario", name = "WORLD_HUMAN_PICNIC"},
        salute = {type = "anim", dict = "mp_player_int_uppersalute", anim = "mp_player_int_salute", flags = 49},
        wave = {type = "anim", dict = "friends@frj@ig_1", anim = "wave_a", flags = 49},
        dance = {type = "anim", dict = "anim@mp_player_intcelebrationmale@salsa_roll", anim = "salsa_roll", flags = 1},
        smoke = {type = "scenario", name = "WORLD_HUMAN_SMOKING"},
        guard = {type = "scenario", name = "WORLD_HUMAN_GUARD_STAND"}
    }
}

-- Function to get player's appearance data (works with qb-clothing, illenium-appearance, or fivem-appearance)
local function GetPlayerAppearance()
    local appearance = nil
    
    -- Try different appearance systems
    if exports['qb-clothing'] then
        appearance = exports['qb-clothing']:GetCurrentAppearance()
    elseif exports['illenium-appearance'] then
        appearance = exports['illenium-appearance']:GetAppearance()
    elseif exports['fivem-appearance'] then
        appearance = exports['fivem-appearance']:GetAppearance()
    end
    
    return appearance
end

-- Function to apply animation or scenario to ped
local function ApplyAnimationToPed(ped, animKey)
    if not animKey or not Config.Animations[animKey] then return false end
    
    local animData = Config.Animations[animKey]
    
    if animData.type == "scenario" then
        -- Apply scenario (like sitting, smoking, etc.)
        TaskStartScenarioInPlace(ped, animData.name, 0, true)
    elseif animData.type == "anim" then
        -- Request animation dictionary
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do
            Wait(10)
        end
        -- Play animation
        TaskPlayAnim(ped, animData.dict, animData.anim, 8.0, -8.0, -1, animData.flags or 1, 0, false, false, false)
    end
    
    return true
end

-- Function to apply appearance to ped
local function ApplyAppearanceToPed(ped, appearance)
    if not appearance then return false end
    
    -- Apply model (gender)
    if appearance.model then
        SetPedComponentVariation(ped, 0, 0, 0, 0) -- Face
    end
    
    -- Apply components (clothing)
    if appearance.components then
        for i = 0, 11 do
            if appearance.components[i] then
                SetPedComponentVariation(ped, i, appearance.components[i].drawable or 0, appearance.components[i].texture or 0, appearance.components[i].palette or 0)
            end
        end
    elseif appearance.drawables then -- Alternative format
        for i = 0, 11 do
            if appearance.drawables[i] then
                SetPedComponentVariation(ped, i, appearance.drawables[i], appearance.textures[i] or 0, 0)
            end
        end
    end
    
    -- Apply props (accessories)
    if appearance.props then
        for i = 0, 7 do
            if appearance.props[i] then
                if appearance.props[i].drawable and appearance.props[i].drawable ~= -1 then
                    SetPedPropIndex(ped, i, appearance.props[i].drawable, appearance.props[i].texture or 0, true)
                else
                    ClearPedProp(ped, i)
                end
            end
        end
    end
    
    -- Apply face features
    if appearance.faceFeatures then
        for i = 0, 19 do
            if appearance.faceFeatures[i] then
                SetPedFaceFeature(ped, i, appearance.faceFeatures[i])
            end
        end
    end
    
    -- Apply head blend data (heritage)
    if appearance.headBlend then
        SetPedHeadBlendData(ped, 
            appearance.headBlend.shapeFirst or 0,
            appearance.headBlend.shapeSecond or 0,
            appearance.headBlend.shapeThird or 0,
            appearance.headBlend.skinFirst or 0,
            appearance.headBlend.skinSecond or 0,
            appearance.headBlend.skinThird or 0,
            appearance.headBlend.shapeMix or 0.0,
            appearance.headBlend.skinMix or 0.0,
            appearance.headBlend.thirdMix or 0.0
        )
    end
    
    -- Apply head overlays (makeup, facial hair, etc.)
    if appearance.headOverlays then
        for i = 0, 12 do
            if appearance.headOverlays[i] then
                SetPedHeadOverlay(ped, i, 
                    appearance.headOverlays[i].value or 0,
                    appearance.headOverlays[i].opacity or 0.0
                )
                if appearance.headOverlays[i].color then
                    SetPedHeadOverlayColor(ped, i, 
                        appearance.headOverlays[i].colorType or 0,
                        appearance.headOverlays[i].color or 0,
                        appearance.headOverlays[i].secondColor or 0
                    )
                end
            end
        end
    end
    
    -- Apply hair color
    if appearance.hair then
        SetPedComponentVariation(ped, 2, appearance.hair.style or 0, 0, 0)
        SetPedHairColor(ped, appearance.hair.color or 0, appearance.hair.highlight or 0)
    elseif appearance.hairColor then
        SetPedHairColor(ped, appearance.hairColor.color or 0, appearance.hairColor.highlight or 0)
    end
    
    -- Apply eye color
    if appearance.eyeColor then
        SetPedEyeColor(ped, appearance.eyeColor)
    end
    
    return true
end

-- Function to spawn a mini ped (for own player)
function SpawnMiniPed(scale, boneIndex, offset, animKey)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerModel = GetEntityModel(playerPed)
    
    -- Request the model
    RequestModel(playerModel)
    while not HasModelLoaded(playerModel) do
        Wait(10)
    end
    
    -- Create the ped
    local ped = CreatePed(4, playerModel, playerCoords.x, playerCoords.y, playerCoords.z, 0.0, false, true)
    
    -- Configure ped
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCanRagdoll(ped, false)
    
    -- Don't freeze if animation is applied (animations need movement)
    if not animKey then
        FreezeEntityPosition(ped, true)
    end
    
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    
    -- Get and apply player's appearance
    local appearance = GetPlayerAppearance()
    if appearance then
        ApplyAppearanceToPed(ped, appearance)
    end
    
    -- Set scale
    scale = scale or Config.DefaultScale
    scale = math.max(Config.MinScale, math.min(Config.MaxScale, scale))
    SetPedScale(ped, scale)
    
    -- Attach to bone if specified
    if boneIndex then
        offset = offset or vector3(0.0, 0.0, 0.0)
        local bone = GetPedBoneIndex(playerPed, boneIndex)
        AttachEntityToEntity(ped, playerPed, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    end
    
    -- Apply animation if specified
    if animKey then
        -- Wait a bit for ped to be fully set up
        Wait(100)
        ApplyAnimationToPed(ped, animKey)
    end
    
    -- Initialize own player's ped table
    local myServerId = GetPlayerServerId(PlayerId())
    if not spawnedPeds[myServerId] then
        spawnedPeds[myServerId] = {}
    end
    
    -- Store ped data
    local pedId = 1
    for i = 1, Config.MaxPedId do
        if not spawnedPeds[myServerId][i] then
            pedId = i
            break
        end
    end
    
    spawnedPeds[myServerId][pedId] = {
        ped = ped,
        scale = scale,
        boneIndex = boneIndex,
        offset = offset,
        animKey = animKey
    }
    
    -- Trigger server event to broadcast to other clients
    TriggerServerEvent('minime:server:spawn', pedId, scale, boneIndex, offset, appearance, animKey)
    
    return pedId
end

-- Function to spawn a mini ped for another player
function SpawnMiniPedForPlayer(serverSource, pedId, scale, boneIndex, offset, appearance, animKey)
    -- Don't spawn own peds via this function
    local myServerId = GetPlayerServerId(PlayerId())
    if serverSource == myServerId then
        return
    end
    
    -- Get the target player
    local targetPlayer = GetPlayerFromServerId(serverSource)
    if targetPlayer == -1 then return end
    
    local targetPed = GetPlayerPed(targetPlayer)
    if not DoesEntityExist(targetPed) then return end
    
    local targetCoords = GetEntityCoords(targetPed)
    local targetModel = GetEntityModel(targetPed)
    
    -- Request the model
    RequestModel(targetModel)
    while not HasModelLoaded(targetModel) do
        Wait(10)
    end
    
    -- Create the ped
    local ped = CreatePed(4, targetModel, targetCoords.x, targetCoords.y, targetCoords.z, 0.0, false, true)
    
    -- Configure ped
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedCanRagdoll(ped, false)
    
    -- Don't freeze if animation is applied
    if not animKey then
        FreezeEntityPosition(ped, true)
    end
    
    SetEntityInvincible(ped, true)
    SetEntityCollision(ped, false, false)
    
    -- Apply appearance if provided
    if appearance then
        ApplyAppearanceToPed(ped, appearance)
    end
    
    -- Set scale
    scale = scale or Config.DefaultScale
    scale = math.max(Config.MinScale, math.min(Config.MaxScale, scale))
    SetPedScale(ped, scale)
    
    -- Attach to bone if specified
    if boneIndex then
        offset = offset or vector3(0.0, 0.0, 0.0)
        local bone = GetPedBoneIndex(targetPed, boneIndex)
        AttachEntityToEntity(ped, targetPed, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
    end
    
    -- Apply animation if specified
    if animKey then
        Wait(100)
        ApplyAnimationToPed(ped, animKey)
    end
    
    -- Initialize player's ped table
    if not spawnedPeds[serverSource] then
        spawnedPeds[serverSource] = {}
    end
    
    -- Store ped data
    spawnedPeds[serverSource][pedId] = {
        ped = ped,
        scale = scale,
        boneIndex = boneIndex,
        offset = offset,
        animKey = animKey
    }
end

-- Function to update ped scale
function UpdatePedScale(pedId, newScale)
    local myServerId = GetPlayerServerId(PlayerId())
    if spawnedPeds[myServerId] and spawnedPeds[myServerId][pedId] and DoesEntityExist(spawnedPeds[myServerId][pedId].ped) then
        newScale = math.max(Config.MinScale, math.min(Config.MaxScale, newScale))
        SetPedScale(spawnedPeds[myServerId][pedId].ped, newScale)
        spawnedPeds[myServerId][pedId].scale = newScale
        
        -- Trigger server event to broadcast to other clients
        TriggerServerEvent('minime:server:updateScale', pedId, newScale)
        
        return true
    end
    return false
end

-- Function to update ped attachment
function UpdatePedAttachment(pedId, boneIndex, offset)
    local myServerId = GetPlayerServerId(PlayerId())
    if spawnedPeds[myServerId] and spawnedPeds[myServerId][pedId] and DoesEntityExist(spawnedPeds[myServerId][pedId].ped) then
        local playerPed = PlayerPedId()
        local ped = spawnedPeds[myServerId][pedId].ped
        
        -- Detach if currently attached
        DetachEntity(ped, true, false)
        
        -- Attach to new bone
        if boneIndex then
            offset = offset or vector3(0.0, 0.0, 0.0)
            local bone = GetPedBoneIndex(playerPed, boneIndex)
            AttachEntityToEntity(ped, playerPed, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            
            spawnedPeds[myServerId][pedId].boneIndex = boneIndex
            spawnedPeds[myServerId][pedId].offset = offset
        end
        
        -- Trigger server event to broadcast to other clients
        TriggerServerEvent('minime:server:updateAttachment', pedId, boneIndex, offset)
        
        return true
    end
    return false
end

-- Function to update ped animation
function UpdatePedAnimation(pedId, animKey)
    local myServerId = GetPlayerServerId(PlayerId())
    if spawnedPeds[myServerId] and spawnedPeds[myServerId][pedId] and DoesEntityExist(spawnedPeds[myServerId][pedId].ped) then
        local ped = spawnedPeds[myServerId][pedId].ped
        
        -- Clear existing animation/scenario
        ClearPedTasks(ped)
        
        -- Apply new animation
        if animKey and ApplyAnimationToPed(ped, animKey) then
            spawnedPeds[myServerId][pedId].animKey = animKey
            
            -- Unfreeze ped if animation is applied
            FreezeEntityPosition(ped, false)
            
            -- Trigger server event to broadcast to other clients
            TriggerServerEvent('minime:server:updateAnimation', pedId, animKey)
            
            return true
        else
            -- Clear animation means freeze again
            spawnedPeds[myServerId][pedId].animKey = nil
            FreezeEntityPosition(ped, true)
            
            -- Trigger server event to broadcast to other clients
            TriggerServerEvent('minime:server:updateAnimation', pedId, nil)
        end
        
        return true
    end
    return false
end

-- Function to delete a spawned ped
function DeleteMiniPed(pedId)
    local myServerId = GetPlayerServerId(PlayerId())
    if spawnedPeds[myServerId] and spawnedPeds[myServerId][pedId] and DoesEntityExist(spawnedPeds[myServerId][pedId].ped) then
        DeleteEntity(spawnedPeds[myServerId][pedId].ped)
        spawnedPeds[myServerId][pedId] = nil
        
        -- Trigger server event to broadcast to other clients
        TriggerServerEvent('minime:server:delete', pedId)
        
        return true
    end
    return false
end

-- Function to delete all spawned peds
function DeleteAllMiniPeds()
    local myServerId = GetPlayerServerId(PlayerId())
    if spawnedPeds[myServerId] then
        for pedId, data in pairs(spawnedPeds[myServerId]) do
            if DoesEntityExist(data.ped) then
                DeleteEntity(data.ped)
            end
        end
        spawnedPeds[myServerId] = {}
    end
    
    -- Trigger server event to broadcast to other clients
    TriggerServerEvent('minime:server:deleteAll')
end

-- Client event handlers for network synchronization

-- Spawn mini ped for another player
RegisterNetEvent('minime:client:spawn', function(serverSource, pedId, scale, boneIndex, offset, appearance, animKey)
    SpawnMiniPedForPlayer(serverSource, pedId, scale, boneIndex, offset, appearance, animKey)
end)

-- Update scale for another player's mini ped
RegisterNetEvent('minime:client:updateScale', function(serverSource, pedId, newScale)
    if spawnedPeds[serverSource] and spawnedPeds[serverSource][pedId] then
        local ped = spawnedPeds[serverSource][pedId].ped
        if DoesEntityExist(ped) then
            newScale = math.max(Config.MinScale, math.min(Config.MaxScale, newScale))
            SetPedScale(ped, newScale)
            spawnedPeds[serverSource][pedId].scale = newScale
        end
    end
end)

-- Update attachment for another player's mini ped
RegisterNetEvent('minime:client:updateAttachment', function(serverSource, pedId, boneIndex, offset)
    if spawnedPeds[serverSource] and spawnedPeds[serverSource][pedId] then
        local ped = spawnedPeds[serverSource][pedId].ped
        if DoesEntityExist(ped) then
            -- Get the target player
            local targetPlayer = GetPlayerFromServerId(serverSource)
            if targetPlayer ~= -1 then
                local targetPed = GetPlayerPed(targetPlayer)
                if DoesEntityExist(targetPed) then
                    -- Detach if currently attached
                    DetachEntity(ped, true, false)
                    
                    -- Attach to new bone
                    if boneIndex then
                        offset = offset or vector3(0.0, 0.0, 0.0)
                        local bone = GetPedBoneIndex(targetPed, boneIndex)
                        AttachEntityToEntity(ped, targetPed, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                        
                        spawnedPeds[serverSource][pedId].boneIndex = boneIndex
                        spawnedPeds[serverSource][pedId].offset = offset
                    end
                end
            end
        end
    end
end)

-- Update animation for another player's mini ped
RegisterNetEvent('minime:client:updateAnimation', function(serverSource, pedId, animKey)
    if spawnedPeds[serverSource] and spawnedPeds[serverSource][pedId] then
        local ped = spawnedPeds[serverSource][pedId].ped
        if DoesEntityExist(ped) then
            -- Clear existing animation/scenario
            ClearPedTasks(ped)
            
            -- Apply new animation
            if animKey then
                ApplyAnimationToPed(ped, animKey)
                FreezeEntityPosition(ped, false)
                spawnedPeds[serverSource][pedId].animKey = animKey
            else
                FreezeEntityPosition(ped, true)
                spawnedPeds[serverSource][pedId].animKey = nil
            end
        end
    end
end)

-- Delete another player's mini ped
RegisterNetEvent('minime:client:delete', function(serverSource, pedId)
    if spawnedPeds[serverSource] and spawnedPeds[serverSource][pedId] then
        local ped = spawnedPeds[serverSource][pedId].ped
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
        spawnedPeds[serverSource][pedId] = nil
    end
end)

-- Delete all mini peds for a specific player
RegisterNetEvent('minime:client:deleteAllForPlayer', function(serverSource)
    if spawnedPeds[serverSource] then
        for pedId, data in pairs(spawnedPeds[serverSource]) do
            if DoesEntityExist(data.ped) then
                DeleteEntity(data.ped)
            end
        end
        spawnedPeds[serverSource] = nil
    end
end)

-- Sync all active mini peds (for newly connected clients)
RegisterNetEvent('minime:client:syncAll', function(allPeds)
    for serverSource, peds in pairs(allPeds) do
        for pedId, data in pairs(peds) do
            SpawnMiniPedForPlayer(serverSource, pedId, data.scale, data.boneIndex, data.offset, data.appearance, data.animKey)
        end
    end
end)

-- Commands for testing
RegisterCommand('spawnminime', function(source, args)
    local scale = tonumber(args[1]) or 0.3
    local boneIndex = tonumber(args[2]) or 24818 -- Default: head bone
    local offset = vector3(0.0, 0.0, tonumber(args[3]) or 0.3)
    local animKey = args[4] -- Optional animation key
    
    local pedId = SpawnMiniPed(scale, boneIndex, offset, animKey)
    if animKey then
        QBCore.Functions.Notify('Mini-me spawned with ' .. animKey .. ' animation! ID: ' .. pedId, 'success')
    else
        QBCore.Functions.Notify('Mini-me spawned! ID: ' .. pedId, 'success')
    end
end)

RegisterCommand('spawnminime_shoulder', function(source, args)
    local scale = tonumber(args[1]) or 0.3
    local boneIndex = 64729 -- Right shoulder bone
    local offset = vector3(0.15, 0.0, 0.0)
    local animKey = args[2] -- Optional animation key
    
    local pedId = SpawnMiniPed(scale, boneIndex, offset, animKey)
    if animKey then
        QBCore.Functions.Notify('Mini-me spawned on shoulder with ' .. animKey .. ' animation! ID: ' .. pedId, 'success')
    else
        QBCore.Functions.Notify('Mini-me spawned on shoulder! ID: ' .. pedId, 'success')
    end
end)

RegisterCommand('scaleminime', function(source, args)
    local pedId = tonumber(args[1])
    local scale = tonumber(args[2])
    
    if not pedId or not scale then
        QBCore.Functions.Notify('Usage: /scaleminime [pedId] [scale]', 'error')
        return
    end
    
    if UpdatePedScale(pedId, scale) then
        QBCore.Functions.Notify('Scale updated!', 'success')
    else
        QBCore.Functions.Notify('Invalid ped ID', 'error')
    end
end)

RegisterCommand('animminime', function(source, args)
    local pedId = tonumber(args[1])
    local animKey = args[2]
    
    if not pedId then
        QBCore.Functions.Notify('Usage: /animminime [pedId] [animKey]', 'error')
        QBCore.Functions.Notify('Available animations: sitchair, sitchair2, salute, wave, dance, smoke, guard', 'info')
        return
    end
    
    if UpdatePedAnimation(pedId, animKey) then
        if animKey then
            QBCore.Functions.Notify('Animation "' .. animKey .. '" applied!', 'success')
        else
            QBCore.Functions.Notify('Animation cleared!', 'success')
        end
    else
        QBCore.Functions.Notify('Invalid ped ID', 'error')
    end
end)

RegisterCommand('listanims', function()
    QBCore.Functions.Notify('Available animations:', 'info')
    for key, _ in pairs(Config.Animations) do
        QBCore.Functions.Notify('- ' .. key, 'info')
    end
end)

RegisterCommand('deleteminime', function(source, args)
    local pedId = tonumber(args[1])
    
    if not pedId then
        QBCore.Functions.Notify('Usage: /deleteminime [pedId]', 'error')
        return
    end
    
    if DeleteMiniPed(pedId) then
        QBCore.Functions.Notify('Mini-me deleted!', 'success')
    else
        QBCore.Functions.Notify('Invalid ped ID', 'error')
    end
end)

RegisterCommand('deleteallminime', function()
    DeleteAllMiniPeds()
    QBCore.Functions.Notify('All mini-mes deleted!', 'success')
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Delete all peds for all players
        for serverSource, peds in pairs(spawnedPeds) do
            for pedId, data in pairs(peds) do
                if DoesEntityExist(data.ped) then
                    DeleteEntity(data.ped)
                end
            end
        end
        spawnedPeds = {}
    end
end)

-- Request sync when resource starts
CreateThread(function()
    Wait(Config.SyncDelayMs)
    TriggerServerEvent('minime:server:requestSync')
end)

-- Export functions for use in other scripts
exports('SpawnMiniPed', SpawnMiniPed)
exports('UpdatePedScale', UpdatePedScale)
exports('UpdatePedAttachment', UpdatePedAttachment)
exports('UpdatePedAnimation', UpdatePedAnimation)
exports('DeleteMiniPed', DeleteMiniPed)
exports('DeleteAllMiniPeds', DeleteAllMiniPeds)
