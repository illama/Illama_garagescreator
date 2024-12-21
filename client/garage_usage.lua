local ESX = exports["es_extended"]:getSharedObject()
local garages = {}
local currentGarage = nil
local garageZones = {}
local garagePeds = {}
local busyPeds = {}
local garageBlips = {}
ESX.PlayerData = ESX.GetPlayerData()
local inspectAnimations = {
    notepad = {dict = "amb@world_human_clipboard@male@base", anim = "base"},
    tireCheck = {dict = "amb@prop_human_parking_meter@male@idle_a", anim = "idle_a"}, -- Animation accroupie
    lookAround = {dict = "anim@amb@garage@human_inspect_vehicle@", anim = "inspect_2"},
    checkEngine = {dict = "amb@prop_human_parking_meter@male@base", anim = "base"} -- Animation penchée
}

-- Au début du fichier, ajoutez
local pedAnimations = {
    base = {dict = "anim@amb@casino@valet_scenario@poswe_d@", anim = "base_a_m_y_vinewood_01"},
    toVehicle = {dict = "anim@move_m@confident", anim = "walk"},
    getInVehicle = {dict = "anim@mp_player_intmenu@key_fob@", anim = "fob_click"}
}
-- Fonction pour créer un blip
function CreateGarageBlip(garage)
    local garagePos = json.decode(garage.garage_pos)
    local blip = AddBlipForCoord(garagePos.x, garagePos.y, garagePos.z)
    
    -- Configuration du blip
    SetBlipSprite(blip, 357)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.6)
    SetBlipColour(blip, 40)
    SetBlipAsShortRange(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(garage.name)
    EndTextCommandSetBlipName(blip)
    
    return blip
end

function UpdateGarageBlips()
    -- Clear existing blips
    for _, blip in pairs(garageBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    garageBlips = {}
    
    -- Get player job with nil check
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.job then
        return
    end
    local playerJob = playerData.job
    
    -- Create new blips for accessible garages
    for _, garage in pairs(garages) do
        -- Check if garage is accessible based on job
        if garage.job == 'all' or garage.job == '' or garage.job == playerJob.name then
            -- Grade verification
            local canAccess = true
            if garage.grades and garage.grades ~= '' then
                local success, grades = pcall(json.decode, garage.grades)
                if success and grades then
                    local minGradeRequired = 999
                    for _, grade in ipairs(grades) do
                        local gradeNum = tonumber(grade)
                        if gradeNum and gradeNum < minGradeRequired then
                            minGradeRequired = gradeNum
                        end
                    end
                    canAccess = playerJob.grade >= minGradeRequired
                else
                end
            end
            
            -- Create blip if access is granted
            if canAccess then
                local blip = CreateGarageBlip(garage)
                if blip then
                    table.insert(garageBlips, blip)
                end
            end
        end
    end
end
-- Fonction pour jouer une animation
local function PlayPedAnimation(ped, dict, anim, flag)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(0) end
    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag, 0, false, false, false)
    RemoveAnimDict(dict)
end
-- Fonction pour faire regarder le ped vers une position
function TaskPedLookAtCoord(ped, coords)
    if busyPeds[ped] then return end -- Ne pas tourner si occupé
    
    local pedCoords = GetEntityCoords(ped)
    local dx = coords.x - pedCoords.x
    local dy = coords.y - pedCoords.y
    
    -- Calculer l'angle
    local heading = (math.atan2(dy, dx) * 180 / math.pi) - 90
    
    -- Appliquer la rotation en douceur
    local currentHeading = GetEntityHeading(ped)
    local newHeading = heading
    
    if math.abs(newHeading - currentHeading) > 180 then
        if newHeading > currentHeading then
            newHeading = newHeading - 360
        else
            newHeading = newHeading + 360
        end
    end
    
    local factor = 0.1
    local interpolatedHeading = currentHeading + (newHeading - currentHeading) * factor
    SetEntityHeading(ped, interpolatedHeading % 360)
end
-- Thread pour la mise à jour des peds (celui qui fait tourner les peds)
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, pedData in pairs(garagePeds) do
            if DoesEntityExist(pedData.ped) and not busyPeds[pedData.ped] then -- Vérifier si le ped n'est pas occupé
                local pedCoords = GetEntityCoords(pedData.ped)
                local distance = #(playerCoords - pedCoords)
                
                if distance <= 10.0 then
                    wait = 0
                    local closestDistance = distance
                    local closestCoords = playerCoords
                    
                    -- Vérifier s'il y a d'autres joueurs plus proches
                    for _, playerId in ipairs(GetActivePlayers()) do
                        local targetPed = GetPlayerPed(playerId)
                        if targetPed ~= playerPed then
                            local targetCoords = GetEntityCoords(targetPed)
                            local targetDistance = #(pedCoords - targetCoords)
                            
                            if targetDistance < closestDistance then
                                closestDistance = targetDistance
                                closestCoords = targetCoords
                            end
                        end
                    end
                    
                    -- Faire regarder le ped vers le joueur le plus proche
                    TaskPedLookAtCoord(pedData.ped, closestCoords)
                    
                    -- Vérifier et relancer l'animation de base si nécessaire
                    if not IsEntityPlayingAnim(pedData.ped, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 3) then
                        PlayPedAnimation(pedData.ped, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 1)
                    end
                end
            end
        end
        
        Wait(wait)
    end
end)
-- Ajoutez ces nouvelles fonctions
function CreateGaragePed(coords)
    -- Charger le modèle du ped
    local pedModel = `s_m_m_security_01`
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(50)
    end
    
    -- Créer le ped
    local ped = CreatePed(4, pedModel, coords.x, coords.y, coords.z - 1.0, 0.0, false, true)
    
    -- Configuration avancée du ped
    SetEntityInvincible(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedCanBeKnockedOffVehicle(ped, 1)
    SetPedCanBeDraggedOut(ped, false)
    SetPedCanBeTargettedByTeam(ped, false)
    SetPedCanBeTargettedByPlayer(ped, false)
    SetEntityCanBeDamaged(ped, false)
    SetPedRagdollOnCollision(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetPedCanBeShotInVehicle(ped, false)
    SetPedConfigFlag(ped, 32, false) -- CPED_CONFIG_FLAG_CanBeKnockedOffBike
    SetPedConfigFlag(ped, 281, true) -- CPED_CONFIG_FLAG_DisableHurt
    SetPedConfigFlag(ped, 208, true) -- CPED_CONFIG_FLAG_DisablePlayerLockon
    SetPedConfigFlag(ped, 128, true) -- CPED_CONFIG_FLAG_RagdollOnCollision
    SetPedSuffersCriticalHits(ped, false)
    SetPedDiesWhenInjured(ped, false)
    DisablePedPainAudio(ped, true)
    SetPedCanPlayAmbientAnims(ped, false)
    SetPedCanPlayAmbientBaseAnims(ped, false)
    SetPedRelationshipGroupHash(ped, GetHashKey("CIVMALE"))
    SetBlockingOfNonTemporaryEvents(ped, true)
    
    -- Animation de base
    PlayPedAnimation(ped, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 1)
    FreezeEntityPosition(ped, true)
    
    SetModelAsNoLongerNeeded(pedModel)
    
    return ped
end

-- Events pour le chargement des garages
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    TriggerServerEvent('illama_garagescreator:requestGarages')
    UpdateGarageBlips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
    TriggerServerEvent('illama_garagescreator:requestGarages')
    UpdateGarageBlips()
end)

RegisterNetEvent('illama_garagescreator:receiveGarages')
AddEventHandler('illama_garagescreator:receiveGarages', function(serverGarages)
    garages = serverGarages
    LoadGarages()
end)
RegisterNetEvent('illama_garagescreator:syncPedActionClient')
AddEventHandler('illama_garagescreator:syncPedActionClient', function(garageId, vehicleNetId, actionType, actionData)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    local pedData = garagePeds[garageId]
    
    if not pedData or not DoesEntityExist(pedData.ped) then return end
    local ped = pedData.ped

    if actionType == "move" then
        TaskGoToCoordAnyMeans(ped, actionData.x, actionData.y, actionData.z, 1.0, 0, 0, 786603, 0xbf800000)
    elseif actionType == "animation" then
        PlayPedAnimation(ped, actionData.dict, actionData.anim, actionData.flag or 1)
    elseif actionType == "heading" then
        SetEntityHeading(ped, actionData.heading)
    elseif actionType == "enterVehicle" then
        TaskEnterVehicle(ped, vehicle, -1, -1, 1.0, 1, 0)
    elseif actionType == "driveAway" then
        TaskVehicleDriveToCoord(ped, vehicle, actionData.x, actionData.y, actionData.z, 20.0, 0, GetEntityModel(vehicle), 786603, 1.0, true)
    end
end)
RegisterNetEvent('illama_garagescreator:syncVehicleDeleteClient')
AddEventHandler('illama_garagescreator:syncVehicleDeleteClient', function(vehicleNetId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        -- Effet de disparition
        local alpha = 255
        CreateThread(function()
            while alpha > 0 do
                alpha = alpha - 5
                SetEntityAlpha(vehicle, alpha, false)
                Wait(50)
            end
            DeleteEntity(vehicle)
        end)
    end
end)
-- Modifiez la fonction LoadGarages comme ceci
function LoadGarages()
    -- Supprimer les anciens peds
    for _, pedData in pairs(garagePeds) do
        if DoesEntityExist(pedData.ped) then
            DeleteEntity(pedData.ped)
        end
    end
    garagePeds = {}
    
    -- Supprime les anciennes zones
    for _, zone in pairs(garageZones) do
        exports.ox_target:removeZone(zone)
    end
    garageZones = {}

    -- Initialise les nouvelles zones et peds
    for id, garage in pairs(garages) do
        local garagePos = json.decode(garage.garage_pos)
        
        -- Créer le ped
        local ped = CreateGaragePed(vec3(garagePos.x, garagePos.y, garagePos.z))
        garagePeds[garage.id] = {
            ped = ped,
            position = vec3(garagePos.x, garagePos.y, garagePos.z),
            heading = 0.0
        }
        
        -- Options du ox_target pour le PNJ
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'open_garage_' .. garage.id,
                label = 'Ouvrir le garage - ' .. garage.name,
                icon = 'fa-solid fa-warehouse',
                distance = 2.5,
                canInteract = function()
                    return CanAccessGarage(garage)
                end,
                onSelect = function()
                    OpenGarageMenu(garage)
                end
            },
            {
                name = 'store_vehicle_' .. garage.id,
                label = 'Ranger un véhicule',
                icon = 'fa-solid fa-car',
                distance = 2.5,
                canInteract = function()
                    return CanAccessGarage(garage) and IsAnyGarageVehicleNearby(garage)
                end,
                onSelect = function()
                    OpenStoreVehicleMenu(garage, ped)
                end
            }
        })
    end
    UpdateGarageBlips()
