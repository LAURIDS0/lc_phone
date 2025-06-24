fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'LC Development'
description 'An advanced phone system for FiveM with various features and a user-friendly interface.'
version '1.3.0'

ui_page 'html/index.html'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/animation.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'html/*.html',
    'html/js/*.js',
    'html/img/*.png',
    'html/css/*.css',
    'html/img/backgrounds/*.png',
    -- 'html/img/apps/*.png',
    -- 'html/fonts/*.ttf',
    -- 'html/sounds/*.ogg'
}

dependencies {
    'oxmysql'
}

optional_dependencies {
    'ox_lib'
}