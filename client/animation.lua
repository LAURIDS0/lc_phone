local phoneProps = nil

-- Debug function
local function debug(message)
    print('[LC Phone] ' .. message)
end

-- Load animation dictionaries
function loadAnimDict(dict)
    debug('Loading animation dict: ' .. dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Create phone prop
function createPhoneProp()
    local playerPed = PlayerPedId()
    deletePhoneProp()
    
    debug('Creating phone prop')
    RequestModel(Config.PhoneModel)
    while not HasModelLoaded(Config.PhoneModel) do
        Wait(1)
    end
    
    phoneProps = CreateObject(Config.PhoneModel, 1.0, 1.0, 1.0, true, true, false)
    local bone = GetPedBoneIndex(playerPed, 28422)
    
    -- Modified offsets to position phone better with walking animations
    AttachEntityToEntity(phoneProps, playerPed, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    SetModelAsNoLongerNeeded(Config.PhoneModel)
    debug('Phone prop created')
    
    -- Create a thread to handle phone position during movement
    CreateThread(function()
        while phoneProps ~= nil do
            local playerPed = PlayerPedId()
            -- If player is moving, adjust phone position slightly
            if IsPedWalking(playerPed) or IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
                -- Subtle adjustment of phone position during movement
                local bone = GetPedBoneIndex(playerPed, 28422)
                AttachEntityToEntity(phoneProps, playerPed, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
            end
            Wait(500)
        end
    end)
end

-- Delete phone prop
function deletePhoneProp()
    if phoneProps then
        debug('Deleting phone prop')
        DeleteEntity(phoneProps)
        phoneProps = nil
    end
end

-- Play phone animation
function loadPhoneAnimation(animType)
    local playerPed = PlayerPedId()
    local animData = Config.PhoneAnimations[animType]
    
    if not animData then
        debug('Animation type not found: ' .. animType)
        return
    end
    
    debug('Playing phone animation: ' .. animType)
    loadAnimDict(animData.dict)
    
    if animType == 'open' then
        createPhoneProp()
        -- Use a different flag for animations to allow movement
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, 50, 0, false, false, false)
    elseif animType == 'close' then
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, 50, 0, false, false, false)
        Wait(700)
        StopAnimTask(playerPed, animData.dict, animData.anim, 1.0)
        deletePhoneProp()
    elseif animType == 'call' then
        createPhoneProp()
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, 50, 0, false, false, false)
    end
    
    -- Create a thread to ensure animation continues during movement
    if animType == 'open' or animType == 'call' then
        CreateThread(function()
            while phoneProps ~= nil do
                local playerPed = PlayerPedId()
                if not IsEntityPlayingAnim(playerPed, animData.dict, animData.anim, 3) then
                    TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, 50, 0, false, false, false)
                end
                Wait(500)
            end
        end)
    end
end