end
function IsAnyGarageVehicleNearby(garage)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = json.decode(garage.vehicles)
    local radius = Config.VehicleDetectionRadius
    
    local nearbyVehicles = GetGamePool('CVehicle')
    
    for _, vehicle in pairs(nearbyVehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(playerCoords - vehicleCoords) <= radius then
            local model = GetEntityModel(vehicle)
            for _, garageVehicle in ipairs(vehicles) do
                if model == GetHashKey(garageVehicle.model) then
                    return true
                end
            end
        end
    end
    
    return false
end
function GetNearbyGarageVehicles(garage)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = json.decode(garage.vehicles)
    local radius = Config.VehicleDetectionRadius
    local nearbyGarageVehicles = {}
    
    local nearbyVehicles = GetGamePool('CVehicle')
    
    for _, vehicle in pairs(nearbyVehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(playerCoords - vehicleCoords) <= radius then
            local model = GetEntityModel(vehicle)
            for _, garageVehicle in ipairs(vehicles) do
                if model == GetHashKey(garageVehicle.model) then
                    table.insert(nearbyGarageVehicles, {
                        vehicle = vehicle,
                        data = garageVehicle
                    })
                    break
                end
            end
        end
    end
    
    return nearbyGarageVehicles
end

-- Nouvelle fonction pour ouvrir le menu de rangement
function OpenStoreVehicleMenu(garage, ped)
    local nearbyVehicles = GetNearbyGarageVehicles(garage)
    local elements = {}
    
    if #nearbyVehicles == 0 then
        ESX.ShowNotification('Aucun véhicule du garage à proximité')
        return
    end
    
    for _, vehData in ipairs(nearbyVehicles) do
        local vehicle = vehData.vehicle
        local vehName = vehData.data.label
        local plate = GetVehicleNumberPlateText(vehicle)
        
        table.insert(elements, {
            title = vehName,
            description = 'Plaque: ' .. plate,
            icon = 'car',
            onSelect = function()
                StoreVehicle(garage, ped, vehicle, vehData.data)
            end
        })
    end
    
    lib.registerContext({
        id = 'store_vehicle_menu',
        title = 'Ranger un véhicule',
        options = elements
    })
    
    lib.showContext('store_vehicle_menu')
end
function StoreVehicle(garage, ped, vehicle, vehicleData)
    if not DoesEntityExist(vehicle) then 
        ESX.ShowNotification('Véhicule introuvable')
        return
    end

    -- Récupérer la plaque au début de la fonction
    local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))

    -- Récupérer le NetworkId du véhicule pour la synchronisation
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    SetNetworkIdCanMigrate(vehicleNetId, false)
    
    -- Vérifie si c'est un hélicoptère ou un bateau
    local vehicleClass = GetVehicleClass(vehicle)
    local isSpecialVehicle = vehicleClass == 14 or vehicleClass == 15 -- 14 = Bateaux, 15 = Hélicoptères
    
    if isSpecialVehicle then
        -- Pour les bateaux et hélicoptères, on range directement
        -- Effets lumineux et suppression des clés
        SetVehicleLights(vehicle, 2)
        StartVehicleHorn(vehicle, 50, "HELDDOWN", false)
        Wait(100)
        SetVehicleLights(vehicle, 0)
        Wait(150)
        SetVehicleLights(vehicle, 2)
        Wait(100)
        SetVehicleLights(vehicle, 0)
        
        -- Supprimer les clés en incluant le job
        TriggerServerEvent('illama_keyscreator:removeJobKeys', plate, ESX.PlayerData.job.name)
        
        -- Synchroniser la suppression du véhicule avec effet de fondu
        TriggerServerEvent('illama_garagescreator:syncVehicleDelete', vehicleNetId)
        
        ESX.ShowNotification('Véhicule rangé avec succès')
        return
    end
    
    -- Pour les véhicules normaux, continuer avec le processus standard
    busyPeds[ped] = true
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    
    -- Position près du véhicule
    local vehiclePos = GetEntityCoords(vehicle)
    local offsetCoords = GetOffsetFromEntityInWorldCoords(vehicle, -2.0, 0.0, 0.0)
    
    -- Synchroniser le déplacement vers le véhicule
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "move", {
        x = offsetCoords.x,
        y = offsetCoords.y,
        z = offsetCoords.z
    })
    
    -- Attendre que le ped arrive
    while #(GetEntityCoords(ped) - offsetCoords) > 1.0 do
        Wait(100)
    end
    
    -- Synchroniser la rotation
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "heading", {
        heading = GetEntityHeading(vehicle) + 180.0
    })
    
    -- Animation bloc-notes
    local clipboard = CreateObject(GetHashKey("p_amb_clipboard_01"), 0, 0, 0, true, true, true)
    local pen = CreateObject(GetHashKey("prop_pencil_01"), 0, 0, 0, true, true, true)
    AttachEntityToEntity(clipboard, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.1, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
    AttachEntityToEntity(pen, ped, GetPedBoneIndex(ped, 58866), 0.12, 0.05, -0.03, -20.0, 0.0, 0.0, true, true, false, true, 1, true)
    
    -- Synchroniser l'animation du bloc-notes
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "animation", {
        dict = "amb@world_human_clipboard@male@base",
        anim = "base"
    })
    Wait(5000)
    
    DeleteEntity(clipboard)
    DeleteEntity(pen)
    ClearPedTasks(ped)
    
    -- Synchroniser l'animation des clés
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "animation", {
        dict = "anim@mp_player_intmenu@key_fob@",
        anim = "fob_click",
        flag = 48
    })
    
    -- Déverrouiller complètement le véhicule et jouer les effets
    SetVehicleDoorsLocked(vehicle, 1) -- Déverrouillage général
    SetVehicleDoorsLockedForAllPlayers(vehicle, false) -- S'assurer que c'est déverrouillé pour tous
    SetVehicleDoorsLockedForPlayer(vehicle, PlayerId(), false) -- Déverrouillé pour le joueur
    SetVehicleDoorsLockedForTeam(vehicle, false) -- Déverrouillé pour l'équipe
    
    -- Effets visuels
    SetVehicleLights(vehicle, 2)
    StartVehicleHorn(vehicle, 50, "HELDDOWN", false)
    Wait(100)
    SetVehicleLights(vehicle, 0)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    Wait(100)
    SetVehicleLights(vehicle, 0)
    
    -- Ouvrir uniquement la porte conducteur
    SetVehicleDoorOpen(vehicle, 0, false, false) -- 0 est l'index de la porte conducteur
    
    Wait(500) -- Petit délai pour que la porte soit bien ouverte
    
    -- S'assurer que le véhicule est complètement accessible pour le PED
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleAlarm(vehicle, false)
    
    -- Synchroniser l'entrée dans le véhicule
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "enterVehicle", {})
    
    -- Attendre que le ped soit dans le véhicule
    local timeout = 0
    while not IsPedInVehicle(ped, vehicle, false) and timeout < 100 do
        timeout = timeout + 1
        Wait(100)
    end
    
    Wait(500)
    
    -- Direction aléatoire pour partir
    local angle = math.random() * 360
    local distance = 100.0
    local targetX = vehiclePos.x + math.cos(math.rad(angle)) * distance
    local targetY = vehiclePos.y + math.sin(math.rad(angle)) * distance
    local targetZ = vehiclePos.z
    
    -- Supprimer les clés avant que le véhicule ne parte
    TriggerServerEvent('illama_keyscreator:removeJobKeys', plate, ESX.PlayerData.job.name)
    
    -- Synchroniser le départ
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "driveAway", {
        x = targetX,
        y = targetY,
        z = targetZ
    })
    
    -- Attendre que le véhicule s'éloigne
    local distanceCheck = 0
    while distanceCheck < 60 do
        if DoesEntityExist(vehicle) then
            local currentCoords = GetEntityCoords(vehicle)
            if #(currentCoords - vehiclePos) > 60.0 then
                break
            end
        else
            break
        end
        distanceCheck = distanceCheck + 1
        Wait(500)
    end
    
    -- Synchroniser la suppression du véhicule
    TriggerServerEvent('illama_garagescreator:syncVehicleDelete', vehicleNetId)
    
    -- Remettre le ped à sa position
    local returnPos = garagePeds[garage.id].position
    SetEntityCoords(ped, returnPos.x, returnPos.y, returnPos.z - 1.0)
    SetEntityHeading(ped, garagePeds[garage.id].heading)
    FreezeEntityPosition(ped, true)
    
    -- Synchroniser l'animation de base
    TriggerServerEvent('illama_garagescreator:syncPedAction', garage.id, vehicleNetId, "animation", {
        dict = "anim@amb@casino@valet_scenario@pose_d@",
        anim = "base_a_m_y_vinewood_01"
    })
    
    busyPeds[ped] = nil
    
    ESX.ShowNotification('Véhicule rangé avec succès')
