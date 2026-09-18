# Checklist d'Installation et Validation

## Checklist d'Installation

### ✅ Prérequis
- [ ] PHP 8.0+ installé
- [ ] MySQL/MariaDB en fonctionnement
- [ ] MAMP (ou LAMP) démarré
- [ ] Base `TINDER22` créée
- [ ] Fichier `.env` configuré

### ✅ Étapes d'Installation

#### 1. Scripts SQL
```bash
# Exécuter les deux scripts
mysql -u root -p TINDER22 < sql/register_schema.sql
mysql -u root -p TINDER22 < sql/login_schema.sql
```

**Vérifier :**
```bash
# Colonnes USER
mysql -u root -p -e "DESC TINDER22.USER;" | grep -E "derniereConnexion|tentativesEchouees|bloqueJusqua"

# Tables
mysql -u root -p -e "SHOW TABLES FROM TINDER22;" | grep -E "login_attempts|registration_attempts"
```

#### 2. Fichiers PHP

Vérifier l'existence des fichiers :
```bash
# Backend
ls -la config/database.php
ls -la helpers/JwtHelper.php
ls -la middlewares/authMiddleware.php
ls -la models/UserModel.php
ls -la controllers/AuthController.php
ls -la routes/auth.php
ls -la api/index.php

# Frontend
ls -la public/connexion.html
ls -la public/js/connexion.js
ls -la public/js/auth-guard.js
ls -la public/home.html
```

#### 3. Permissions

```bash
# Uploads : permissions de lecture/écriture
chmod 755 uploads/
chmod 644 uploads/.htaccess

# Logs : lisibles par PHP
chmod 755 logs/ || mkdir logs && chmod 755 logs/
```

#### 4. .env

```env
# Vérifier les clés essentielles :
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_DATABASE=TINDER22
JWT_SECRET=votre-clé-secrète
APP_DEBUG=true
```

---

## Validation du Backend

### Test 1 : Connexion à la Base

```bash
# Terminal
php -r "
require 'config/database.php';
\$db = Database::getInstance();
echo 'Connexion OK';
" 2>&1
```

**Résultat attendu :** "Connexion OK"  
**Erreur fréquente :** `PDOException: SQLSTATE[28000]` → vérifier user/password dans .env

---

### Test 2 : Existence de l'Utilisateur Test

```bash
mysql -u root -p -e "SELECT idUser, emailUser, age FROM TINDER22.USER LIMIT 1;"
```

**Résultat attendu :**
```
idUser | emailUser | age
1      | test@tinder.local | 25
```

**Si vide :** Créer un utilisateur de test
```bash
mysql -u root -p TINDER22 << EOF
INSERT INTO GENRE (libGenr) VALUES ('Homme'), ('Femme'), ('Non-binaire');
INSERT INTO USER (idGenr, nomEUser, prenomUser, age, emailUser, mdpUser)
VALUES (1, 'Test', 'User', 25, 'test@tinder.local', '\$(php -r "echo password_hash('TestPassword123!', PASSWORD_DEFAULT);")');
EOF
```

---

### Test 3 : Endpoint POST /api/login

```bash
# Via curl
curl -i -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{"emailUser":"test@tinder.local","mdpUser":"TestPassword123!"}'
```

**Résultat attendu :**
- **Code HTTP :** 200
- **Réponse :** JSON avec `"success": true` et un champ `"token"`

**Erreurs courantes :**
- **404 :** Vérifier que `api/index.php` existe et que la route est déclarée
- **500 :** Vérifier les logs PHP (`error_log`)
- **400 :** Champs manquants ou JSON malformé
- **401 :** Identifiants incorrects ou utilisateur inexistant

---

### Test 4 : Endpoint GET /api/me (avec token valide)

```bash
# Remplacer TOKEN par le token reçu dans le test 3
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -i -X GET 'http://localhost/TINDER22/api/me' \
  -H "Authorization: Bearer $TOKEN"
```

**Résultat attendu :**
- **Code HTTP :** 200
- **Réponse :** JSON avec les infos utilisateur (sans mot de passe)

**Erreurs courantes :**
- **401 :** Token invalide, expiré ou mal formaté
- **500 :** Vérifier la valeur de `JWT_SECRET` dans `.env`

---

## Validation du Frontend

### Test 5 : Page de Connexion

```bash
# Ouvrir dans le navigateur
http://localhost/TINDER22/public/connexion.html
```

