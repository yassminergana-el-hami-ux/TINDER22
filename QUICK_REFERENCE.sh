#!/bin/bash

# 🚀 QUICK REFERENCE - Commandes Essentielles
# Copie-colle rapide pour démarrer le module login

##############################################################################
#                          INSTALLATION (5 MIN)
##############################################################################

# 1️⃣  Exécuter le script SQL
mysql -u root -p TINDER22 < sql/login_schema.sql

# 2️⃣  Ajouter JWT_SECRET dans .env
# Éditer .env et ajouter :
# JWT_SECRET=votre-clé-secrète-très-forte-au-minimum-32-caractères

# 3️⃣  Créer utilisateur de test
php -r "echo password_hash('TestPassword123!', PASSWORD_DEFAULT);"
# Copier le résultat et l'insérer ci-dessous

mysql -u root -p TINDER22 << EOF
INSERT INTO USER (idGenr, nomEUser, prenomUser, age, emailUser, mdpUser)
VALUES (1, 'Test', 'User', 25, 'test@tinder.local', '<COLLER-LE-HASH-ICI>');
EOF

##############################################################################
#                          TESTS RAPIDES
##############################################################################

# Test 1️⃣  : Connexion réussie (200)
curl -s -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "test@tinder.local",
    "mdpUser": "TestPassword123!"
  }' | jq '.'

# Test 2️⃣  : Mot de passe faux (401)
curl -s -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser": "test@tinder.local",
    "mdpUser": "WRONG"
  }' | jq '.message'

# Test 3️⃣  : Champs manquants (400)
curl -s -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{"emailUser": "test@tinder.local"}' | jq '.message'

##############################################################################
#                          STOCKER ET UTILISER TOKEN
##############################################################################

