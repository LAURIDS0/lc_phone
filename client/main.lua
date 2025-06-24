local isPhoneOpen = false
local phoneData = {}
local currentApp = nil
local hasPhone = false

-- Function to open the phone
function OpenPhone()
    if isPhoneOpen or not hasPhone then return end
    
    TriggerServerEvent('lc_phone:server:GetPhoneData')
    isPhoneOpen = true
    SetNuiFocus(true, true)
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
    SendNUIMessage({
        action = "closePhone"
    })
    
    -- Play animation
    loadPhoneAnimation('close')
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
    if isPhoneOpen then
        ClosePhone()
    else
        OpenPhone()
    end
end)

-- Key mapping
RegisterKeyMapping('phone', 'Open Phone', 'keyboard', Config.OpenKey)

-- Initialize when player loads
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(2000) -- Wait for player to fully load
    TriggerServerEvent('lc_phone:server:PlayerLoaded')
end)
