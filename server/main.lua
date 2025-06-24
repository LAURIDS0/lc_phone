local PhoneData = {}

-- Get player identifier
local function GetPlayerIdentifier(source)
    local identifierType = string.lower(Config.UseIdentifiers)
    for _, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, string.len(identifierType .. ":")) == identifierType .. ":" then
            return v
        end
    end
    return nil
end

-- Generate a unique phone number
local function GeneratePhoneNumber()
    local number = Config.PhoneNumberPrefix
    for i = 1, (Config.PhoneNumberLength - #Config.PhoneNumberPrefix) do
        number = number .. math.random(0, 9)
    end
    
    -- Check if number exists
    local result = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM phone_numbers WHERE number = ?', {number})
    
    if result > 0 then
        return GeneratePhoneNumber() -- Generate a new number if this one exists
    end
    
    return number
end

-- Get player's phone number
local function GetPlayerPhoneNumber(identifier)
    local result = MySQL.Sync.fetchScalar('SELECT number FROM phone_numbers WHERE identifier = ?', {identifier})
    
    if not result then
        -- Player doesn't have a number, generate one
        local number = GeneratePhoneNumber()
        MySQL.Async.execute('INSERT INTO phone_numbers (identifier, number) VALUES (?, ?)', {
            identifier, number
        })
        return number
    end
    
    return result
end

-- Get player's phone data
local function GetPlayerPhoneData(identifier)
    if not PhoneData[identifier] then
        PhoneData[identifier] = {
            contacts = {},
            messages = {},
            calls = {},
            notifications = {},
            number = GetPlayerPhoneNumber(identifier)
        }
        
        -- Load contacts
        local contacts = MySQL.Sync.fetchAll('SELECT * FROM phone_contacts WHERE identifier = ?', {identifier})
        if contacts and #contacts > 0 then
            PhoneData[identifier].contacts = contacts
        end
        
        -- Load messages
        local messages = MySQL.Sync.fetchAll('SELECT * FROM phone_messages WHERE identifier = ?', {identifier})
        if messages and #messages > 0 then
            for _, msg in pairs(messages) do
                if msg.messages then
                    msg.messages = json.decode(msg.messages)
                end
            end
            PhoneData[identifier].messages = messages
        end
        
        -- Load calls
        local calls = MySQL.Sync.fetchAll('SELECT * FROM phone_calls WHERE identifier = ?', {identifier})
        if calls and #calls > 0 then
            for _, call in pairs(calls) do
                if call.calls then
                    call.calls = json.decode(call.calls)
                end
            end
            PhoneData[identifier].calls = calls
        end
        
        -- Load notifications
        local notifications = MySQL.Sync.fetchAll('SELECT * FROM phone_notifications WHERE identifier = ?', {identifier})
        if notifications and #notifications > 0 then
            PhoneData[identifier].notifications = notifications
        end
    end
    
    return PhoneData[identifier]
end

-- Save player's phone data
local function SavePlayerPhoneData(identifier)
    if not PhoneData[identifier] then return end
    
    -- Save contacts (delete and insert)
    MySQL.Async.execute('DELETE FROM phone_contacts WHERE identifier = ?', {identifier})
    if #PhoneData[identifier].contacts > 0 then
        for _, contact in pairs(PhoneData[identifier].contacts) do
            MySQL.Async.insert('INSERT INTO phone_contacts (identifier, name, number, iban) VALUES (?, ?, ?, ?)', {
                identifier, contact.name, contact.number, contact.iban
            })
        end
    end
    
    -- Save messages
    MySQL.Async.execute('DELETE FROM phone_messages WHERE identifier = ?', {identifier})
    if #PhoneData[identifier].messages > 0 then
        for _, chat in pairs(PhoneData[identifier].messages) do
            if chat.messages and #chat.messages > 0 then
                MySQL.Async.insert('INSERT INTO phone_messages (identifier, number, messages) VALUES (?, ?, ?)', {
                    identifier, chat.number, json.encode(chat.messages)
                })
            end
        end
    end
    
    -- Save calls
    MySQL.Async.execute('DELETE FROM phone_calls WHERE identifier = ?', {identifier})
    if #PhoneData[identifier].calls > 0 then
        MySQL.Async.insert('INSERT INTO phone_calls (identifier, calls) VALUES (?, ?)', {
            identifier, json.encode(PhoneData[identifier].calls)
        })
    end
end

-- Check if player has phone
local function HasPhone(source)
    if not Config.StorePhoneAsItem then return true end
    
    -- You could implement your inventory check here if needed
    -- For standalone, we'll use a basic implementation that assumes the player has a phone
    -- This can be expanded with an exports system later
    
    -- Example with ox_inventory:
    -- local hasPhone = exports.ox_inventory:GetItem(source, Config.PhoneItemName, nil, true)
    -- return hasPhone > 0
    
    return true
end

-- Events
RegisterNetEvent('lc_phone:server:PlayerLoaded')
AddEventHandler('lc_phone:server:PlayerLoaded', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if identifier then
        GetPlayerPhoneData(identifier)
    end
end)

RegisterNetEvent('lc_phone:server:GetPhoneData')
AddEventHandler('lc_phone:server:GetPhoneData', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if identifier and HasPhone(src) then
        local phoneData = GetPlayerPhoneData(identifier)
        TriggerClientEvent('lc_phone:client:ReceivePhoneData', src, phoneData)
    else
        TriggerClientEvent('lc_phone:client:PhoneNotAvailable', src)
    end
end)

-- Add a contact
RegisterNetEvent('lc_phone:server:AddContact')
AddEventHandler('lc_phone:server:AddContact', function(name, number, iban)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if identifier and HasPhone(src) then
        local contactData = {
            name = name,
            number = number,
            iban = iban or ''
        }
        
        table.insert(PhoneData[identifier].contacts, contactData)
        TriggerClientEvent('lc_phone:client:ContactAdded', src, contactData)
    end
end)

-- Send a message
RegisterNetEvent('lc_phone:server:SendMessage')
AddEventHandler('lc_phone:server:SendMessage', function(number, message)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if identifier and HasPhone(src) then
        local senderNumber = PhoneData[identifier].number
        local messageData = {
            sender = senderNumber,
            message = message,
            time = os.date('%H:%M')
        }
        
        -- Find target by phone number
        local targetIdentifier = nil
        local targetSource = nil
        
        for id, data in pairs(PhoneData) do
            if data.number == number then
                targetIdentifier = id
                break
            end
        end
        
        -- Add message to sender's messages
        local senderChat = nil
        for i, chat in pairs(PhoneData[identifier].messages) do
            if chat.number == number then
                senderChat = i
                break
            end
        end
        
        if senderChat then
            table.insert(PhoneData[identifier].messages[senderChat].messages, messageData)
        else
            table.insert(PhoneData[identifier].messages, {
                number = number,
                messages = {messageData}
            })
        end
        
        TriggerClientEvent('lc_phone:client:MessageSent', src, number, messageData)
        
        -- Add message to receiver's messages if they're online
        if targetIdentifier then
            local receiverChat = nil
            for i, chat in pairs(PhoneData[targetIdentifier].messages) do
                if chat.number == senderNumber then
                    receiverChat = i
                    break
                end
            end
            
            if receiverChat then
                table.insert(PhoneData[targetIdentifier].messages[receiverChat].messages, messageData)
            else
                table.insert(PhoneData[targetIdentifier].messages, {
                    number = senderNumber,
                    messages = {messageData}
                })
            end
            
            -- Find target source
            for _, player in ipairs(GetPlayers()) do
                if GetPlayerIdentifier(player) == targetIdentifier then
                    targetSource = player
                    break
                end
            end
            
            if targetSource then
                TriggerClientEvent('lc_phone:client:MessageReceived', targetSource, senderNumber, messageData)
            end
        end
    end
end)

-- Initialize on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Create tables if they don't exist
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `phone_numbers` (
            `identifier` varchar(100) NOT NULL,
            `number` varchar(20) NOT NULL,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

-- Save data when resource stops
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for identifier, _ in pairs(PhoneData) do
        SavePlayerPhoneData(identifier)
    end
end)

-- Player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if identifier and PhoneData[identifier] then
        SavePlayerPhoneData(identifier)
    end
end)
