Config = {}

-- General Settings
Config.UseIdentifiers = 'license' -- Options: 'license', 'steam', 'discord', 'ip'
Config.OpenKey = 'm' -- Default key to open the phone
Config.PhoneModel = `prop_npc_phone_02` -- Phone prop model
Config.CallVolume = 0.2 -- Default call volume

-- Phone Apps
Config.Apps = {
    ['phone'] = {
        name = 'Phone',
        icon = 'phone',
        color = '#27ae60',
        enabled = true
    },
    ['messages'] = {
        name = 'Messages',
        icon = 'comment',
        color = '#2ecc71',
        enabled = true
    },
    ['contacts'] = {
        name = 'Contacts',
        icon = 'user',
        color = '#3498db',
        enabled = true
    },
    ['settings'] = {
        name = 'Settings',
        icon = 'cog',
        color = '#636e72',
        enabled = true
    },
    ['twitter'] = {
        name = 'Twitter',
        icon = 'twitter',
        color = '#1da1f2',
        enabled = true
    },
    ['gallery'] = {
        name = 'Gallery',
        icon = 'image',
        color = '#e74c3c',
        enabled = true
    },
    ['bank'] = {
        name = 'Bank',
        icon = 'university',
        color = '#8e44ad',
        enabled = true
    }
}

-- Phone Number Format
Config.PhoneNumberPrefix = '555' -- Prefix for generated phone numbers
Config.PhoneNumberLength = 7 -- Total length of phone number (including prefix)

-- Phone Animation Settings
Config.PhoneAnimations = {
    ['open'] = {
        dict = 'cellphone@',
        anim = 'cellphone_text_in',
        flag = 50
    },
    ['close'] = {
        dict = 'cellphone@',
        anim = 'cellphone_text_out',
        flag = 50
    },
    ['call'] = {
        dict = 'cellphone@',
        anim = 'cellphone_call_listen_base',
        flag = 49
    }
}

-- Standalone Configuration
Config.DefaultBackground = 'default.png' -- Default phone background
Config.DefaultRingtone = 'ringtone_default.ogg' -- Default ringtone
Config.StorePhoneAsItem = true -- Whether the phone should be an item or always available
Config.PhoneItemName = 'phone' -- Name of the phone item if StorePhoneAsItem is true
