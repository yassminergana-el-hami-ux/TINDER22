# Architecture du Module de Connexion

## Vue d'ensemble

Le parcours de connexion implémente une architecture classique :

```
┌─────────────────┐
│  connexion.html │  (Form + JS fetch)
└────────┬────────┘
         │
         │ POST /api/login (JSON)
         ↓
┌────────────────────────────────┐
│ api/index.php (Router)         │
└────────┬───────────────────────┘
         │
         ↓ routes/auth.php
┌────────────────────────────────────────┐
│ AuthController::login()                │
├────────────────────────────────────────┤
│ 1. Vérifier champs requis (400)        │
│ 2. Rate-limit par IP (429)             │
│ 3. Chercher utilisateur (findByEmail) │
│ 4. Vérifier compte bloqué (423)       │
│ 5. Vérifier mot de passe (401)        │
│ 6. Générer JWT via JwtHelper          │
│ 7. Mettre à jour BDD (derniereConnexion)
│ 8. Retourner token + user infos (200)│
└────────────────────────────────────────┘
         │
         │ Response JSON + JWT
         ↓
┌─────────────────┐
│  connexion.js   │
│ - Stocke token  │
│ - Redirige      │
└─────────────────┘
         │
         │ Redirection
         ↓
┌────────────────────────┐
│  home.html             │  (Page protégée)
│ + auth-guard.js        │
└────────┬───────────────┘
         │
         │ GET /api/me (avec Bearer token)
         ↓
┌────────────────────────────────────────┐
│ AuthMiddleware::authenticate()         │
│ - Extrait token du header              │
│ - Valide signature JWT                 │
│ - Vérifie expiration                   │
└────────┬───────────────────────────────┘
         │
         ├─ Valide ? → Attacher user global
         │
         └─ Invalide ? → 401 + redirection connexion.html
```

## Flux de Données

### 1. Enregistrement du Token

**Client (connexion.js) :**
```javascript
// Après réception du token
localStorage.setItem('auth_token', token);
```

**Production :** httpOnly cookie (plus sécurisé)

### 2. Envoi du Token aux Requêtes Protégées

**Client (auth-guard.js) :**
```javascript
const token = localStorage.getItem('auth_token');
fetch('/api/me', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
});
```

**Serveur (AuthMiddleware) :**
```php
// Extraction du header
$header = $_SERVER['HTTP_AUTHORIZATION']; // "Bearer xxx.yyy.zzz"
// Validation du JWT
$payload = $jwt->decode($token);
```

### 3. Exécution de Route Protégée

```php
// Dans routes/auth.php
if (preg_match('#/api/me$#', $path)) {
    $auth = new AuthMiddleware();
    if (!$auth->handle()) {  // Retourne 401 si invalide
        return true;
    }
    // Continuer avec la route
    $controller->me();
}
```

## Sécurité Détaillée

### Anti-Brute-Force

**Par compte (UserModel) :**
- Compteur `tentativesEchouees` incrémenté à chaque échec
- À 5 tentatives → blocage 15 min (colonne `bloqueJusqua`)
- Réinitialisation à 0 après succès

**Par IP (globale) :**
- Table `login_attempts` enregistre chaque tentative
- Query pour compter tentatives de l'IP dans la dernière heure
- 429 Too Many Requests si ≥ 10 tentatives

**Points gérés :**
- `tentativesEchouees` compte uniquement les échecs du compte
- `login_attempts` compte TOUS les essais de toutes les IP
- Blocage 15 min se réinitialise automatiquement via colonne DATETIME

### Message d'Erreur Générique

```php
// Email inexistant
→ "Email ou mot de passe incorrect"

// Mot de passe faux
→ "Email ou mot de passe incorrect"

// Compte bloqué
→ Code 423 + message "Compte bloqué"
```

**Raison :** Empêcher l'énumération d'utilisateurs (Security 101)

### Signature JWT

```
Token = Base64(header) . Base64(payload) . HMAC-SHA256(header.payload, secret)
```

**Validation :**
1. Décodage de header + payload
2. Recalcul de HMAC avec la clé secrète
3. Comparaison avec la signature (hash_equals pour timing attack)
4. Vérification de l'expiration (`exp` vs `time()`)

## État de la Base de Données

### Colonnes USER

