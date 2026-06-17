fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 's_wyrd'
description 'Wyrdbound engine, character sheet, and dice combat for Ash & Iron RP. Displaced-only Wyrd layer; Modern characters live on standard Saga systems.'
author 'ValRavn'
version '0.4.0'

dependencies {
    's_lib',
    's_core',
}

ui_page 'web/hud.html'

shared_scripts {
    '@s_lib/init.lua',
    'shared/rules.lua',
    'shared/classes.lua',
    'shared/dice.lua',
    'shared/config.lua',
}

server_scripts {
    'server/util.lua',
    'server/sheet.lua',
    'server/combat.lua',
    'server/main.lua',
}

client_scripts {
    'client/sheet.lua',
    'client/combat.lua',
    'client/main.lua',
}

files {
    'web/hud.html',
    'web/hud.css',
    'web/hud.js',
}
