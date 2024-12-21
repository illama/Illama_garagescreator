-- illama_garages.sql
CREATE TABLE IF NOT EXISTS `illama_garages` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `job` varchar(50) DEFAULT NULL,
    `grades` longtext DEFAULT NULL,
    `vehicles` longtext DEFAULT NULL,
    `garage_pos` longtext NOT NULL,
    `spawn_pos` longtext NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;