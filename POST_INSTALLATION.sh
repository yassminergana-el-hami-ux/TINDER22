#!/bin/bash

##############################################################################
#          🎯 POST-INSTALLATION CHECKLIST - Module Connexion
#
#  Exécutez ce script après l'installation pour valider le setup
##############################################################################

set -e  # Stop on error

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Compteurs
PASS=0
FAIL=0
WARN=0

# Fonction pour afficher un test
test_item() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Fonction pour marquer un succès
pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS++))
}

# Fonction pour marquer un échec
fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL++))
}

# Fonction pour marquer un warning
warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARN++))
}

##############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          POST-INSTALLATION VALIDATION                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# 1. Fichiers PHP Existants
##############################################################################

test_item "1️⃣  Vérification des fichiers PHP"

# Backend
[ -f "helpers/JwtHelper.php" ] && pass "JwtHelper.php" || fail "JwtHelper.php manquant"
[ -f "middlewares/authMiddleware.php" ] && pass "authMiddleware.php" || fail "authMiddleware.php manquant"
[ -f "models/UserModel.php" ] && pass "UserModel.php" || fail "UserModel.php manquant"
[ -f "controllers/AuthController.php" ] && pass "AuthController.php" || fail "AuthController.php manquant"
[ -f "routes/auth.php" ] && pass "routes/auth.php" || fail "routes/auth.php manquant"
[ -f "config/database.php" ] && pass "config/database.php" || fail "config/database.php manquant"
[ -f "api/index.php" ] && pass "api/index.php" || fail "api/index.php manquant"

##############################################################################
# 2. Fichiers HTML/JS Existants
##############################################################################

test_item "2️⃣  Vérification des fichiers Frontend"

[ -f "public/connexion.html" ] && pass "connexion.html" || fail "connexion.html manquant"
[ -f "public/home.html" ] && pass "home.html" || fail "home.html manquant"
[ -f "public/js/connexion.js" ] && pass "connexion.js" || fail "connexion.js manquant"
[ -f "public/js/auth-guard.js" ] && pass "auth-guard.js" || fail "auth-guard.js manquant"

##############################################################################
# 3. Fichiers SQL Existants
##############################################################################

test_item "3️⃣  Vérification des scripts SQL"

[ -f "sql/login_schema.sql" ] && pass "login_schema.sql" || fail "login_schema.sql manquant"

##############################################################################
# 4. Configuration .env
##############################################################################

test_item "4️⃣  Vérification de la configuration .env"

if [ -f ".env" ]; then
    pass ".env existe"
    
    if grep -q "DB_HOST" .env; then
        pass "DB_HOST configuré"
    else
        fail "DB_HOST non trouvé dans .env"
    fi
    
    if grep -q "DB_USER" .env; then
        pass "DB_USER configuré"
    else
        fail "DB_USER non trouvé dans .env"
    fi
    
    if grep -q "JWT_SECRET" .env; then
        JWT_LEN=$(grep "JWT_SECRET" .env | wc -c)
        if [ $JWT_LEN -gt 32 ]; then
            pass "JWT_SECRET configuré et suffisamment long ($JWT_LEN caractères)"
        else
            warn "JWT_SECRET existe mais est court ($JWT_LEN caractères). Min 32 recommandé."
        fi
    else
        fail "JWT_SECRET non trouvé dans .env → À AJOUTER"
    fi
else
    fail ".env n'existe pas"
fi

##############################################################################
# 5. Connexion à la Base de Données
##############################################################################

test_item "5️⃣  Connexion à la base de données"

DB_HOST=$(grep "DB_HOST" .env | cut -d'=' -f2 || echo "")
DB_USER=$(grep "DB_USER" .env | cut -d'=' -f2 || echo "")
DB_PASS=$(grep "DB_PASSWORD" .env | cut -d'=' -f2 || echo "")
DB_NAME=$(grep "DB_DATABASE" .env | cut -d'=' -f2 || echo "")

