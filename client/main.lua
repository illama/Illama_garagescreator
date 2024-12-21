local ESX = exports["es_extended"]:getSharedObject()
local isUIOpen = false
local isSelectingPosition = false
local selectedGaragePos = nil
local selectedSpawnPos = nil
local selectedHeading = 0

-- Gestion de l'interface
RegisterNetEvent('illama_garagescreator:openUI')
AddEventHandler('illama_garagescreator:openUI', function()
    if not isUIOpen then
        ESX.TriggerServerCallback('illama_garagescreator:getJobsAndGrades', function(jobsWithGrades)
            isUIOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage({
                type = "openUI",
                jobs = jobsWithGrades
            })
        end)
    end
end)

-- Gestion du mode sélection de position
local function enterPositionMode()
    isSelectingPosition = true
    isUIOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        type = "hideUI"
    })
end

local function exitPositionMode(posType, pos)
    isSelectingPosition = false
    isUIOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "showUI",
        positionType = posType,
        position = pos
    })
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('requestPosition', function(data, cb)
    enterPositionMode()
    local message = data.type == 'spawn' 
        and 'Appuyez sur ~g~E~s~ pour définir le point de spawn. Orientez le personnage dans la direction souhaitée.'
        or 'Appuyez sur ~g~E~s~ pour définir la position du garage.'
    ESX.ShowNotification(message)
    
    CreateThread(function()
        while isSelectingPosition do
            Wait(0)
            local playerPed = PlayerPedId()
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            
            -- Affichage uniquement pour le spawn
            if data.type == 'spawn' then
                -- Affichage de la direction pour le spawn
                local forwardX = coords.x + math.sin(-math.rad(heading)) * 5
                local forwardY = coords.y + math.cos(-math.rad(heading)) * 5
                DrawLine(coords.x, coords.y, coords.z, forwardX, forwardY, coords.z, 255, 0, 0, 255)
                
                -- Marqueur rouge pour le spawn uniquement
                DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                    1.0, 1.0, 1.0, 
                    255, 0, 0, 100, 
                    false, true, 2, false, nil, nil, false)
            end
            
            -- Validation avec E
            if IsControlJustPressed(0, 38) then
                local pos = {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = heading
                }
                
                if data.type == 'garage' then
                    selectedGaragePos = pos
                    ESX.ShowNotification('Position du garage définie')
                else
                    selectedSpawnPos = pos
                    selectedHeading = heading
                    ESX.ShowNotification('Point de spawn défini')
                end
                
                exitPositionMode(data.type, pos)
                break
            end

            -- Annulation avec ECHAP
            if IsControlJustPressed(0, 177) then
                isSelectingPosition = false
                ESX.ShowNotification('Sélection de position annulée')
                exitPositionMode(data.type, nil)
                break
            end
        end
    end)
    
    cb('ok')
end)

RegisterNUICallback('saveGarage', function(data, cb)
    if not selectedGaragePos or not selectedSpawnPos then
        ESX.ShowNotification('Vous devez définir les deux positions')
        cb('error')
        return
    end
    
    data.garagePos = selectedGaragePos
    data.spawnPos = {
        x = selectedSpawnPos.x,
        y = selectedSpawnPos.y,
        z = selectedSpawnPos.z,
        heading = selectedHeading
    }
    
    TriggerServerEvent('illama_garagescreator:saveGarage', data)
    ESX.ShowNotification('Garage en cours de sauvegarde...')
    cb('ok')
end)

-- Commande d'ouverture
RegisterCommand(Config.Command, function()
    ESX.TriggerServerCallback('illama_garagescreator:checkAdmin', function(isAdmin)
        if isAdmin then
            TriggerEvent('illama_garagescreator:openUI')
        else
            ESX.ShowNotification('Vous n\'avez pas les permissions nécessaires')
        end
    end)
end)