end
-- Vérification des permissions
function CanAccessGarage(garage)
    while ESX == nil do Wait(0) end
    
    local playerData = ESX.GetPlayerData()

    -- Vérifie que le garage a un job assigné
    if not garage.job or garage.job == '' then
        return true -- Si pas de job assigné, accès pour tout le monde
    end

    -- Vérifie que les données du job sont chargées
    if not playerData or not playerData.job then
        return false
    end

    -- Vérifie le job
    if garage.job ~= 'all' and playerData.job.name ~= garage.job then 
        return false 
    end
    
    -- Si pas de grades spécifiés ou grades vide, autoriser tout grade du job
    if not garage.grades or garage.grades == '' then
        return true
    end

    -- Parse les grades
    local grades = json.decode(garage.grades)
    if not grades or type(grades) ~= 'table' then
        return true -- En cas d'erreur de parsing, autoriser l'accès
    end
    
    -- Trouve le grade minimum requis
    local minGradeRequired = 999
    for _, grade in ipairs(grades) do
        local gradeNum = tonumber(grade)
        if gradeNum and gradeNum < minGradeRequired then
            minGradeRequired = gradeNum
        end
    end
    
    -- Autorise l'accès si le grade du joueur est supérieur ou égal au grade minimum requis
    local playerGrade = tonumber(playerData.job.grade)
    return playerGrade >= minGradeRequired
