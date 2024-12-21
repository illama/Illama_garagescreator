fx_version 'cerulean'
game 'gta5'
lua54 'yes'  -- Ajout de cette ligne pour activer Lua 5.4

name 'illama_garagescreator'
description 'Illama Garages Creator est un outil puissant pour gérer les garages dans un serveur FiveM sous ESX. Compatible avec Illama Keys Creator, il offre une intégration parfaite pour gérer les véhicules et distribuer les clés automatiquement lors du spawn.'
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
