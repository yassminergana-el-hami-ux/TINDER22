-- Script SQL pour ajouter colonnes à la table `USER` et insérer des genres de test
-- Modifications : ALTER TABLE + INSERT pour la table GENRE

-- Ajouter les colonnes demandées
ALTER TABLE `USER`
  ADD COLUMN `emailUser` VARCHAR(100) NOT NULL UNIQUE AFTER `idGenr`,
  ADD COLUMN `mdpUser` VARCHAR(255) NOT NULL AFTER `emailUser`,
  ADD COLUMN `dateInscription` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER `mdpUser`;

-- Table simple pour limiter les tentatives d'inscription (IP + horodatage)
CREATE TABLE IF NOT EXISTS `registration_attempts` (
  `idAttempt` INT AUTO_INCREMENT PRIMARY KEY,
  `ip` VARCHAR(45) NOT NULL,
  `attempted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (`ip`),
  INDEX (`attempted_at`)
);

-- INSERTs de test pour la table GENRE
INSERT INTO `GENRE` (`libGenr`) VALUES
  ('Homme'),
  ('Femme'),
  ('Non-binaire')
ON DUPLICATE KEY UPDATE libGenr = VALUES(libGenr);

-- Notes :
-- - `registration_attempts` permet une implémentation simple du rate-limit.
-- - L'ALTER TABLE suppose que la table `USER` existe déjà avec la colonne `idGenr`.
