/**
 * Script d'ajout des colonnes pour la fonctionnalité d'inscription
 * À exécuter sur la base TINDER22 existante
 * 
 * Ajoute les colonnes manquantes à la table USER
 */

USE TINDER22;

-- ==========================================
-- 1. Ajouter les colonnes à la table USER
-- ==========================================

ALTER TABLE `USER` 
ADD COLUMN `emailUser` VARCHAR(100) NOT NULL UNIQUE AFTER `idGenr`,
ADD COLUMN `mdpUser` VARCHAR(255) NOT NULL AFTER `emailUser`,
ADD COLUMN `dateInscription` DATETIME DEFAULT CURRENT_TIMESTAMP AFTER `mdpUser`;

-- ==========================================
-- Notes de sécurité :
-- ==========================================
-- 1. emailUser : UNIQUE pour éviter les doublons
-- 2. mdpUser : VARCHAR(255) pour stocker le hash bcrypt
-- 3. dateInscription : Enregistre automatiquement la date/heure de création
-- 4. Tous les champs sont validés côté PHP avec prepared statements

-- ==========================================
-- Vérification : afficher la structure mise à jour
-- ==========================================

-- DESCRIBE USER;
-- SELECT COUNT(*) FROM USER;
-- SELECT * FROM GENRE LIMIT 5;
