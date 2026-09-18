-- Script SQL pour le module de connexion
-- Ajouter colonnes manquantes et table de rate-limit par IP

-- Ajouter colonnes à la table USER si absent
ALTER TABLE `USER`
  ADD COLUMN `derniereConnexion` DATETIME NULL AFTER `dateInscription`,
  ADD COLUMN `tentativesEchouees` INT DEFAULT 0 AFTER `derniereConnexion`,
  ADD COLUMN `bloqueJusqua` DATETIME NULL AFTER `tentativesEchouees`;

-- Table pour limiter les tentatives par IP (rate-limit globale sur la connexion)
CREATE TABLE IF NOT EXISTS `login_attempts` (
  `idAttempt` INT AUTO_INCREMENT PRIMARY KEY,
  `ip` VARCHAR(45) NOT NULL,
  `attempted_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX (`ip`),
  INDEX (`attempted_at`)
);

-- Notes :
-- - derniereConnexion: pour tracer les activités
-- - tentativesEchouees: compteur pour le blocage compte (5 tentatives = 15 min blocage)
-- - bloqueJusqua: timestamp du déblocage automatique
-- - login_attempts: table pour rate-limit par IP (max 10 tentatives/heure/IP)