# Récupérer le token
TOKEN=$(curl -s -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{"emailUser":"test@tinder.local","mdpUser":"TestPassword123!"}' \
  | jq -r '.token')

echo "Token obtenu : $TOKEN"

# Utiliser le token pour GET /api/me
curl -s -X GET 'http://localhost/TINDER22/api/me' \
  -H "Authorization: Bearer $TOKEN" | jq '.'

##############################################################################
#                          BLOCAGE COMPTE (423)
##############################################################################

# Faire 5 tentatives échouées (bloc le compte)
for i in {1..5}; do
  echo "Tentative $i..."
  curl -s -X POST 'http://localhost/TINDER22/api/login' \
    -H 'Content-Type: application/json' \
    -d '{"emailUser":"test@tinder.local","mdpUser":"WRONG"}' \
    | jq '.message'
done

# 6ème tentative : compte bloqué (423)
curl -s -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{"emailUser":"test@tinder.local","mdpUser":"TestPassword123!"}' \
  | jq '.'

##############################################################################
#                          ACCÈS NAVIGATEUR
##############################################################################

# Connexion
open http://localhost/TINDER22/public/connexion.html

# Home (page protégée)
open http://localhost/TINDER22/public/home.html

##############################################################################
#                          VÉRIFICATIONS EN BASE
##############################################################################

# Vérifier l'utilisateur test
mysql -u root -p -e "SELECT idUser, emailUser, tentativesEchouees, bloqueJusqua FROM TINDER22.USER WHERE emailUser='test@tinder.local';"

# Vérifier les tentatives de connexion
mysql -u root -p -e "SELECT COUNT(*) as tentatives_derniere_heure FROM TINDER22.login_attempts WHERE ip='127.0.0.1' AND attempted_at >= NOW() - INTERVAL 1 HOUR;"

# Débloquer manuellement un compte (si nécessaire)
mysql -u root -p -e "UPDATE TINDER22.USER SET bloqueJusqua=NULL, tentativesEchouees=0 WHERE emailUser='test@tinder.local';"

##############################################################################
#                          LOGS ET DÉBUG
##############################################################################

# Vérifier les erreurs PHP
tail -f /Applications/MAMP/logs/php_error.log

# Consulter les logs MySQL
mysql -u root -p -e "SHOW WARNINGS;"

# Tester la connexion PDO
php -r "
require 'config/database.php';
try {
  \$db = Database::getInstance();
  echo 'PDO OK' . PHP_EOL;
} catch (Exception \$e) {
  echo 'Erreur: ' . \$e->getMessage();
}
"

##############################################################################
#                          SCRIPTS DE TEST
##############################################################################

# Tests automatisés complets
bash test_login.sh

# Exemples cURL interactifs
bash TESTS_CURL.sh

##############################################################################
#                          FICHIERS IMPORTANTS
##############################################################################

# Documentation de base
cat LOGIN_README.md

# Checklist validation
cat VALIDATION_CHECKLIST.md

# Architecture détaillée
cat ARCHITECTURE_LOGIN.md

# Tous les fichiers créés
find . -name "*.php" -o -name "*.html" -o -name "*.js" -o -name "*.sql" | grep -E "(login|jwt|auth)" | sort

##############################################################################
#                          CONFIGURATION
##############################################################################

# Générer une clé JWT forte
openssl rand -hex 32

# Vérifier la config .env
grep -E "DB_|JWT_|APP_" .env

# Ajouter à .env si absent
echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env

##############################################################################
#                          DÉBLOCAGE MANUEL
##############################################################################

# Débloquer compte bloqué
ACCOUNT_ID=1
mysql -u root -p TINDER22 -e "UPDATE USER SET bloqueJusqua=NULL WHERE idUser=$ACCOUNT_ID;"

# Réinitialiser tous les compteurs
mysql -u root -p TINDER22 -e "UPDATE USER SET tentativesEchouees=0, bloqueJusqua=NULL;"

##############################################################################
#                          PRODUCTION CHECKLIST
##############################################################################

# ✅ AVANT DÉPLOIEMENT

# 1. Vérifier HTTPS
curl -I https://votre-domaine.com/api/login

# 2. Vérifier JWT_SECRET (fort et secret)
grep JWT_SECRET .env | wc -c  # Doit être > 32

# 3. Vérifier httpOnly cookie
grep -i "httponly" controllers/AuthController.php

# 4. Vérifier les logs ne contiennent pas de mots de passe
grep -i "mdpuser" /var/log/php-fpm.log || echo "OK"

# 5. Tester rate-limit par IP (429)
for i in {1..15}; do curl -s http://localhost/TINDER22/api/login -H 'Content-Type: application/json' -d '{"emailUser":"x","mdpUser":"x"}' > /dev/null; done
curl -s -w "%{http_code}" http://localhost/TINDER22/api/login -H 'Content-Type: application/json' -d '{"emailUser":"x","mdpUser":"x"}'

##############################################################################
#                          TROUBLESHOOT
##############################################################################

# Erreur "Token invalide"
# → Vérifier JWT_SECRET dans .env
grep JWT_SECRET .env

# Erreur "Pas de base de données"
# → Vérifier les paramètres dans .env
mysql -u root -p -e "USE TINDER22; SELECT 1;" 2>&1

# Erreur "404 Not Found"
# → Vérifier les fichiers PHP existent
ls -la helpers/JwtHelper.php middlewares/authMiddleware.php

# Erreur "Timeout" lors du login
# → Vérifier password_verify() n'est pas bloqué (rare)
# → Vérifier la base de données est accessible
mysql -u root -p -e "SELECT 1 FROM TINDER22.USER LIMIT 1;"

##############################################################################
#                          PERFORMANCE
##############################################################################

# Test de charge : 100 connexions en 10s
ab -n 100 -c 10 -p payload.json http://localhost/TINDER22/api/login

# Où payload.json contient :
# {"emailUser":"test@tinder.local","mdpUser":"TestPassword123!"}

# Vérifier l'index sur emailUser
mysql -u root -p -e "SHOW INDEXES FROM TINDER22.USER WHERE Column_name='emailUser';"

##############################################################################
#                          NETTOYAGE
##############################################################################

# Supprimer les anciens tokens (optionnel, JWT stateless)
# → Rien à faire, les tokens sont stateless

# Nettoyer les tentatives de connexion anciennes (> 1 mois)
mysql -u root -p -e "DELETE FROM TINDER22.login_attempts WHERE attempted_at < DATE_SUB(NOW(), INTERVAL 1 MONTH);"

# Nettoyer les tentatives d'inscription anciennes (> 1 mois)
mysql -u root -p -e "DELETE FROM TINDER22.registration_attempts WHERE attempted_at < DATE_SUB(NOW(), INTERVAL 1 MONTH);"

##############################################################################

echo "✅ Quick Reference chargée !"
echo "Consultez LOGIN_README.md pour plus de détails"
