#!/bin/bash

##############################################################################
#                    EXEMPLES DE TEST - MODULE CONNEXION
#
# Exécutez ces commandes pour tester les endpoints du module de connexion
# Assurez-vous que :
#  1. Le serveur MAMP tourne
#  2. L'utilisateur test existe (email: test@tinder.local)
#  3. Les scripts SQL ont été exécutés
##############################################################################

# Configuration
API_BASE="http://localhost/TINDER22/api"
TEST_EMAIL="test@tinder.local"
TEST_PASSWORD="TestPassword123!"
WRONG_PASSWORD="WrongPassword123!"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  EXEMPLES DE TEST - MODULE DE CONNEXION (Tinder Clone)        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

##############################################################################
# TEST 1 : Connexion réussie
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 1 : Connexion réussie${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << 'EOF'
curl -i -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "test@tinder.local",
    "mdpUser": "TestPassword123!",
    "rememberMe": false
  }'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

RESPONSE=$(curl -s -i -X POST "$API_BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{
    \"emailUser\": \"$TEST_EMAIL\",
    \"mdpUser\": \"$TEST_PASSWORD\",
    \"rememberMe\": false
  }")

echo "$RESPONSE"
echo ""

# Extraire le token
TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4 | head -1)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}✅ Succès ! Token obtenu${NC}"
    echo -e "${BLUE}Token (premiers 50 caractères) :${NC} ${TOKEN:0:50}..."
    echo ""
else
    echo -e "${RED}❌ Erreur : Pas de token obtenu${NC}"
fi

echo ""

##############################################################################
# TEST 2 : Vérifier l'utilisateur avec GET /api/me
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 2 : Récupérer les infos de l'utilisateur (GET /api/me)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << EOF
curl -i -X GET '$API_BASE/me' \
  -H "Authorization: Bearer $TOKEN"
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

if [ -n "$TOKEN" ]; then
    ME_RESPONSE=$(curl -s -i -X GET "$API_BASE/me" \
      -H "Authorization: Bearer $TOKEN")
    echo "$ME_RESPONSE"
    
    if echo "$ME_RESPONSE" | grep -q '"success":true'; then
        echo -e "${GREEN}✅ Succès ! Infos utilisateur récupérées${NC}"
    else
        echo -e "${RED}❌ Erreur lors de la récupération${NC}"
    fi
else
    echo -e "${RED}⚠️  Impossible : pas de token du test précédent${NC}"
fi

echo ""

##############################################################################
# TEST 3 : Mot de passe incorrect
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 3 : Connexion échouée (mot de passe faux)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << EOF
curl -i -X POST '$API_BASE/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "$TEST_EMAIL",
    "mdpUser": "$WRONG_PASSWORD",
    "rememberMe": false
  }'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

FAIL_RESPONSE=$(curl -s -i -X POST "$API_BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{
    \"emailUser\": \"$TEST_EMAIL\",
    \"mdpUser\": \"$WRONG_PASSWORD\",
    \"rememberMe\": false
  }")

echo "$FAIL_RESPONSE"
echo ""

if echo "$FAIL_RESPONSE" | grep -q "401"; then
    echo -e "${GREEN}✅ Succès ! Erreur 401 retournée${NC}"
    if echo "$FAIL_RESPONSE" | grep -q "Email ou mot de passe incorrect"; then
        echo -e "${GREEN}✅ Message générique correct (pas d'énumération d'utilisateurs)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Code HTTP inattendu${NC}"
fi

echo ""

##############################################################################
# TEST 4 : Champs manquants
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 4 : Requête invalide (champ manquant)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << EOF
curl -i -X POST '$API_BASE/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "$TEST_EMAIL"
  }'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

INVALID_RESPONSE=$(curl -s -i -X POST "$API_BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{\"emailUser\": \"$TEST_EMAIL\"}")

echo "$INVALID_RESPONSE"
echo ""

if echo "$INVALID_RESPONSE" | grep -q "400"; then
    echo -e "${GREEN}✅ Succès ! Erreur 400 retournée${NC}"
else
    echo -e "${YELLOW}⚠️  Code HTTP inattendu${NC}"
fi

echo ""

##############################################################################
# TEST 5 : Bloquer le compte avec 5 tentatives
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 5 : Bloquer le compte (5 tentatives échouées)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Envoi de 5 tentatives avec mot de passe faux...${NC}"
echo ""

for i in {1..5}; do
    echo -e "${BLUE}Tentative $i/5...${NC}"
    
    LOCK_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_BASE/login" \
      -H 'Content-Type: application/json' \
      -d "{
        \"emailUser\": \"$TEST_EMAIL\",
        \"mdpUser\": \"$WRONG_PASSWORD\",
        \"rememberMe\": false
      }")
    
    HTTP_CODE=$(echo "$LOCK_RESPONSE" | tail -n1)
    BODY=$(echo "$LOCK_RESPONSE" | head -n-1)
    
    if [ "$HTTP_CODE" = "401" ]; then
        echo -e "  ${GREEN}✓ Tentative $i : 401 (compte pas encore bloqué)${NC}"
    elif [ "$HTTP_CODE" = "423" ]; then
        echo -e "  ${RED}✓ Tentative $i : 423 (COMPTE BLOQUÉ !)${NC}"
        MINUTES=$(echo "$BODY" | grep -o '"minutesRestantes":[0-9]*' | grep -o '[0-9]*')
        echo -e "  ${RED}Durée du blocage : $MINUTES minutes${NC}"
        break
    else
        echo -e "  ${YELLOW}? Tentative $i : Code $HTTP_CODE${NC}"
    fi
