fx_version 'cerulean'
game 'gta5'
lua54 'yes'  -- Ajout de cette ligne pour activer Lua 5.4

name 'illama_garagescreator'
description 'Système simple pour créer des garages pour la version 1.1X.X de ESX.'
author 'Illama'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    '@ox_target/client.lua',
    'client/*.lua'
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target'
}