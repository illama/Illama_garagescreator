Illama Garages Creator est un outil puissant pour gérer les garages dans un serveur FiveM sous ESX. Compatible avec Illama Keys Creator, il offre une intégration parfaite pour gérer les véhicules et distribuer les clés automatiquement lors du spawn.

    Interface Intuitive : Interface utilisateur NUI pour configurer et gérer facilement les garages.
    Gestion des Permissions : Accès limité aux administrateurs pour configurer les garages.
    Positions Configurables :
        Définissez la position du garage et du point de spawn.
        Orientation personnalisée des véhicules lors du spawn.
    Support des Jobs et Grades :
        Intégration des jobs et grades directement depuis la base de données.
        Possibilité de lier des garages à des jobs spécifiques avec des grades définis.
    Compatibilité avec Illama Keys Creator :
        Distribution automatique des clés lors du spawn des véhicules depuis le garage.
    Sauvegarde Sécurisée : Les données des garages sont sauvegardées dans une base de données MySQL.

Installation

    Téléchargez et placez le script dans votre dossier resources.
    Ajoutez la ressource à votre fichier server.cfg :

ensure illama_garagescreator

Créez la table MySQL nécessaire en exécutant la requête suivante :

    CREATE TABLE `illama_garages` (
        `id` INT AUTO_INCREMENT PRIMARY KEY,
        `name` VARCHAR(50) NOT NULL,
        `job` VARCHAR(50) NOT NULL,
        `grades` JSON NOT NULL,
        `vehicles` JSON NOT NULL,
        `garage_pos` JSON NOT NULL,
        `spawn_pos` JSON NOT NULL,
        `vehicle_colors` JSON DEFAULT NULL
    );

    Redémarrez votre serveur FiveM.

Commandes

    Ouvrir l'interface de configuration :

    /garagecreator

    Accessible uniquement pour les administrateurs.

Configuration

    Commandes et paramètres peuvent être ajustés dans config.lua :

    Config = {
        Command = "garagecreator" -- Commande pour ouvrir l'interface
    }

Prérequis

    ESX Legacy (ou compatible).
    MySQL-Async pour la gestion des bases de données.
    Illama Keys Creator pour une gestion fluide des clés.

Crédits

Développé par Illama.
