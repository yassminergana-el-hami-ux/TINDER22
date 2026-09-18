#!/bin/bash

# Script de test du module de connexion
# Prérequis : curl, mysql, un utilisateur TEST créé en base

API_URL="http://localhost/TINDER22/api"
TEST_EMAIL="test@tinder.local"
TEST_PASSWORD="TestPassword123!"

echo "╔════════════════════════════════════════════════════════╗"
echo "║  Test du Module de Connexion (Tinder Clone)           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

# Créer l'utilisateur de test si nécessaire
echo "[1/6] Préparation : création de l'utilisateur de test en base..."
mysql -u root -p -e "
  INSERT INTO TINDER22.USER (idGenr, nomEUser, prenomUser, photo, age, biographie, emailUser, mdpUser)
  VALUES (1, 'Test', 'User', NULL, 25, 'Utilisateur de test', '$TEST_EMAIL', '\$(php -r \"echo password_hash('$TEST_PASSWORD', PASSWORD_DEFAULT);\")');
" 2>/dev/null || echo "   ⚠️  Utilisateur peut exister. Continuons..."

echo ""

# Test 1 : Connexion réussie
echo "[2/6] Test : Connexion réussie"
echo "  Requête : POST $API_URL/login"
RESPONSE=$(curl -s -X POST "$API_URL/login" \
  -H 'Content-Type: application/json' \
  -d "{\"emailUser\":\"$TEST_EMAIL\",\"mdpUser\":\"$TEST_PASSWORD\",\"rememberMe\":false}")

echo "  Réponse : $RESPONSE"
TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
    echo "  ✅ Connexion réussie. Token obtenu."
    echo "  Token (premiers 50 chars) : ${TOKEN:0:50}..."
else
    echo "  ❌ Connexion échouée."
    exit 1
fi

echo ""

# Test 2 : Vérifier l'utilisateur avec GET /api/me
echo "[3/6] Test : Vérifier GET /api/me avec le token valide"
ME_RESPONSE=$(curl -s -X GET "$API_URL/me" \
  -H "Authorization: Bearer $TOKEN")
echo "  Réponse : $ME_RESPONSE"
if echo "$ME_RESPONSE" | grep -q "success.*true"; then
    echo "  ✅ Infos utilisateur récupérées."
else
    echo "  ❌ Erreur lors de la récupération des infos."
fi

echo ""

# Test 3 : Tentative avec mot de passe faux (compteur d'échecs)
echo "[4/6] Test : 5 tentatives avec mot de passe faux (pour bloquer le compte)"
for i in {1..5}; do
    echo "  Tentative $i/5..."
    FAIL_RESPONSE=$(curl -s -X POST "$API_URL/login" \
      -H 'Content-Type: application/json' \
      -d "{\"emailUser\":\"$TEST_EMAIL\",\"mdpUser\":\"MauvaisMdp123!\",\"rememberMe\":false}")
    
    if echo "$FAIL_RESPONSE" | grep -q '"message":"Email ou mot de passe incorrect"'; then
        echo "    ✅ Réponse générique correcte"
    else
        echo "    ⚠️  Réponse inattendue : $FAIL_RESPONSE"
    fi
done

echo ""

# Test 4 : Vérifier le blocage du compte
echo "[5/6] Test : Essayer de se connecter avec le compte bloqué"
LOCKED_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/login" \
  -H 'Content-Type: application/json' \
  -d "{\"emailUser\":\"$TEST_EMAIL\",\"mdpUser\":\"$TEST_PASSWORD\",\"rememberMe\":false}")

HTTP_CODE=$(echo "$LOCKED_RESPONSE" | tail -n1)
BODY=$(echo "$LOCKED_RESPONSE" | head -n-1)

echo "  Code HTTP : $HTTP_CODE"
echo "  Réponse : $BODY"

if [ "$HTTP_CODE" = "423" ]; then
    echo "  ✅ Compte correctement bloqué (code 423)"
    MINUTES=$(echo "$BODY" | grep -o '"minutesRestantes":[0-9]*' | grep -o '[0-9]*')
    echo "  Minutes restantes de blocage : $MINUTES"
else
    echo "  ❌ Code HTTP inattendu (attendu 423, obtenu $HTTP_CODE)"
fi

echo ""

# Test 5 : Token invalide
echo "[6/6] Test : GET /api/me avec un token invalide"
INVALID_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$API_URL/me" \
  -H 'Authorization: Bearer invalid-token-xyz')

INVALID_CODE=$(echo "$INVALID_RESPONSE" | tail -n1)
INVALID_BODY=$(echo "$INVALID_RESPONSE" | head -n-1)

echo "  Code HTTP : $INVALID_CODE"
echo "  Réponse : $INVALID_BODY"

if [ "$INVALID_CODE" = "401" ]; then
    echo "  ✅ Token invalide correctement rejeté (code 401)"
else
    echo "  ⚠️  Code HTTP inattendu (attendu 401, obtenu $INVALID_CODE)"
fi

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║  Tests complétés !                                     ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "Prochaines étapes :"
echo "  1. Vérifier que le compte TEST est déblocké après 15 minutes"
echo "  2. Tester via le navigateur : http://localhost/TINDER22/public/connexion.html"
echo "  3. Tester la redirection vers home.html après connexion"
echo "  4. Tester la protection de pages avec auth-guard.js"