**Vérifications :**
- [ ] Page charge correctement (HTML + CSS)
- [ ] Formulaire affichage : email, mot de passe, case "Se souvenir"
- [ ] Bouton toggle du mot de passe fonctionne
- [ ] Aucune erreur dans la console (F12 > Console)

**Console DevTools :**
```javascript
// Vérifier que les éléments existent
console.log(document.getElementById('loginForm')); // Doit retourner l'élément
```

---

### Test 6 : Connexion Réussie

1. Remplir le formulaire :
   - Email : `test@tinder.local`
   - Mot de passe : `TestPassword123!`
   - Cocher "Se souvenir de moi"

2. Cliquer sur "Se connecter"

**Comportement attendu :**
- [ ] Spinner s'affiche (brève animation)
- [ ] Bouton se désactive temporairement
- [ ] Message "Connexion réussie, redirection..." (2 sec)
- [ ] Redirection automatique vers `home.html`

**Vérifier le stockage du token :**
```javascript
// Console du navigateur (F12)
localStorage.getItem('auth_token')
// Doit retourner un token JWT (format : xxx.yyy.zzz)
```

---

### Test 7 : Page Protégée (home.html)

1. Après redirection depuis connexion.html

**Comportement attendu :**
- [ ] Page home.html se charge
- [ ] Message "Bienvenue, User !" s'affiche
- [ ] Infos utilisateur visibles (Email, Âge, etc.)

2. Tenter d'accéder directement sans token :
```bash
# Supprimer le token et recharger
# Dans la console :
localStorage.removeItem('auth_token');
// Puis F5 pour recharger
```

**Résultat attendu :**
- Redirection automatique vers `connexion.html`

---

### Test 8 : Déconnexion

1. Sur la page home.html, cliquer sur "Déconnexion"

**Résultat attendu :**
- [ ] Token supprimé du localStorage
- [ ] Redirection vers connexion.html

**Vérifier :**
```javascript
localStorage.getItem('auth_token')
// Doit retourner null
```

---

## Validation de la Sécurité

### Test 9 : Message d'Erreur Générique

1. Connexion avec email valide + mot de passe faux

**Résultat attendu :**
- Message : "Email ou mot de passe incorrect" (pas "Email inconnu")

2. Connexion avec email inexistant

**Résultat attendu :**
- Message identique : "Email ou mot de passe incorrect"

---

### Test 10 : Blocage après 5 tentatives

1. Faire 5 tentatives avec mot de passe faux
2. À la 6e tentative

**Résultat attendu :**
- **Code HTTP :** 423 Locked
- **Message :** "Compte bloqué. Réessayez dans X minute(s)"

**Vérifier en base :**
```bash
mysql -u root -p -e "SELECT bloqueJusqua FROM TINDER22.USER WHERE emailUser='test@tinder.local';"
# Doit afficher un timestamp dans les 15 prochaines minutes
```

---

### Test 11 : Rate-Limit par IP

1. Faire 10 requêtes de connexion échouées (depuis la même IP/machine)

**Résultat attendu :**
- À partir de la 11e : **Code HTTP 429 Too Many Requests**

```bash
# Vérifier la table login_attempts
mysql -u root -p -e "SELECT COUNT(*) FROM TINDER22.login_attempts WHERE ip='127.0.0.1' AND attempted_at >= NOW() - INTERVAL 1 HOUR;"
# Doit afficher ≥ 11
```

---

### Test 12 : JWT Signature

1. Récupérer un token valide
2. Modifier le token (changer un caractère)
3. Tenter GET /api/me avec le token modifié

```bash
# Token original
TOKEN="eyJ...aaa.bbbb.cccc"

# Token modifié
FAKE_TOKEN="eyJ...aaa.bbbb.ccdd"  # Derniers chiffres modifiés

curl -X GET 'http://localhost/TINDER22/api/me' \
  -H "Authorization: Bearer $FAKE_TOKEN"
```

**Résultat attendu :**
- **Code HTTP :** 401
- **Message :** "Authentification requise"

---

## Logs et Débogage

### Où Vérifier les Erreurs

#### PHP Error Log
```bash
# MAMP sur macOS
tail -f /Applications/MAMP/logs/php_error.log

# Linux
tail -f /var/log/php-fpm.log

# Windows
Check MAMP/logs/php_error.log
```

#### Logs Applicatifs
```php
// Ajouter dans le code
error_log("Debug: " . json_encode($var));

// Puis vérifier
grep "Debug:" /Applications/MAMP/logs/php_error.log
```

