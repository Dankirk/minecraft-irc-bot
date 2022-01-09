-- MySQL dump 10.13  Distrib 8.0.27, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: mc_autoreply
-- ------------------------------------------------------
-- Server version	8.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `blacklist`
--

DROP TABLE IF EXISTS `blacklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blacklist` (
  `name` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `customrules`
--

DROP TABLE IF EXISTS `customrules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customrules` (
  `Server` int NOT NULL,
  `RegMatch` varchar(256) NOT NULL,
  `Reply` varchar(128) NOT NULL,
  `Enabled` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`Server`,`RegMatch`),
  KEY `Server` (`Server`),
  CONSTRAINT `Server` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `kicks`
--

DROP TABLE IF EXISTS `kicks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kicks` (
  `name` varchar(32) NOT NULL DEFAULT '',
  `Server` int NOT NULL,
  `Count` int DEFAULT '1',
  `Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`name`,`Server`),
  KEY `Kicks.Server` (`Server`),
  CONSTRAINT `Kicks.Server` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `logins`
--

DROP TABLE IF EXISTS `logins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logins` (
  `hash` varchar(32) NOT NULL,
  `Server` int NOT NULL,
  `Created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `master` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`hash`),
  KEY `login.server` (`Server`),
  CONSTRAINT `login.server` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `online`
--

DROP TABLE IF EXISTS `online`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `online` (
  `Server` int NOT NULL,
  `PlayerName` varchar(45) NOT NULL,
  `Ranking` int DEFAULT '0',
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Server`,`PlayerName`),
  KEY `Online.Server` (`Server`),
  CONSTRAINT `Online.Server` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ops`
--

DROP TABLE IF EXISTS `ops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ops` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT '',
  `Demotes` int NOT NULL DEFAULT '0',
  `Kicks` int NOT NULL DEFAULT '0',
  `Bans` int NOT NULL DEFAULT '0',
  `Promotes` int NOT NULL DEFAULT '0',
  `Promobfires` int NOT NULL DEFAULT '0',
  `Server` int NOT NULL,
  `LastAction` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Name` (`name`,`Server`),
  KEY `OpServer` (`Server`),
  CONSTRAINT `OpServer` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4283 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promoted`
--

DROP TABLE IF EXISTS `promoted`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promoted` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(32) DEFAULT '',
  `Promoter` int NOT NULL,
  `Server` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `Name` (`name`,`Server`),
  KEY `PromoServer` (`Server`),
  KEY `Promoter` (`Promoter`),
  CONSTRAINT `PromoServer` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`),
  CONSTRAINT `Promoter` FOREIGN KEY (`Promoter`) REFERENCES `ops` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32148 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rankedvisitors`
--

DROP TABLE IF EXISTS `rankedvisitors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rankedvisitors` (
  `Server` int NOT NULL,
  `Ranking` int NOT NULL,
  `num` int NOT NULL DEFAULT '0',
  `Title` varchar(32) DEFAULT NULL,
  `Color` int NOT NULL DEFAULT '15',
  `Prefix` varchar(2) NOT NULL DEFAULT '',
  `PromoTo` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`Server`,`Color`,`Prefix`),
  KEY `RVServer` (`Server`),
  CONSTRAINT `RVServer` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `rankerrors`
--

DROP TABLE IF EXISTS `rankerrors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rankerrors` (
  `Server` int NOT NULL,
  `Prefix` varchar(2) NOT NULL,
  `Color` varchar(45) NOT NULL,
  `Nickname` varchar(45) NOT NULL,
  PRIMARY KEY (`Server`,`Prefix`,`Color`),
  KEY `RankErrors.Server` (`Server`),
  CONSTRAINT `RankErrors.Server` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servers`
--

DROP TABLE IF EXISTS `servers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `servers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `Name` varchar(45) NOT NULL,
  `Bans` int NOT NULL DEFAULT '0',
  `Kicks` int NOT NULL DEFAULT '0',
  `Promotes` int NOT NULL DEFAULT '0',
  `Demotes` int NOT NULL DEFAULT '0',
  `HackInforms` int NOT NULL DEFAULT '0',
  `Visitors` int NOT NULL DEFAULT '0',
  `Thanks` int NOT NULL DEFAULT '0',
  `Replies` int NOT NULL DEFAULT '0',
  `pass` varchar(32) DEFAULT '',
  `Token` varchar(32) DEFAULT NULL,
  `Pony` tinyint(1) DEFAULT '1',
  `Jokes` tinyint(1) DEFAULT '1',
  `Ranks` tinyint(1) DEFAULT '1',
  `FunFacts` tinyint(1) DEFAULT '1',
  `Botname` varchar(64) DEFAULT NULL,
  `Website` varchar(128) DEFAULT NULL,
  `PromoRank` int NOT NULL DEFAULT '5',
  `SpleefRank` int NOT NULL DEFAULT '2',
  `MuteRank` int NOT NULL DEFAULT '7',
  `masterPass` varchar(32) NOT NULL DEFAULT '',
  `DispName` varchar(32) NOT NULL DEFAULT '',
  `HowToFly` varchar(128) NOT NULL DEFAULT 'For how to fly with WoM, visit: http://is.gd/howtofly',
  `Impersonation` tinyint(1) NOT NULL DEFAULT '1',
  `MultiColorValue` int NOT NULL DEFAULT '5',
  `PublicStats` tinyint(1) NOT NULL DEFAULT '1',
  `Muted` tinyint(1) NOT NULL DEFAULT '0',
  `HideSilent` int DEFAULT '2',
  `IsOnline` enum('ON','OFF') DEFAULT 'OFF',
  `Multilang` tinyint(1) NOT NULL DEFAULT '0',
  `WaterRank` int DEFAULT '1',
  `BotAuth` varchar(32) DEFAULT '',
  `Active` tinyint unsigned NOT NULL DEFAULT '1',
  `disableplayers` tinyint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `Name_UNIQUE` (`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stats`
--

DROP TABLE IF EXISTS `stats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stats` (
  `Date` date NOT NULL,
  `Promotes` int NOT NULL DEFAULT '0',
  `Demotes` int NOT NULL DEFAULT '0',
  `Kicks` int NOT NULL DEFAULT '0',
  `Bans` int NOT NULL DEFAULT '0',
  `Server` int NOT NULL,
  `Visitors` int NOT NULL DEFAULT '0',
  `Replies` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`Date`,`Server`),
  KEY `StatsServer` (`Server`),
  CONSTRAINT `StatsServer` FOREIGN KEY (`Server`) REFERENCES `servers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-01-09 14:35:58
