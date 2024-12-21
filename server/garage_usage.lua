local ESX = exports["es_extended"]:getSharedObject()
local cachedGarages = {}

-- Chargement des garages au démarrage du serveur
CreateThread(function()
    LoadGarages()
end)

-- Fonction de chargement des garages
function LoadGarages()
    MySQL.Async.fetchAll('SELECT * FROM illama_garages', {}, function(results)
        if results then
            cachedGarages = results
        end
    end)
end

-- Event pour les nouveaux garages créés
RegisterNetEvent('illama_garagescreator:garageCreated')
AddEventHandler('illama_garagescreator:garageCreated', function()
    LoadGarages()
end)

-- Récupération des garages par les clients
RegisterNetEvent('illama_garagescreator:requestGarages')
AddEventHandler('illama_garagescreator:requestGarages', function()
    local source = source
    TriggerClientEvent('illama_garagescreator:receiveGarages', source, cachedGarages)
end)

-- Callback pour obtenir les véhicules d'un garage
ESX.RegisterServerCallback('illama_garagescreator:getVehicles', function(source, cb, garageId)
    for _, garage in ipairs(cachedGarages) do
        if garage.id == garageId then
            cb(garage.vehicles)
            return
        end
    end
    cb({})
end)