#### Console du Navigateur (F12)
```javascript
// Erreurs JavaScript
console.error('Erreur réseau :', err);

// Affichage du token
console.log('Token :', localStorage.getItem('auth_token'));

// Logs fetch
fetch('/api/login').then(r => console.log('Status:', r.status));
```

---

## Problèmes Fréquents et Solutions

### ❌ "Token invalide" après connexion réussie

**Cause probable :** `JWT_SECRET` n'existe pas ou mismatch  
**Solution :**
```env
# Dans .env, ajouter
JWT_SECRET=dev-secret-change-en-production
```

Puis supprimer le token ancien et se reconnecter.

---

### ❌ "Email ou mot de passe incorrect" même avec les bons identifiants

**Cause probable :** Utilisateur test inexistant ou mot de passe non hashé  
**Solution :**
```bash
# Vérifier l'existence
mysql -u root -p -e "SELECT emailUser, mdpUser FROM TINDER22.USER WHERE emailUser='test@tinder.local';"

# Re-créer si nécessaire avec hash correct
mysql -u root -p TINDER22 << EOF
DELETE FROM USER WHERE emailUser='test@tinder.local';
INSERT INTO USER (idGenr, nomEUser, prenomUser, age, emailUser, mdpUser)
VALUES (1, 'Test', 'User', 25, 'test@tinder.local', '\$(php -r "echo password_hash('TestPassword123!', PASSWORD_DEFAULT);")');
EOF
```

---

### ❌ "404 Not Found" sur /api/login

**Cause probable :** `api/index.php` n'existe pas ou route non déclarée  
**Solution :**
```bash
# Vérifier les fichiers
ls -la api/index.php
ls -la routes/auth.php

# Vérifier la route dans routes/auth.php
grep "handleAuthRoutes" routes/auth.php

# Vérifier que api/index.php inclut les routes
grep "routes/auth.php" api/index.php
```

---

### ❌ Redirection infinito entre connexion.html et home.html

**Cause probable :** Token valide mais GET /api/me retourne une erreur  
**Solution :**
```javascript
// Dans console du navigateur
fetch('/api/me', {
    headers: {'Authorization': 'Bearer ' + localStorage.getItem('auth_token')}
})
.then(r => console.log('Status:', r.status, r.json()))
.catch(e => console.error(e));
```

Vérifier la réponse. Si 500, consulter les logs PHP.

---

### ❌ localStorage vide après F5

**Cause probable :** localStorage est vide (normal après suppression)  
**Comportement attendu :** Redirection vers connexion.html  
**Solution :** Accepter que auth-guard.js redirige si pas de token

---

## Validation Complète (Checklist)

| Étape | Test | Résultat | Status |
|-------|------|---------|--------|
| 1 | SQL scripts exécutés | Tables + colonnes présentes | ✅ |
| 2 | Fichiers PHP existent | Tous les fichiers trouvés | ✅ |
| 3 | POST /api/login (succès) | Code 200 + token | ✅ |
| 4 | GET /api/me (valide) | Code 200 + infos user | ✅ |
| 5 | POST /api/login (fail) | Code 401 + msg générique | ✅ |
| 6 | GET /api/me (invalide) | Code 401 | ✅ |
| 7 | connexion.html charge | Form + JS ok | ✅ |
| 8 | Login réussi (browser) | Redirection + token | ✅ |
| 9 | home.html protégée | Auth-guard valide | ✅ |
| 10 | Déconnexion | Token supprimé | ✅ |
| 11 | Blocage 5 tentatives | Code 423 | ✅ |
| 12 | Rate-limit IP | Code 429 après 10 | ✅ |
| 13 | JWT signature | Invalid token → 401 | ✅ |

---

## Support

**Questions fréquentes :**

**Q : Comment utiliser httpOnly cookie au lieu de localStorage ?**
A : Voir [ARCHITECTURE_LOGIN.md](ARCHITECTURE_LOGIN.md#httponly-cookie-recommandé-en-production)

**Q : Comment ajouter un refresh token ?**
A : Voir [ARCHITECTURE_LOGIN.md](ARCHITECTURE_LOGIN.md#token-refresh)

**Q : Comment implémenter la blacklist de tokens ?**
A : Voir [ARCHITECTURE_LOGIN.md](ARCHITECTURE_LOGIN.md#blacklist-de-tokens)

---

**Document créé :** 2026-09-18  
**Dernière mise à jour :** 2026-09-18
