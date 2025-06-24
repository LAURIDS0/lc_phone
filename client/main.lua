local isPhoneOpen = false
local phoneData = {}
local currentApp = nil
local hasPhone = true  -- Changed default to true for easier testing

-- Function to open the phone
function OpenPhone()
    if isPhoneOpen or not hasPhone then return end
    
    TriggerServerEvent('lc_phone:server:GetPhoneData')
    isPhoneOpen = true
    
    -- Set NUI focus but allow player movement (last param to false)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true) -- This allows movement while using NUI
    
    -- Disable aiming and attacking when phone is open
    -- but allow other movement keys
    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim
    DisableControlAction(0, 47, true) -- Weapon
    DisableControlAction(0, 58, true) -- Weapon
    
    SendNUIMessage({
        action = "openPhone"
    })
    
    -- Play animation
    loadPhoneAnimation('open')
end

-- Function to close the phone
function ClosePhone()
    if not isPhoneOpen then return end
    
    isPhoneOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false) -- Reset focus
    
    -- Re-enable all controls
    EnableAllControlActions(0)
    
    SendNUIMessage({
        action = "closePhone"
    })
    
    -- Play animation
    loadPhoneAnimation('close')
end

-- Key handler function
function HandleKeyPress()
    if not hasPhone then
        -- Notification that the player doesn't have a phone
        TriggerEvent('ox_lib:notify', {
            title = 'Phone',
            description = 'You don\'t have a phone',
            type = 'error'
        })
        return
    end
    
    if isPhoneOpen then
        ClosePhone()
    else
        OpenPhone()
    end
end

-- NUI Callbacks
RegisterNUICallback('closePhone', function(data, cb)
    ClosePhone()
    cb('ok')
end)

RegisterNUICallback('openApp', function(data, cb)
    currentApp = data.app
    cb({
        app = currentApp,
        appData = phoneData[currentApp] or {}
    })
end)

RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('lc_phone:server:AddContact', data.name, data.number, data.iban)
    cb('ok')
end)

RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('lc_phone:server:SendMessage', data.number, data.message)
    cb('ok')
end)

-- Events from server
RegisterNetEvent('lc_phone:client:ReceivePhoneData')
AddEventHandler('lc_phone:client:ReceivePhoneData', function(data)
    phoneData = data
    hasPhone = true
    SendNUIMessage({
        action = "updatePhoneData",
        data = phoneData
    })
end)

RegisterNetEvent('lc_phone:client:PhoneNotAvailable')
AddEventHandler('lc_phone:client:PhoneNotAvailable', function()
    hasPhone = false
    if isPhoneOpen then
        ClosePhone()
        -- You could add a notification here
    end
end)

RegisterNetEvent('lc_phone:client:ContactAdded')
AddEventHandler('lc_phone:client:ContactAdded', function(contactData)
    SendNUIMessage({
        action = "contactAdded",
        contact = contactData
    })
end)

RegisterNetEvent('lc_phone:client:MessageSent')
AddEventHandler('lc_phone:client:MessageSent', function(number, messageData)
    SendNUIMessage({
        action = "messageSent",
        number = number,
        message = messageData
    })
end)

RegisterNetEvent('lc_phone:client:MessageReceived')
AddEventHandler('lc_phone:client:MessageReceived', function(number, messageData)
    SendNUIMessage({
        action = "messageReceived",
        number = number,
        message = messageData
    })
    
    -- Play notification sound
    PlaySound(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 0, 0, 1)
end)

-- Commands
RegisterCommand('phone', function()
    HandleKeyPress()
end)

-- Key mapping
RegisterKeyMapping('phone', 'Open Phone', 'keyboard', Config.OpenKey)

-- Control loop while phone is open
CreateThread(function()
    while true do
        if isPhoneOpen then
            -- Disable specific controls when phone is open but still allow movement
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
            
            -- Allow movement keys
            EnableControlAction(0, 30, true) -- Move LR
            EnableControlAction(0, 31, true) -- Move UD
            EnableControlAction(0, 21, true) -- Sprint
            EnableControlAction(0, 22, true) -- Jump
            
            -- Handle ESC key to close phone
            if IsControlJustPressed(0, 177) then -- ESC key
                ClosePhone()
            end
        end
        Wait(0)
    end
end)

-- Initialize when player loads
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(2000) -- Wait for player to fully load
    print('[LC Phone] Resource started - Press ' .. Config.OpenKey .. ' to open phone')
    TriggerServerEvent('lc_phone:server:PlayerLoaded')
end)
