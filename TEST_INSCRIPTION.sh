#!/bin/bash

##############################################################################
#          🧪 TESTS - Fonctionnalité Créer un Compte
#
#  Script de validation et test du formulaire d'inscription
##############################################################################

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🧪 TESTS - Créer un Compte (Backend)             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# TEST 1: Vérifier que la page est accessible
##############################################################################
echo -e "${YELLOW}[TEST 1] Vérifier que la page est accessible${NC}"
echo "URL: http://localhost/TINDER22/views/backend/users/create.php"
echo ""
if timeout 3 curl -s http://localhost/TINDER22/views/backend/users/create.php | grep -q "Créer un nouveau"; then
    echo -e "${GREEN}✅ Page accessible${NC}"
else
    echo -e "${RED}❌ Page non accessible${NC}"
    echo "   Vérifiez que MAMP est lancé"
fi
echo ""

##############################################################################
# TEST 2: Vérifier la base de données
##############################################################################
echo -e "${YELLOW}[TEST 2] Vérifier la base de données${NC}"
echo ""

# Vérifier la connexion MySQL
if mysql -u root -e "USE TINDER22; SELECT 1;" 2>/dev/null; then
    echo -e "${GREEN}✅ Base TINDER22 accessible${NC}"
else
    echo -e "${RED}❌ Base TINDER22 non accessible${NC}"
    echo "   Vérifiez que MySQL est lancé"
fi
echo ""

# Vérifier les colonnes USER
echo -e "${YELLOW}Vérification des colonnes USER:${NC}"
if mysql -u root TINDER22 -e "DESCRIBE USER;" 2>/dev/null | grep -q "emailUser"; then
    echo -e "${GREEN}✅ Colonne emailUser existe${NC}"
else
    echo -e "${RED}❌ Colonne emailUser manquante${NC}"
    echo "   Exécutez: mysql -u root -p TINDER22 < BDD/register_schema.sql"
fi

if mysql -u root TINDER22 -e "DESCRIBE USER;" 2>/dev/null | grep -q "mdpUser"; then
    echo -e "${GREEN}✅ Colonne mdpUser existe${NC}"
else
    echo -e "${RED}❌ Colonne mdpUser manquante${NC}"
fi

if mysql -u root TINDER22 -e "DESCRIBE USER;" 2>/dev/null | grep -q "dateInscription"; then
    echo -e "${GREEN}✅ Colonne dateInscription existe${NC}"
else
    echo -e "${RED}❌ Colonne dateInscription manquante${NC}"
fi
echo ""

##############################################################################
# TEST 3: Vérifier les genres
##############################################################################
echo -e "${YELLOW}[TEST 3] Vérifier les genres en base${NC}"
echo ""

GENRE_COUNT=$(mysql -u root TINDER22 -e "SELECT COUNT(*) as nb FROM GENRE;" 2>/dev/null | grep -v "nb" | head -1)

