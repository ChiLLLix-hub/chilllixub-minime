local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}

-- Configuration
local Config = {
    DefaultScale = 1.0,
    MinScale = 0.1,
    MaxScale = 2.0
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

-- Function to spawn a mini ped
function SpawnMiniPed(scale, boneIndex, offset)
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
    FreezeEntityPosition(ped, true)
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
    
    -- Store ped data
    local pedId = #spawnedPeds + 1
    spawnedPeds[pedId] = {
        ped = ped,
        scale = scale,
        boneIndex = boneIndex,
        offset = offset
    }
    
    return pedId
end

-- Function to update ped scale
function UpdatePedScale(pedId, newScale)
    if spawnedPeds[pedId] and DoesEntityExist(spawnedPeds[pedId].ped) then
        newScale = math.max(Config.MinScale, math.min(Config.MaxScale, newScale))
        SetPedScale(spawnedPeds[pedId].ped, newScale)
        spawnedPeds[pedId].scale = newScale
        return true
    end
    return false
end

-- Function to update ped attachment
function UpdatePedAttachment(pedId, boneIndex, offset)
    if spawnedPeds[pedId] and DoesEntityExist(spawnedPeds[pedId].ped) then
        local playerPed = PlayerPedId()
        local ped = spawnedPeds[pedId].ped
        
        -- Detach if currently attached
        DetachEntity(ped, true, false)
        
        -- Attach to new bone
        if boneIndex then
            offset = offset or vector3(0.0, 0.0, 0.0)
            local bone = GetPedBoneIndex(playerPed, boneIndex)
            AttachEntityToEntity(ped, playerPed, bone, offset.x, offset.y, offset.z, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
            
            spawnedPeds[pedId].boneIndex = boneIndex
            spawnedPeds[pedId].offset = offset
        end
        
        return true
    end
    return false
end

-- Function to delete a spawned ped
function DeleteMiniPed(pedId)
    if spawnedPeds[pedId] and DoesEntityExist(spawnedPeds[pedId].ped) then
        DeleteEntity(spawnedPeds[pedId].ped)
        spawnedPeds[pedId] = nil
        return true
    end
    return false
end

-- Function to delete all spawned peds
function DeleteAllMiniPeds()
    for pedId, data in pairs(spawnedPeds) do
        if DoesEntityExist(data.ped) then
            DeleteEntity(data.ped)
        end
    end
    spawnedPeds = {}
end

-- Commands for testing
RegisterCommand('spawnminime', function(source, args)
    local scale = tonumber(args[1]) or 0.3
    local boneIndex = tonumber(args[2]) or 24818 -- Default: head bone
    local offset = vector3(0.0, 0.0, tonumber(args[3]) or 0.3)
    
    local pedId = SpawnMiniPed(scale, boneIndex, offset)
    QBCore.Functions.Notify('Mini-me spawned! ID: ' .. pedId, 'success')
end)

RegisterCommand('spawnminime_shoulder', function(source, args)
    local scale = tonumber(args[1]) or 0.3
    local boneIndex = 64729 -- Right shoulder bone
    local offset = vector3(0.15, 0.0, 0.0)
    
    local pedId = SpawnMiniPed(scale, boneIndex, offset)
    QBCore.Functions.Notify('Mini-me spawned on shoulder! ID: ' .. pedId, 'success')
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
        DeleteAllMiniPeds()
    end
end)

-- Export functions for use in other scripts
exports('SpawnMiniPed', SpawnMiniPed)
exports('UpdatePedScale', UpdatePedScale)
exports('UpdatePedAttachment', UpdatePedAttachment)
exports('DeleteMiniPed', DeleteMiniPed)
exports('DeleteAllMiniPeds', DeleteAllMiniPeds)
