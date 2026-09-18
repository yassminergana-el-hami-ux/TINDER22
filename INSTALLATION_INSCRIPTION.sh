#!/bin/bash

##############################################################################
#     🚀 GUIDE D'INSTALLATION RAPIDE - Fonctionnalité Inscription
##############################################################################

echo "=================================================="
echo "   Installation: Créer un Compte - Backend"
echo "=================================================="
echo ""

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================================================
# ÉTAPE 1: Exécuter le script SQL
# ============================================================================
echo -e "${BLUE}[1/4] Exécution du script SQL...${NC}"
echo "Commande:"
echo "  mysql -u root -p TINDER22 < BDD/register_schema.sql"
echo ""
echo -e "${YELLOW}⚠️  Avant d'exécuter, vérifiez:${NC}"
echo "  • MySQL est lancé"
echo "  • La base TINDER22 existe"
echo "  • Votre mot de passe root"
echo ""

# ============================================================================
# ÉTAPE 2: Vérifier les genres
# ============================================================================
echo -e "${BLUE}[2/4] Vérification des genres...${NC}"
echo "Connectez-vous à MySQL et exécutez:"
echo ""
echo "  mysql -u root -p TINDER22"
echo "  SELECT * FROM GENRE;"
echo ""
echo "Si aucun genre, insérez:"
echo ""
echo "  INSERT INTO GENRE (libGenr) VALUES ('Homme');"
echo "  INSERT INTO GENRE (libGenr) VALUES ('Femme');"
echo "  INSERT INTO GENRE (libGenr) VALUES ('Non-binaire');"
echo "  INSERT INTO GENRE (libGenr) VALUES ('Autre');"
echo ""

# ============================================================================
# ÉTAPE 3: Vérifier la structure
# ============================================================================
echo -e "${BLUE}[3/4] Vérification de la table USER...${NC}"
echo "Exécutez en MySQL:"
echo ""
echo "  DESCRIBE USER;"
echo ""
echo -e "${GREEN}Vous devriez voir:${NC}"
echo "  • emailUser      VARCHAR(100) UNIQUE NOT NULL"
echo "  • mdpUser        VARCHAR(255) NOT NULL"
echo "  • dateInscription DATETIME DEFAULT CURRENT_TIMESTAMP"
echo ""

# ============================================================================
# ÉTAPE 4: Accéder au formulaire
# ============================================================================
echo -e "${BLUE}[4/4] Accès au formulaire...${NC}"
echo ""
echo -e "${GREEN}✅ Le formulaire est accessible à:${NC}"
echo "  http://localhost/TINDER22/views/backend/users/create.php"
echo ""

# ============================================================================
# INFORMATIONS
# ============================================================================
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo "📋 FICHIERS IMPORTANTS"
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo ""
echo "Formulaire:"
echo "  📄 views/backend/users/create.php (toute la logique)"
echo ""
echo "Base de données:"
echo "  📄 BDD/register_schema.sql (script d'installation)"
echo "  📄 BDD/CreateDbTinder22.sql (structure initiale)"
echo ""
echo "Documentation:"
echo "  📄 INSCRIPTION_README.md (documentation complète)"
echo ""

# ============================================================================
# PREMIÈRES ÉTAPES
# ============================================================================
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo "🚀 PREMIÈRES ÉTAPES"
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo ""
echo "1️⃣  Exécuter le SQL:"
echo "    mysql -u root -p TINDER22 < BDD/register_schema.sql"
echo ""
echo "2️⃣  Ajouter des genres (si besoin):"
echo "    mysql -u root -p"
echo "    > USE TINDER22;"
echo "    > INSERT INTO GENRE (libGenr) VALUES ('Homme'), ('Femme');"
echo ""
echo "3️⃣  Ouvrir le formulaire:"
echo "    http://localhost/TINDER22/views/backend/users/create.php"
echo ""
echo "4️⃣  Remplir et soumettre le formulaire"
echo ""

# ============================================================================
# VALIDATION
# ============================================================================
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo "✅ CHECKLIST DE VALIDATION"
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo ""
echo "Avant d'utiliser le formulaire:"
echo ""
echo "  ☐ MySQL lancé (MAMP running)"
echo "  ☐ Script SQL exécuté"
echo "  ☐ Table USER a colonnes emailUser, mdpUser, dateInscription"
echo "  ☐ Au moins 1 genre en BD"
echo "  ☐ Serveur PHP actif"
echo "  ☐ Fichier views/backend/users/create.php accessible"
echo ""

# ============================================================================
# TEST
# ============================================================================
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo "🧪 TEST RAPIDE"
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo ""
echo "Données de test valides:"
echo ""
echo "  Prénom:       Yassmine"
echo "  Nom:          Rgana"
echo "  Naissance:    2007-08-15"
echo "  Genre:        (choisir Femme ou autre)"
echo "  Email:        test@example.com"
echo "  MDP:          SecurePass123!"
echo "  Confirmation: SecurePass123!"
echo "  Ville:        Bordeaux"
echo "  Bio:          Développeuse passionnée"
echo ""

# ============================================================================
# SÉCURITÉ
# ============================================================================
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo "🔐 POINTS DE SÉCURITÉ IMPORTANTS"
echo -e "${YELLOW}═════════════════════════════════════════════════════════${NC}"
echo ""
echo "✓ Mots de passe hashés avec bcrypt"
echo "✓ Emails uniques en base de données"
echo "✓ Prepared statements (protection SQL injection)"
echo "✓ Validation stricte côté serveur"
echo "✓ Données échappées en HTML"
echo "✓ Messages d'erreur génériques"
echo ""

echo -e "${GREEN}═════════════════════════════════════════════════════════${NC}"
echo "           ✨ Configuration terminée! ✨"
echo -e "${GREEN}═════════════════════════════════════════════════════════${NC}"
echo ""
