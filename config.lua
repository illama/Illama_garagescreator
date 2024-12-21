Config = {}

Config.Command = 'creategarage' -- Commande pour créer un garage
Config.DefaultGrades = {0, 1, 2, 3, 4} -- Grades par défaut proposés

-- Marqueur pour le garage
Config.MarkerType = 36 -- Type de marqueur à afficher
Config.MarkerSize = {x = 1.0, y = 1.0, z = 1.0}
Config.MarkerColor = {r = 0, g = 255, b = 0, a = 100}

-- Marqueur pour le rangement
Config.StoreMarkerType = 1
Config.StoreMarkerSize = {x = 10.0, y = 10.0, z = 1.0}
Config.StoreMarkerColor = {r = 255, g = 0, b = 0, a = 100}

-- Distances
Config.DrawDistance = 10.0 -- Distance d'affichage des marqueurs
Config.StoreDistance = 10.0 -- Distance pour ranger un véhicule

-- Messages
Config.Messages = {
    vehicleStored = 'Véhicule rangé avec succès',
    cannotStore = 'Ce véhicule n\'appartient pas à ce garage',
    pressToStore = 'Appuyez sur ~g~E~w~ pour ranger le véhicule'
}

Config.VehicleDetectionRadius = 15.0