if [ "$GENRE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ $GENRE_COUNT genre(s) trouvé(s)${NC}"
    mysql -u root TINDER22 -e "SELECT idGenr, libGenr FROM GENRE;" 2>/dev/null | tail -n +2
else
    echo -e "${RED}❌ Aucun genre trouvé${NC}"
    echo "   Insérez des genres:"
    echo "     INSERT INTO GENRE (libGenr) VALUES ('Homme'), ('Femme'), ('Non-binaire');"
fi
echo ""

##############################################################################
# TEST 4: Vérifier les utilisateurs existants
##############################################################################
echo -e "${YELLOW}[TEST 4] Vérifier les utilisateurs existants${NC}"
echo ""

USER_COUNT=$(mysql -u root TINDER22 -e "SELECT COUNT(*) as nb FROM USER;" 2>/dev/null | grep -v "nb" | head -1)

if [ "$USER_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}$USER_COUNT utilisateur(s) déjà présent(s):${NC}"
    mysql -u root TINDER22 -e "SELECT idUser, prenomUser, nomEUser, emailUser, dateInscription FROM USER LIMIT 10;" 2>/dev/null | tail -n +2
else
    echo -e "${GREEN}✅ Table USER vide (prêt pour test)${NC}"
fi
echo ""

##############################################################################
# TEST 5: Validation des emails
##############################################################################
echo -e "${YELLOW}[TEST 5] Test de validation des emails${NC}"
echo ""

# Récupérer les emails existants
EXISTING_EMAILS=$(mysql -u root TINDER22 -e "SELECT emailUser FROM USER;" 2>/dev/null | grep -v "emailUser")

if [ ! -z "$EXISTING_EMAILS" ]; then
    echo -e "${YELLOW}Emails déjà utilisés (à éviter):${NC}"
    echo "$EXISTING_EMAILS"
else
    echo -e "${GREEN}✅ Aucun email préexistant${NC}"
fi
echo ""

##############################################################################
# TEST 6: Permissions des fichiers
##############################################################################
echo -e "${YELLOW}[TEST 6] Vérifier les permissions des fichiers${NC}"
echo ""

if [ -f "views/backend/users/create.php" ]; then
    echo -e "${GREEN}✅ Fichier create.php existe${NC}"
    if [ -r "views/backend/users/create.php" ]; then
        echo -e "${GREEN}✅ Fichier create.php est lisible${NC}"
    else
        echo -e "${RED}❌ Fichier create.php n'est pas lisible${NC}"
    fi
else
    echo -e "${RED}❌ Fichier create.php manquant${NC}"
fi

if [ -r "config/database.php" ]; then
    echo -e "${GREEN}✅ Fichier config/database.php accessible${NC}"
else
    echo -e "${RED}❌ Fichier config/database.php non accessible${NC}"
fi
echo ""

##############################################################################
# TEST 7: Configuration .env
##############################################################################
echo -e "${YELLOW}[TEST 7] Vérifier la configuration .env${NC}"
echo ""

if [ -f ".env" ]; then
    echo -e "${GREEN}✅ Fichier .env existe${NC}"
    
    if grep -q "DB_HOST" .env; then
        echo -e "${GREEN}✅ DB_HOST configuré${NC}"
    else
        echo -e "${YELLOW}⚠️  DB_HOST non trouvé${NC}"
    fi
    
    if grep -q "DB_DATABASE" .env; then
        echo -e "${GREEN}✅ DB_DATABASE configuré${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Fichier .env manquant (utilise les defaults)${NC}"
fi
echo ""

##############################################################################
# TEST 8: Résumé et recommandations
##############################################################################
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    RÉSUMÉ & PROCHAINES ÉTAPES             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📋 Checklist avant d'utiliser le formulaire:${NC}"
echo ""
echo "  ☐ MAMP lancé (Apache + MySQL)"
echo "  ☐ Base TINDER22 existe"
echo "  ☐ Colonnes emailUser, mdpUser, dateInscription ajoutées"
echo "  ☐ Au moins 1 genre en BD"
echo "  ☐ Fichier create.php accessible"
echo ""

echo -e "${YELLOW}🚀 Accès au formulaire:${NC}"
echo ""
echo "  http://localhost/TINDER22/views/backend/users/create.php"
echo ""

echo -e "${YELLOW}✅ Données de test valides:${NC}"
echo ""
echo "  Prénom:       Yassmine"
echo "  Nom:          Rgana"
echo "  Naissance:    2007-08-15 (format YYYY-MM-DD)"
echo "  Genre:        (Femme, Homme, etc.)"
echo "  Email:        test@example.com (unique!)"
echo "  MDP:          SecurePass123 (8+ chars, maj, min, chiffre)"
echo "  Confirmation: SecurePass123"
echo ""

echo -e "${YELLOW}❌ Données de test invalides:${NC}"
echo ""
echo "  Email valide:  \"test@\" → ❌ Format invalide"
echo "  Email valide:  \"test\" → ❌ Pas de @"
echo "  MDP faible:    \"pass\" → ❌ < 8 caractères"
echo "  MDP faible:    \"password123\" → ❌ Pas de majuscule"
echo "  MDP faible:    \"Password\" → ❌ Pas de chiffre"
echo "  Confirmations différentes → ❌ Ne correspondent pas"
echo "  Date future → ❌ Age invalide"
echo "  Age < 18 → ❌ Trop jeune"
echo ""

echo -e "${YELLOW}🧹 Nettoyage (après test):${NC}"
echo ""
echo "  Pour supprimer les utilisateurs de test:"
echo "  DELETE FROM USER WHERE dateInscription >= DATE_SUB(NOW(), INTERVAL 1 DAY);"
echo ""
echo "  Pour réinitialiser la table:"
echo "  DELETE FROM USER;"
echo "  ALTER TABLE USER AUTO_INCREMENT = 1;"
echo ""

echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo "              ✨ Tests terminés! Bonne chance! ✨"
echo -e "${GREEN}═════════════════════════════════════════════════════════════${NC}"
echo ""
