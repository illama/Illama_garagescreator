-- server/main.lua
local ESX = exports["es_extended"]:getSharedObject()
RegisterNetEvent('illama_garagescreator:syncPedAction')
AddEventHandler('illama_garagescreator:syncPedAction', function(garageId, vehicleNetId, actionType, actionData)
    -- Broadcast l'action à tous les autres joueurs
    TriggerClientEvent('illama_garagescreator:syncPedActionClient', -1, garageId, vehicleNetId, actionType, actionData)
end)

RegisterNetEvent('illama_garagescreator:syncVehicleDelete')
AddEventHandler('illama_garagescreator:syncVehicleDelete', function(vehicleNetId)
    TriggerClientEvent('illama_garagescreator:syncVehicleDeleteClient', -1, vehicleNetId)
end)
-- Vérification des permissions admin
ESX.RegisterServerCallback('illama_garagescreator:checkAdmin', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.Sync.fetchAll('SELECT `group` FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })
    
    if result[1] and result[1].group == 'admin' then
        cb(true)
    else
        cb(false)
    end
end)

-- Sauvegarde du garage
-- server/main.lua
local savingGarage = false

RegisterNetEvent('illama_garagescreator:saveGarage')
AddEventHandler('illama_garagescreator:saveGarage', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Vérification admin
    if xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    -- Protection contre les doubles sauvegardes
    if savingGarage then
        TriggerClientEvent('esx:showNotification', source, 'Sauvegarde déjà en cours...')
        return
    end
    
    savingGarage = true
    
    -- On s'assure que les données sont valides
    if not data.name or not data.vehicles or not data.garagePos or not data.spawnPos then
        TriggerClientEvent('esx:showNotification', source, 'Données invalides')
        savingGarage = false
        return
    end

    MySQL.Async.execute('INSERT INTO illama_garages (`name`, `job`, `grades`, `vehicles`, `garage_pos`, `spawn_pos`, `vehicle_colors`) VALUES (@name, @job, @grades, @vehicles, @garage_pos, @spawn_pos, @colors)', {
        ['@name'] = data.name,
        ['@job'] = data.job,
        ['@grades'] = json.encode(data.grades),
        ['@vehicles'] = json.encode(data.vehicles),
        ['@garage_pos'] = json.encode(data.garagePos),
        ['@spawn_pos'] = json.encode(data.spawnPos),
        ['@colors'] = json.encode(data.vehicleColors or {})
    }, function(rowsChanged)
        if rowsChanged > 0 then
            TriggerClientEvent('esx:showNotification', source, 'Garage créé avec succès')
        else
            TriggerClientEvent('esx:showNotification', source, 'Erreur lors de la création du garage')
        end
        savingGarage = false
    end)
end)

-- Récupération des jobs et grades
ESX.RegisterServerCallback('illama_garagescreator:getJobsAndGrades', function(source, cb)
    MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs)
        MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(grades)
            -- Réorganiser les grades par job
            local jobsWithGrades = {}
            for _, job in ipairs(jobs) do
                jobsWithGrades[job.name] = {
                    label = job.label,
                    grades = {}
                }
            end
            
            for _, grade in ipairs(grades) do
                if jobsWithGrades[grade.job_name] then
                    table.insert(jobsWithGrades[grade.job_name].grades, {
                        id = grade.grade,
                        name = grade.name,
                        label = grade.label
                    })
                end
            end
            
            cb(jobsWithGrades)
        end)
    end)
end)