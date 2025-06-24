CREATE TABLE IF NOT EXISTS `phone_numbers` (
  `identifier` varchar(100) NOT NULL,
  `number` varchar(20) NOT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `iban` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phone_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) DEFAULT NULL,
  `number` varchar(50) DEFAULT NULL,
  `messages` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `number` (`number`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phone_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) DEFAULT NULL,
  `calls` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `phone_notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(100) NOT NULL,
  `app` varchar(50) NOT NULL,
  `title` varchar(50) NOT NULL,
  `content` text DEFAULT NULL,
  `time` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;