end

-- Menu du garage
function OpenGarageMenu(garage)
    currentGarage = garage
    local elements = {}
    local vehicleList = json.decode(garage.vehicles)
    
    for _, vehicle in ipairs(vehicleList) do
        table.insert(elements, {
            title = vehicle.label,
            description = 'Sortir ce véhicule',
            icon = 'car',
            onSelect = function()
                SpawnVehicle(vehicle.model, garage, vehicle)
            end
        })
    end
    
    lib.registerContext({
        id = 'garage_menu',
        title = garage.name,
        options = elements
    })
    
    lib.showContext('garage_menu')
end

-- Spawn d'un véhicule
function SpawnVehicle(model, garage, vehicleData)
    local spawnPos = json.decode(garage.spawn_pos)
    local spawnCoords = vec3(spawnPos.x, spawnPos.y, spawnPos.z)
    
    -- Nettoie la zone avant de spawn
    ClearSpawnArea(spawnCoords)
    
    -- Vérification si la zone de spawn est libre
    if not IsSpawnPointClear(spawnPos) then
        ESX.ShowNotification('La zone de spawn est occupée')
        return
    end
    
    ESX.Game.SpawnVehicle(model, spawnCoords, spawnPos.heading, function(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        
        -- Appliquer la plaque si elle existe
        if vehicleData.plate and vehicleData.plate ~= '' then
            SetVehicleNumberPlateText(vehicle, vehicleData.plate)
        end
        
        -- Appliquer les couleurs si disponibles
        if vehicleData and vehicleData.colors then
            -- Convertir les couleurs hex en RGB
            local function HexToRGB(hex)
                hex = hex:gsub("#","")
                return tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
            end
            
            if vehicleData.colors.primary then
                local r, g, b = HexToRGB(vehicleData.colors.primary)
                SetVehicleCustomPrimaryColour(vehicle, r, g, b)
            end
            
            if vehicleData.colors.secondary then
                local r, g, b = HexToRGB(vehicleData.colors.secondary)
                SetVehicleCustomSecondaryColour(vehicle, r, g, b)
            end
        end
        
        -- Options du véhicule
        SetVehicleDirtLevel(vehicle, 0.0)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDoorsLocked(vehicle, 1)

        local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
        -- Donner les clés avec le nom du job
        TriggerServerEvent('illama_keyscreator:giveJobKeys', plate, ESX.PlayerData.job.name, vehicleData.label or model)
        
        -- Téléporte le joueur dans le véhicule
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        
        ESX.ShowNotification('Véhicule sorti avec succès')
    end)
end

-- Fonction pour nettoyer la zone de spawn
function ClearSpawnArea(coords)
    -- Définir le rayon de nettoyage
    local radius = 5.0
    
    -- Récupère toutes les entités dans la zone
    local entities = GetGamePool('CVehicle')
    
    for k, entity in pairs(entities) do
        -- Récupère les coordonnées de l'entité
        local entityCoords = GetEntityCoords(entity)
        
        -- Vérifie si l'entité est dans le rayon
        if #(coords - entityCoords) <= radius then
            -- Vérifie si quelqu'un est dans le véhicule
            local isOccupied = false
            for i = -1, GetVehicleMaxNumberOfPassengers(entity) - 1 do
                if not IsVehicleSeatFree(entity, i) then
                    isOccupied = true
                    break
                end
            end
            
            -- Si le véhicule n'est pas occupé, le supprimer
            if not isOccupied then
                -- S'assurer que l'entité existe et peut être supprimée
                if DoesEntityExist(entity) then
                    -- Marquer l'entité comme non nécessaire
                    SetEntityAsMissionEntity(entity, true, true)
                    -- Supprimer l'entité
                    DeleteEntity(entity)
                end
            end
        end
    end
    
    -- Attendre un court instant pour s'assurer que tout est nettoyé
    Wait(100)
end

-- Vérification si la zone de spawn est libre
function IsSpawnPointClear(pos)
    local coords = vec3(pos.x, pos.y, pos.z)
    return not IsAnyVehicleNearPoint(coords, 3.0)
end

-- Fonction pour obtenir la position de la porte conducteur
function GetEntryPositionOfDoor(vehicle, doorId)
    if DoesEntityExist(vehicle) then
        local doorPos = GetEntryPositionOfDoor(vehicle, doorId)
        if doorPos then
            return doorPos
        else
            local vehCoords = GetEntityCoords(vehicle)
            local vehHeading = GetEntityHeading(vehicle)
            -- Calculer un offset approximatif pour la porte conducteur
            local offset = 2.0
            local x = vehCoords.x - math.sin(math.rad(vehHeading)) * offset
            local y = vehCoords.y - math.cos(math.rad(vehHeading)) * offset
            return vec3(x, y, vehCoords.z)
        end
    end
    return nil
end
-- Thread pour les marqueurs des garages
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, garage in pairs(garages) do
            if CanAccessGarage(garage) then
                local garagePos = json.decode(garage.garage_pos)
                local distance = #(playerCoords - vec3(garagePos.x, garagePos.y, garagePos.z))
                
                if distance < Config.DrawDistance and not IsPedInAnyVehicle(playerPed, false) then
                    wait = 0
                end
            end
        end
        
        Wait(wait)
    end
end)