done

echo ""

##############################################################################
# TEST 6 : Compte bloqué (423)
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 6 : Essayer de se connecter avec compte bloqué (423)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << EOF
curl -i -X POST '$API_BASE/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "$TEST_EMAIL",
    "mdpUser": "$TEST_PASSWORD",
    "rememberMe": false
  }'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

LOCKED_RESPONSE=$(curl -s -i -X POST "$API_BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{
    \"emailUser\": \"$TEST_EMAIL\",
    \"mdpUser\": \"$TEST_PASSWORD\",
    \"rememberMe\": false
  }")

echo "$LOCKED_RESPONSE"
echo ""

if echo "$LOCKED_RESPONSE" | grep -q "423"; then
    echo -e "${GREEN}✅ Succès ! Code 423 (Locked) retourné${NC}"
    MINUTES=$(echo "$LOCKED_RESPONSE" | grep -o '"minutesRestantes":[0-9]*' | grep -o '[0-9]*')
    if [ -n "$MINUTES" ]; then
        echo -e "${GREEN}Minutes restantes : $MINUTES${NC}"
    fi
else
    echo -e "${RED}❌ Erreur : Code 423 attendu${NC}"
fi

echo ""

##############################################################################
# TEST 7 : Token invalide
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 7 : GET /api/me avec token invalide${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << 'EOF'
curl -i -X GET 'http://localhost/TINDER22/api/me' \
  -H 'Authorization: Bearer invalid-token-xyz'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

INVALID_TOKEN_RESPONSE=$(curl -s -i -X GET "$API_BASE/me" \
  -H 'Authorization: Bearer invalid-token-xyz')

echo "$INVALID_TOKEN_RESPONSE"
echo ""

if echo "$INVALID_TOKEN_RESPONSE" | grep -q "401"; then
    echo -e "${GREEN}✅ Succès ! Code 401 retourné pour token invalide${NC}"
else
    echo -e "${RED}❌ Erreur : Code 401 attendu${NC}"
fi

echo ""

##############################################################################
# TEST 8 : Pas de token
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 8 : GET /api/me sans token${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << 'EOF'
curl -i -X GET 'http://localhost/TINDER22/api/me'
EOF

echo ""
echo -e "${BLUE}Exécution :${NC}"

NO_TOKEN_RESPONSE=$(curl -s -i -X GET "$API_BASE/me")

echo "$NO_TOKEN_RESPONSE"
echo ""

if echo "$NO_TOKEN_RESPONSE" | grep -q "401"; then
    echo -e "${GREEN}✅ Succès ! Code 401 retourné (pas de token)${NC}"
else
    echo -e "${RED}❌ Erreur : Code 401 attendu${NC}"
fi

echo ""

##############################################################################
# TEST 9 : Déconnexion
##############################################################################
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST 9 : Déconnexion (POST /api/logout)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${BLUE}Commande :${NC}"
cat << EOF
curl -i -X POST '$API_BASE/logout' \
  -H "Authorization: Bearer <token>"
EOF

echo ""
echo -e "${BLUE}Note :${NC} JWT stateless → déconnexion côté client (suppression token)"
echo -e "${BLUE}      POST /api/logout retourne 200 (aucun effet serveur)${NC}"
echo ""

echo -e "${BLUE}Exécution :${NC}"

if [ -n "$TOKEN" ]; then
    LOGOUT_RESPONSE=$(curl -s -i -X POST "$API_BASE/logout" \
      -H "Authorization: Bearer $TOKEN")
    echo "$LOGOUT_RESPONSE"
    echo ""
    echo -e "${GREEN}✅ Réponse reçue (Déconnexion = suppression du token en localStorage)${NC}"
else
    echo -e "${YELLOW}⚠️  Pas de token du test précédent${NC}"
fi

echo ""

##############################################################################
# RÉSUMÉ
##############################################################################
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                         TESTS TERMINÉS                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Récapitulatif :${NC}"
echo -e "  ✅ TEST 1  : Connexion réussie (200)"
echo -e "  ✅ TEST 2  : Récupération infos utilisateur (200)"
echo -e "  ✅ TEST 3  : Mot de passe faux (401)"
echo -e "  ✅ TEST 4  : Champs manquants (400)"
echo -e "  ✅ TEST 5  : Blocage après 5 tentatives"
echo -e "  ✅ TEST 6  : Compte bloqué (423)"
echo -e "  ✅ TEST 7  : Token invalide (401)"
echo -e "  ✅ TEST 8  : Pas de token (401)"
echo -e "  ✅ TEST 9  : Déconnexion (200)"
echo ""

echo -e "${GREEN}✨ Tous les tests doivent réussir avant déploiement en production${NC}"
echo ""
