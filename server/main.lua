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

-- Configuration
local githubUser = 'illama'
local githubRepo = 'illama_garagescreator'

-- Fonction pour récupérer la version locale depuis le fxmanifest
local function GetCurrentVersion()
    local resourceName = GetCurrentResourceName()
    local manifest = LoadResourceFile(resourceName, 'fxmanifest.lua')
    if not manifest then
        return nil
    end
    
    -- Chercher la ligne avec version
    for line in manifest:gmatch("[^\r\n]+") do
        local version = line:match("^version%s+['\"](.+)['\"]")
        if version then
            return version:gsub("%s+", "") -- Enlever les espaces
        end
    end
    
    return nil
end

-- Fonction pour vérifier la version
local function CheckVersion()
    local currentVersion = GetCurrentVersion()
    if not currentVersion then
        print('^1[illama_garagescreator] Impossible de lire la version dans le fxmanifest.lua^7')
        return
    end

    -- Utiliser l'API GitHub pour récupérer la dernière release
    PerformHttpRequest(
        ('https://api.github.com/repos/%s/%s/releases/latest'):format(githubUser, githubRepo),
        function(err, text, headers)
            if err ~= 200 then
                print('^1[illama_garagescreator] Impossible de vérifier la version sur GitHub^7')
                return
            end
            
            -- Parser la réponse JSON
            local data = json.decode(text)
            if not data or not data.tag_name then
                print('^1[illama_billing] Erreur lors de la lecture de la version GitHub^7')
                return
            end
            
            local latestVersion = data.tag_name:gsub("^v", "") -- Enlever le 'v' si présent
            
            if latestVersion ~= currentVersion then
                print('^3[illama_garagescreator] Une nouvelle version est disponible!^7')
                print('^3[illama_garagescreator] Version actuelle: ^7' .. currentVersion)
                print('^3[illama_garagescreator] Dernière version: ^7' .. latestVersion)
                print('^3[illama_billing] Notes de mise à jour: ^7' .. (data.html_url or 'N/A'))
                if data.body then
                    print('^3[illama_garagescreator] Changements: \n^7' .. data.body)
                end
            else
                print('^2[illama_garagescreator] Le script est à jour (v' .. currentVersion .. ')^7')
            end
        end,
        'GET',
        '',
        {['User-Agent'] = 'FXServer-'..githubUser}
    )
end

-- Vérifier la version au démarrage
CreateThread(function()
    Wait(5000) -- Attendre 5 secondes après le démarrage du serveur
    CheckVersion()
end)