-- Initialisation au démarrage
CreateThread(function()
    while ESX == nil do
        Wait(0)
    end
    
    -- Premier chargement des garages
    TriggerServerEvent('illama_garagescreator:requestGarages')
end)

-- Ajoutez ce nouveau thread pour la rotation des peds
CreateThread(function()
    while true do
        local wait = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for _, pedData in pairs(garagePeds) do
            if DoesEntityExist(pedData.ped) and not busyPeds[pedData.ped] then
                -- Réappliquer régulièrement les paramètres de sécurité
                SetEntityInvincible(pedData.ped, true)
                SetPedCanBeTargetted(pedData.ped, false)
                SetPedCanRagdoll(pedData.ped, false)
                SetPedConfigFlag(pedData.ped, 128, true)
                SetBlockingOfNonTemporaryEvents(pedData.ped, true)
                local pedCoords = GetEntityCoords(ped)
                local distance = #(playerCoords - pedCoords)
                
                if distance <= 10.0 then
                    wait = 0
                    
                    -- Calculer l'angle pour regarder le joueur
                    local dx = playerCoords.x - pedCoords.x
                    local dy = playerCoords.y - pedCoords.y
                    local heading = (math.atan2(dy, dx) * 180 / math.pi) - 90
                    
                    -- Rotation douce
                    local currentHeading = GetEntityHeading(ped)
                    local newHeading = heading
                    
                    if math.abs(newHeading - currentHeading) > 180 then
                        if newHeading > currentHeading then
                            newHeading = newHeading - 360
                        else
                            newHeading = newHeading + 360
                        end
                    end
                    
                    local factor = 0.1
                    local interpolatedHeading = currentHeading + (newHeading - currentHeading) * factor
                    SetEntityHeading(ped, interpolatedHeading % 360)
                    
                    -- Vérifier et relancer l'animation si nécessaire
                    if not IsEntityPlayingAnim(ped, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 3) then
                        TaskPlayAnim(ped, "anim@amb@casino@valet_scenario@pose_d@", "base_a_m_y_vinewood_01", 8.0, -8.0, -1, 1, 0, false, false, false)
                    end
                end
            end
        end
        
        Wait(wait)
    end
end)