if [ -z "$DB_HOST" ] || [ -z "$DB_USER" ] || [ -z "$DB_NAME" ]; then
    fail "Configuration DB incomplète dans .env"
else
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SELECT 1;" 2>/dev/null; then
        pass "Connexion à la base de données OK"
    else
        fail "Impossible de se connecter à la base de données"
    fi
fi

##############################################################################
# 6. Schéma Base de Données
##############################################################################

test_item "6️⃣  Vérification du schéma USER"

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE USER;" 2>/dev/null | grep -q "derniereConnexion"; then
    pass "Colonne derniereConnexion existe"
else
    fail "Colonne derniereConnexion manquante → Exécuter sql/login_schema.sql"
fi

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE USER;" 2>/dev/null | grep -q "tentativesEchouees"; then
    pass "Colonne tentativesEchouees existe"
else
    fail "Colonne tentativesEchouees manquante → Exécuter sql/login_schema.sql"
fi

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE USER;" 2>/dev/null | grep -q "bloqueJusqua"; then
    pass "Colonne bloqueJusqua existe"
else
    fail "Colonne bloqueJusqua manquante → Exécuter sql/login_schema.sql"
fi

##############################################################################
# 7. Tables Auxiliaires
##############################################################################

test_item "7️⃣  Vérification des tables auxiliaires"

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE login_attempts;" 2>/dev/null; then
    pass "Table login_attempts existe"
else
    fail "Table login_attempts manquante → Exécuter sql/login_schema.sql"
fi

if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "DESCRIBE registration_attempts;" 2>/dev/null; then
    pass "Table registration_attempts existe"
else
    warn "Table registration_attempts manquante (nécessaire pour inscription)"
fi

##############################################################################
# 8. Genre de Test
##############################################################################

test_item "8️⃣  Vérification des genres de test"

GENRE_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT COUNT(*) FROM GENRE;" 2>/dev/null | tail -1)

if [ "$GENRE_COUNT" -ge 1 ]; then
    pass "Au moins $GENRE_COUNT genre(s) en base"
else
    fail "Aucun genre trouvé → Insérer via sql/login_schema.sql ou sql/register_schema.sql"
fi

##############################################################################
# 9. Utilisateur de Test
##############################################################################

test_item "9️⃣  Vérification utilisateur de test"

USER_COUNT=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT COUNT(*) FROM USER;" 2>/dev/null | tail -1)

if [ "$USER_COUNT" -ge 1 ]; then
    pass "Au moins $USER_COUNT utilisateur(s) en base"
    
    # Vérifier que l'utilisateur test existe
    TEST_USER=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT emailUser FROM USER WHERE emailUser='test@tinder.local' LIMIT 1;" 2>/dev/null | tail -1)
    if [ "$TEST_USER" = "test@tinder.local" ]; then
        pass "Utilisateur de test (test@tinder.local) existe"
    else
        warn "Utilisateur de test (test@tinder.local) non trouvé → Créer pour tester"
    fi
else
    warn "Aucun utilisateur en base → Créer via inscription ou manuellement"
fi

##############################################################################
# 10. Permissions Fichiers
##############################################################################

test_item "1️⃣0️⃣  Permissions des fichiers"

if [ -d "uploads" ]; then
    if [ -w "uploads" ]; then
        pass "Dossier uploads accessible en écriture"
    else
        fail "Dossier uploads NON accessible en écriture → chmod 755 uploads/"
    fi
else
    warn "Dossier uploads inexistant → mkdir uploads"
fi

if [ -f "uploads/.htaccess" ]; then
    pass "uploads/.htaccess existe"
else
    warn "uploads/.htaccess manquant → Protection scripts non activée"
fi

##############################################################################
# 11. Dépendances PHP
##############################################################################

test_item "1️⃣1️⃣  Vérification dépendances PHP"

