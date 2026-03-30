SET NAMES latin1;
-- SET FOREIGN_KEY_CHECKS = 0;

BEGIN;
-- necessario altrimenti non posso modificare le tabelle in fase di implementazione a causa delle foreign keys
DROP DATABASE IF EXISTS `SmartHome`;  
CREATE DATABASE `SmartHome`;
COMMIT;

USE `SmartHome`;


/*
-- -----------------------------
--    Table structure for ``
-- -----------------------------
DROP TABLE IF EXISTS ``;
CREATE TABLE `` (
	PRIMARY KEY ()
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
*/

-- -----------------------------
--    Table structure for `Tipo`
-- -----------------------------
DROP TABLE IF EXISTS `Tipo`;
CREATE TABLE `Tipo` (
	`Tipologia` VARCHAR(25) NOT NULL
		CHECK (`Tipologia` IN ('Porta','PortaFinestra','Finestra')), 
    `Accesso` BOOLEAN NOT NULL,
	PRIMARY KEY (`Tipologia`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Apertura`
-- -----------------------------
DROP TABLE IF EXISTS `Apertura`;
CREATE TABLE `Apertura` (
	`Codice` INTEGER NOT NULL,
	`Tipologia` VARCHAR(25) NOT NULL
		CHECK (`Tipologia` IN ('Porta','PortaFinestra','Finestra')),
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Tipologia`)
		REFERENCES `Tipo`(`Tipologia`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- -----------------------------
--    Table structure for `Stanza`
-- -----------------------------
DROP TABLE IF EXISTS `Stanza`;
CREATE TABLE `Stanza` (
	`Codice` INTEGER NOT NULL,
    `Nome` VARCHAR(30) NOT NULL,
    `Piano` INTEGER NOT NULL,
    `Altezza` DOUBLE NOT NULL,
    `Larghezza` DOUBLE NOT NULL,
    `Lunghezza` DOUBLE NOT NULL,
	PRIMARY KEY (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Accesso`
-- -----------------------------
DROP TABLE IF EXISTS `Accesso`;
CREATE TABLE `Accesso` (
	`CodiceApertura` INTEGER NOT NULL,
    `CodiceStanza` INTEGER NOT NULL,
    `Orientamento` VARCHAR(2) NOT NULL
		CHECK (`Orientamento` IN ('N','S','E','W','NE','NW','SE','SW')),
	PRIMARY KEY (`CodiceApertura`,`CodiceStanza`),
    FOREIGN KEY (`CodiceApertura`)
		REFERENCES `Apertura`(`Codice`),
	FOREIGN KEY (`CodiceStanza`)
		REFERENCES `Stanza`(`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Utente`
-- -----------------------------
DROP TABLE IF EXISTS `Utente`;
CREATE TABLE `Utente` (
	`CodiceFiscale` VARCHAR(16) NOT NULL,
    `Nome` VARCHAR(20) NOT NULL,
    `Cognome` VARCHAR(20) NOT NULL,
    `Telefono` VARCHAR(13) NOT NULL,   			
    `DataNascita` DATE NOT NULL,
	PRIMARY KEY (`CodiceFiscale`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Contratto`
-- -----------------------------
DROP TABLE IF EXISTS `Contratto`;
CREATE TABLE `Contratto` (
	`LivelloDispersione` DOUBLE NOT NULL,
    `Intestatario` VARCHAR(16) NOT NULL,
	PRIMARY KEY (`LivelloDispersione`),
    FOREIGN KEY (`Intestatario`)
		REFERENCES `Utente`(`CodiceFiscale`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Account`
-- -----------------------------
DROP TABLE IF EXISTS `Account`;
CREATE TABLE `Account` (
	`NomeAccount` VARCHAR(30) NOT NULL,
    `Password` VARCHAR(32) NOT NULL,
    `DomandaSicurezza` VARCHAR(100) NOT NULL,
    `RispostaSicurezza` VARCHAR(100) NOT NULL,
	PRIMARY KEY (`NomeAccount`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Iscrizione`
-- -----------------------------
DROP TABLE IF EXISTS `Iscrizione`;
CREATE TABLE `Iscrizione` (
	`NomeAccount` VARCHAR(30) NOT NULL,
    `CodiceFiscale` VARCHAR(16) NOT NULL,
    `DataIscrizione` DATE NOT NULL,
    PRIMARY KEY (`NomeAccount`, `CodiceFiscale`),
    FOREIGN KEY (`NomeAccount`)
		REFERENCES `Account`(`NomeAccount`),
	FOREIGN KEY (`CodiceFiscale`)
		REFERENCES `Utente`(`CodiceFiscale`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Documento`
-- -----------------------------
DROP TABLE IF EXISTS `Documento`;
CREATE TABLE `Documento` (
	`Numero` VARCHAR(10) NOT NULL,
    `Tipologia` VARCHAR(13) NOT NULL
		CHECK (`Tipologia` in ('Patente','CartaIdentita')),
    `EnteRilascio` VARCHAR(50) NOT NULL,
    `Scadenza` DATE NOT NULL,
	PRIMARY KEY (`Numero`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Verifica`
-- -----------------------------
DROP TABLE IF EXISTS `Verifica`;
CREATE TABLE `Verifica` (
	`NumeroDocumento`VARCHAR(10) NOT NULL,
    `Utente` VARCHAR(16) NOT NULL,
	PRIMARY KEY (`NumeroDocumento`,`Utente`),
    FOREIGN KEY (`NumeroDocumento`)
		REFERENCES `Documento`(`Numero`),
	FOREIGN KEY (`Utente`)
		REFERENCES `Utente`(`CodiceFiscale`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Bilancio`
-- -----------------------------
DROP TABLE IF EXISTS `Bilancio`;
CREATE TABLE `Bilancio` (
	`FasciaOraria` INTEGER NOT NULL,
    `OraInizio` INTEGER NOT NULL
		CHECK(`OraInizio` >= 0 AND `OraInizio` <= 24),
    `OraFine` INTEGER NOT NULL
		CHECK(`OraFine` >= 0 AND `OraFine` <= 24),
	PRIMARY KEY (`FasciaOraria`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Produzione`
-- -----------------------------
DROP TABLE IF EXISTS `Produzione`;
CREATE TABLE `Produzione` (
	`Orario` TIMESTAMP NOT NULL,
    `kW` DOUBLE NOT NULL DEFAULT 0,
    `FasciaOraria` INTEGER NOT NULL,
	PRIMARY KEY (`Orario`),
    FOREIGN KEY (`FasciaOraria`)
		REFERENCES `Bilancio`(`FasciaOraria`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `SmartPlug`
-- -----------------------------
DROP TABLE IF EXISTS `SmartPlug`;
CREATE TABLE `SmartPlug` (
	`Codice` INTEGER NOT NULL,
    `Attiva` BOOLEAN NOT NULL,
    `CodiceStanza` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`CodiceStanza`)
		REFERENCES `Stanza`(`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


/*
aggiunta attributo 'tipologia' (int <= 3 && >= 0)
0: luce
1: condizionatore
2: con programma
3: altro
*/
-- -----------------------------
--    Table structure for `Dispositivo`
-- -----------------------------
DROP TABLE IF EXISTS `Dispositivo`;
CREATE TABLE `Dispositivo` (
	`Codice` INTEGER NOT NULL,
    `Nome` VARCHAR(25) NOT NULL,
    `UltimoUtilizzatore` VARCHAR(30),
    `CodicePresa` INTEGER NOT NULL,
	`Tipologia` INTEGER NOT NULL
		CHECK(`Tipologia` >= 0 AND `Tipologia` <= 3),
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`UltimoUtilizzatore`)
		REFERENCES `Account` (`NomeAccount`),
	FOREIGN KEY (`CodicePresa`)
		REFERENCES `SmartPlug` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- -----------------------------
--    Table structure for `Specifiche`
-- -----------------------------
DROP TABLE IF EXISTS `Specifiche`;
CREATE TABLE `Specifiche` (
	`Nome` varchar(15) NOT NULL,
    `Valore` double,
	PRIMARY KEY (`Nome`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- -----------------------------
--    Table structure for `Possiede`
-- -----------------------------
DROP TABLE IF EXISTS `Possiede`;
CREATE TABLE `Possiede` (
	`Dispositivo` INTEGER NOT NULL,
    `Specifica` VARCHAR(15) NOT NULL,
	PRIMARY KEY (`Dispositivo`, `Specifica`),
    FOREIGN KEY (`Dispositivo`)
		REFERENCES `Dispositivo` (`Codice`),
	FOREIGN KEY (`Specifica`)
		REFERENCES `Specifiche` (`Nome`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- -----------------------------
--    Table structure for `Impostazioni`
-- -----------------------------
DROP TABLE IF EXISTS `Impostazioni`;
CREATE TABLE `Impostazioni` (
	`Codice` INTEGER NOT NULL,
	`Consumo` DOUBLE											-- per i condizionatori va calcolato in base a fattori che non dipendono esclusivamente dall'impostazione scelta
		CHECK (`Consumo` > 0),
	PRIMARY KEY (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `ImpostazioniIlluminazione`
-- -----------------------------
DROP TABLE IF EXISTS `ImpostazioniIlluminazione`;
CREATE TABLE `ImpostazioniIlluminazione` (
	`Codice` INTEGER NOT NULL,
    `Intensita` INTEGER NOT NULL,
    `TemperaturaColore` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Codice`)
		REFERENCES `Impostazioni` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `ImpostazioniCondizionamento`
-- -----------------------------
DROP TABLE IF EXISTS `ImpostazioniCondizionamento`;
CREATE TABLE `ImpostazioniCondizionamento` (
	`Codice` INTEGER NOT NULL,
    `Temperatura` INTEGER NOT NULL,
    `Umidita` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Codice`)
		REFERENCES `Impostazioni` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Programma`
-- -----------------------------
DROP TABLE IF EXISTS `Programma`;
CREATE TABLE `Programma` (
	`Codice` INTEGER NOT NULL,
    `Durata` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Codice`)
		REFERENCES `Impostazioni` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*
Al posto delle tabelle consumofisso e consumo varibile
*/
-- -----------------------------
--    Table structure for `AltreImpostazioni`
-- -----------------------------
DROP TABLE IF EXISTS `AltreImpostazioni`;
CREATE TABLE `AltreImpostazioni` (
	`Codice` INTEGER NOT NULL,
	`Potenza` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Codice`)
		REFERENCES `Impostazioni` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- -----------------------------
--    Table structure for `Utilizzabili`
-- -----------------------------
DROP TABLE IF EXISTS `Utilizzabili`;
CREATE TABLE `Utilizzabili` (
	`Dispositivo` INTEGER NOT NULL,
    `Impostazione` INTEGER NOT NULL,
	PRIMARY KEY (`Dispositivo`,`Impostazione`),
    FOREIGN KEY (`Dispositivo`)
		REFERENCES `Dispositivo` (`Codice`),
	FOREIGN KEY (`Impostazione`)
		REFERENCES `Impostazioni` (`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*
Diffferenze: meno chiavi, modifica foreign keys
*/
	
DROP TABLE IF EXISTS `Storico`;
CREATE TABLE `Storico` (
	`Account` VARCHAR(30) NOT NULL,
	`OrarioInterazione` TIMESTAMP NOT NULL,
	`Dispositivo` INTEGER NOT NULL,
	`Impostazione` INTEGER NOT NULL,
	`OraInizio` TIMESTAMP NOT NULL,
	`OraFine` TIMESTAMP,
	`Consumo` DOUBLE,
	`FasciaOraria` INTEGER,
	PRIMARY KEY (`Dispositivo`, `OraInizio`),			
	FOREIGN KEY (`Account`)
		REFERENCES `Account`(`NomeAccount`),
	FOREIGN KEY (`Impostazione`)
		REFERENCES `Impostazioni`(`Codice`),
	FOREIGN KEY (`FasciaOraria`)
		REFERENCES `Bilancio`(`FasciaOraria`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;





-- -----------------------------
--    Table structure for `Suggerimento`
-- -----------------------------
DROP TABLE IF EXISTS `Suggerimento`;
CREATE TABLE `Suggerimento` (
	`Codice` INTEGER NOT NULL AUTO_INCREMENT,
    `Dispositivo` INTEGER NOT NULL,
    `Impostazione` INTEGER NOT NULL,
    `Orario` TIMESTAMP NULL,
    `Scelto` BOOLEAN NULL,
    `Account` VARCHAR(30) NULL,
	PRIMARY KEY (`Codice`),
    FOREIGN KEY (`Dispositivo`)
		REFERENCES `Dispositivo`(`Codice`),
	FOREIGN KEY (`Impostazione`)
		REFERENCES `Impostazioni`(`Codice`),
	FOREIGN KEY (`Account`)
		REFERENCES `Account`(`NomeAccount`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*

Differenze: meno chiavi, modifica foreign keys

*/
-- -----------------------------
--    Table structure for `Predefinita`
-- -----------------------------
DROP TABLE IF EXISTS `Predefinita`;
CREATE TABLE `Predefinita` (
	`Codice` INTEGER NOT NULL,
    `Dispositivo`INTEGER NOT NULL,
    `Impostazione` INTEGER NOT NULL,
	PRIMARY KEY (`Codice`, `Dispositivo` ),
    FOREIGN KEY (`Dispositivo`)
		REFERENCES `Dispositivo`(`Codice`),
	FOREIGN KEY (`Impostazione`)
		REFERENCES `Impostazioni`(`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


/*

Differenze: meno chiavi, modifica foreign keys
*/
-- -----------------------------
--    Table structure for `Ricorrenza`
-- -----------------------------
DROP TABLE IF EXISTS `Ricorrenza`;
CREATE TABLE `Ricorrenza` (
	`Dispositivo` INTEGER NOT NULL,
    `Impostazione` INTEGER NOT NULL,
    `Giorno` INTEGER
		CHECK (`Giorno` >= 0 AND `Giorno` <= 7),
    `DataInizio` DATE NOT NULL,
    `DataFine` DATE NOT NULL,
    `Anno` BOOLEAN NOT NULL,
    `OraInizio` INTEGER NOT NULL
		CHECK (`OraInizio` >= 0 AND `OraInizio` <= 24),
    `OraFine` INTEGER NOT NULL
		CHECK (`OraFine` >= 0 AND `OraFine` <= 24),
	PRIMARY KEY (`Dispositivo`, `Giorno`, `DataInizio`, `OraInizio`),
    FOREIGN KEY (`Dispositivo`)
		REFERENCES `Dispositivo`(`Codice`),
	FOREIGN KEY (`Impostazione`)
		REFERENCES `Impostazioni`(`Codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;








