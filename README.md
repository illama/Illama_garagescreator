Un script facile d'utilisation permettant de créer des garages. Fonctionnant sous ESX 1.11.4 (minimum). 

Prérequis

- ESX Legacy installé et configuré.
- MySQL-Async pour la gestion des bases de données.
- Ox_lib pour les notifications et les interfaces.

Installation

- Téléchargez le script et placez-le dans votre dossier resources.
- Ajoutez la ressource à votre fichier server.cfg :
- ensure illama_billing

Importez le fichier SQL dans votre base de données :

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

Utilisation
Commandes principales :

- Création de garages pour les métiers,
- Possibilité de choisir la plaque des véhicules,
- Possibilité de choisir la couleur (primaire et secondaire) des véhicules,
- Un blip du garage seulement pour les personnes y ayants accès.

Compatiblité

- illama_keyscreator, don des clés à la sortie du véhicule, suppresssion de celle-ci au rangement du véhicule.

Développé par Illama.
