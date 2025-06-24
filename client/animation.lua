local phoneProps = nil

-- Load animation dictionaries
function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-- Create phone prop
function createPhoneProp()
    local playerPed = PlayerPedId()
    deletePhoneProp()
    
    RequestModel(Config.PhoneModel)
    while not HasModelLoaded(Config.PhoneModel) do
        Wait(1)
    end
    
    phoneProps = CreateObject(Config.PhoneModel, 1.0, 1.0, 1.0, true, true, false)
    local bone = GetPedBoneIndex(playerPed, 28422)
    
    AttachEntityToEntity(phoneProps, playerPed, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 2, true)
    SetModelAsNoLongerNeeded(Config.PhoneModel)
end

-- Delete phone prop
function deletePhoneProp()
    if phoneProps then
        DeleteEntity(phoneProps)
        phoneProps = nil
    end
end

-- Play phone animation
function loadPhoneAnimation(animType)
    local playerPed = PlayerPedId()
    local animData = Config.PhoneAnimations[animType]
    
    if not animData then return end
    
    loadAnimDict(animData.dict)
    
    if animType == 'open' then
        createPhoneProp()
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, animData.flag, 0, false, false, false)
    elseif animType == 'close' then
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, animData.flag, 0, false, false, false)
        Wait(700)
        StopAnimTask(playerPed, animData.dict, animData.anim, 1.0)
        deletePhoneProp()
    elseif animType == 'call' then
        createPhoneProp()
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 5.0, -1, -1, animData.flag, 0, false, false, false)
    end
end