# Tester une fonction simple
php -r "
echo 'Test 1: hash_hmac... ';
if (function_exists('hash_hmac')) { echo 'OK'; } else { echo 'FAIL'; }
echo PHP_EOL;

echo 'Test 2: password_hash... ';
if (function_exists('password_hash')) { echo 'OK'; } else { echo 'FAIL'; }
echo PHP_EOL;

echo 'Test 3: password_verify... ';
if (function_exists('password_verify')) { echo 'OK'; } else { echo 'FAIL'; }
echo PHP_EOL;

echo 'Test 4: json_encode... ';
if (function_exists('json_encode')) { echo 'OK'; } else { echo 'FAIL'; }
echo PHP_EOL;

echo 'Test 5: PDO... ';
if (class_exists('PDO')) { echo 'OK'; } else { echo 'FAIL'; }
echo PHP_EOL;
" 2>/dev/null | grep -q "FAIL" && fail "Certaines fonctions PHP manquent" || pass "Toutes les fonctions PHP requises sont disponibles"

##############################################################################
# 12. Accès Web
##############################################################################

test_item "1️⃣2️⃣  Accès web (si serveur lancé)"

# Vérifier que le serveur est accessible
if timeout 2 curl -s http://localhost/TINDER22/api/index.php > /dev/null 2>&1; then
    pass "Serveur web accessible"
    
    # Tester un endpoint
    RESPONSE=$(curl -s -X POST http://localhost/TINDER22/api/login \
        -H 'Content-Type: application/json' \
        -d '{"emailUser":"test@tinder.local","mdpUser":"TestPassword123!"}' 2>/dev/null)
    
    if echo "$RESPONSE" | grep -q "success"; then
        pass "Endpoint /api/login répond"
    else
        warn "Endpoint /api/login répond mais réponse inattendue"
    fi
else
    warn "Serveur web non accessible (MAMP doit être lancé)"
fi

##############################################################################
# 13. Documentation
##############################################################################

test_item "1️⃣3️⃣  Documentation présente"

[ -f "LOGIN_README.md" ] && pass "LOGIN_README.md" || warn "LOGIN_README.md manquant"
[ -f "ARCHITECTURE_LOGIN.md" ] && pass "ARCHITECTURE_LOGIN.md" || warn "ARCHITECTURE_LOGIN.md manquant"
[ -f "VALIDATION_CHECKLIST.md" ] && pass "VALIDATION_CHECKLIST.md" || warn "VALIDATION_CHECKLIST.md manquant"
[ -f "RESUME_COMPLET.md" ] && pass "RESUME_COMPLET.md" || warn "RESUME_COMPLET.md manquant"
[ -f "INDEX_DOCUMENTATION.md" ] && pass "INDEX_DOCUMENTATION.md" || warn "INDEX_DOCUMENTATION.md manquant"

##############################################################################
# RÉSUMÉ
##############################################################################

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    RÉSUMÉ DE VALIDATION                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Succès : $PASS${NC}"
echo -e "${RED}Erreurs : $FAIL${NC}"
echo -e "${YELLOW}Avertissements : $WARN${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✨ Installation validée avec succès !${NC}"
    echo ""
    echo "Prochaines étapes :"
    echo "  1. Tester la connexion : http://localhost/TINDER22/public/connexion.html"
    echo "  2. Exécuter les tests : bash TESTS_CURL.sh"
    echo "  3. Consulter la doc : cat INDEX_DOCUMENTATION.md"
    exit 0
else
    echo -e "${RED}⚠️  Il y a des erreurs à corriger avant de continuer${NC}"
    echo ""
    echo "Erreurs détectées :"
    echo "  - Vérifier les colonnes de la base de données"
    echo "  - Vérifier la configuration .env"
    echo "  - Exécuter les scripts SQL manquants"
    echo ""
    echo "Consultez VALIDATION_CHECKLIST.md pour plus de détails"
    exit 1
fi