| Colonne | Type | Rôle |
|---------|------|------|
| `tentativesEchouees` | INT DEFAULT 0 | Compteur d'échecs avant blocage |
| `bloqueJusqua` | DATETIME NULL | Timestamp du déblocage automatique |
| `derniereConnexion` | DATETIME NULL | Audit + stats |

### Table login_attempts

| Colonne | Type | Rôle |
|---------|------|------|
| `ip` | VARCHAR(45) | Adresse IP du client |
| `attempted_at` | DATETIME | Horodatage de la tentative |

**Index :** `(ip, attempted_at)` pour les requêtes rapides

## Prise en Main du Frontend

### Accès aux Pages

1. **Connexion :** `public/connexion.html`
   - Déjà connecté ? → Redirection auto vers `home.html`
   - Sinon → Formulaire

2. **Home (protégée) :** `public/home.html`
   - Inclut `auth-guard.js` en premier
   - Guard verifie token via GET /api/me
   - Pas de token ? → Redirection vers connexion.html
   - Token valide ? → Affichage + événement `userLoaded`

### Stockage du Token

```javascript
// Stockage (connexion.js)
localStorage.setItem('auth_token', token);

// Récupération (auth-guard.js, connexion.js)
const token = localStorage.getItem('auth_token');

// Suppression (logout)
localStorage.removeItem('auth_token');
```

### Déconnexion

```javascript
// Supprimer le token localement
localStorage.removeItem('auth_token');

// Optionnel : appeler POST /api/logout (aucun effet côté serveur, JWT stateless)
// S'il y a une blacklist, le serveur peut l'utiliser

// Redirection
window.location.href = 'connexion.html';
```

## Rate-Limit Avancé

### Scénarios Gérés

1. **IP A essaie 10 fois/heure** → 429 (bloquée globalement)
2. **Compte USER X échoue 5 fois** → Bloqué 15 min
3. **IP A réussit la connexion** → Compte remis à 0, déblocage immédiat
4. **Compte USER X attendait 15 min** → Déblocage auto au prochain essai

### SQL Utilisé

```sql
-- Compter tentatives de l'IP dans la dernière heure
SELECT COUNT(*) FROM login_attempts 
WHERE ip = ? AND attempted_at >= NOW() - INTERVAL 1 HOUR

-- Vérifier le blocage du compte
SELECT bloqueJusqua FROM USER 
WHERE idUser = ? AND bloqueJusqua > NOW()

-- Débloquer le compte
UPDATE USER SET bloqueJusqua = NULL WHERE idUser = ?
```

## Configuration en Production

### .env

```env
DB_HOST=db.prod.internal
DB_USER=app_user
DB_PASSWORD=<very-strong-password>
DB_DATABASE=TINDER22

JWT_SECRET=<very-long-random-string-256-bits>

APP_DEBUG=false

# Optionnel
SESSION_LIFETIME=86400
```

### PHP

```php
// Force HTTPS
header('Strict-Transport-Security: max-age=31536000; includeSubDomains');

// CORS
header('Access-Control-Allow-Origin: https://domaine.com');

// httpOnly cookie
setcookie('auth_token', $token, [
    'expires' => time() + 3600,
    'path' => '/',
    'httponly' => true,  // JS ne peut pas accéder
    'secure' => true,    // HTTPS uniquement
    'samesite' => 'Strict',
]);
```

### Nginx

```nginx
server {
    listen 443 ssl http2;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Redirection HTTP → HTTPS
    location / {
        proxy_pass http://php-fpm;
    }
}
```

## Tests Automatisés

Voir [test_login.sh](test_login.sh) pour :
- Création d'utilisateur test
- Connexion réussie
- Vérification du token
- Tentatives échouées
- Blocage du compte
- Token invalide

```bash
bash test_login.sh
```

## Évolution Future

### Token Refresh

```
GET /api/refresh
Body : { "refreshToken": "..." }
Response : { "token": "...", "refreshToken": "..." }
```

### Blacklist de Tokens

```sql
CREATE TABLE token_blacklist (
    jti VARCHAR(255) PRIMARY KEY,  -- JWT ID unique
    revoked_at DATETIME
);
```

### Authentification Multifacteur

```
POST /api/login → Envoyer OTP
POST /api/verify-otp → Valider + retourner token
```

### Social Login

```
POST /api/oauth/google
Body : { "idToken": "..." }
```

---

**Auteur :** Architecture pour Tinder Clone  
**Date :** 2026-09-18  
**Stack :** PHP 8 + PDO + JWT (stateless)
