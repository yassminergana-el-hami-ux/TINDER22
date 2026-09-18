# Parcours de Connexion - Module Login

## Installation

### 1. Exécuter le script SQL

```bash
mysql -u root -p TINDER22 < sql/login_schema.sql
```

Cela ajoute les colonnes manquantes à la table `USER` et crée la table `login_attempts`.

### 2. Configuration .env

Assurez-vous que votre fichier `.env` contient :
```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=root
DB_DATABASE=TINDER22
JWT_SECRET=votre-clé-secrète-très-forte-en-production
APP_DEBUG=true
```

La clé JWT_SECRET est optionnelle ; le code utilise une clé de développement par défaut.

### 3. Accéder à la page

- Page de connexion : `http://localhost/TINDER22/public/connexion.html`
- Page d'accueil (protégée) : `http://localhost/TINDER22/public/home.html`

---

## Endpoints API

### POST /api/login

Connecte un utilisateur et retourne un token JWT.

**Requête :**
```json
{
  "emailUser": "jean.dupont@mail.fr",
  "mdpUser": "MotDePasse123!",
  "rememberMe": false
}
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "idUser": 1,
    "prenomUser": "Jean",
    "nomEUser": "Dupont",
    "emailUser": "jean.dupont@mail.fr",
    "photo": null,
    "age": 25,
    "idGenr": 1,
    "biographie": "..."
  }
}
```

**Réponses d'erreur :**
- `400` : Champs manquants
- `401` : Email ou mot de passe incorrect (message générique)
- `423` : Compte bloqué temporairement (après 5 tentatives échouées)
- `429` : Trop de tentatives par IP (max 10/heure)
- `500` : Erreur serveur

### POST /api/logout

Déconnecte l'utilisateur (côté client : supprimer le token).

**Requête :**
```
Authorization: Bearer <token>
```

**Réponse (200) :**
```json
{
  "success": true,
  "message": "Déconnexion réussie"
}
```

### GET /api/me

Récupère les infos de l'utilisateur actuellement connecté.

**Requête :**
```
Authorization: Bearer <token>
```

**Réponse (200) :**
```json
{
  "success": true,
  "data": {
    "idUser": 1,
    "prenomUser": "Jean",
    "nomEUser": "Dupont",
    "emailUser": "jean.dupont@mail.fr",
    "photo": null,
    "age": 25,
    "idGenr": 1,
    "biographie": "..."
  }
}
```

**Réponses d'erreur :**
- `401` : Token invalide ou absent

---

## Exemples de Test cURL

### 1. Connexion réussie

```bash
curl -i -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser":"jean.dupont@mail.fr",
    "mdpUser":"MotDePasse123!",
    "rememberMe":false
  }'
```

Réponse attendue : **200** avec le token

### 2. Identifiants incorrects (mot de passe faux)

```bash
curl -i -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser":"jean.dupont@mail.fr",
    "mdpUser":"MauvaisMdp123!",
    "rememberMe":false
  }'
```

Réponse attendue : **401** avec message "Email ou mot de passe incorrect"

Le compteur `tentativesEchouees` est incrémenté.

### 3. Bloquer un compte (5 tentatives échouées)

Exécutez 5 fois le curl ci-dessus (identifiants incorrects). À la 5e tentative :

Réponse : **401** "Email ou mot de passe incorrect"

La colonne `bloqueJusqua` est définie à `NOW() + 15 MINUTES`

### 4. Essayer de se connecter avec un compte bloqué

```bash
curl -i -X POST 'http://localhost/TINDER22/api/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "emailUser":"jean.dupont@mail.fr",
    "mdpUser":"MotDePasse123!",
    "rememberMe":false
  }'
```

Réponse attendue : **423** Locked
```json
{
  "success": false,
  "message": "Compte bloqué",
  "minutesRestantes": 14
}
```

### 5. Vérifier l'utilisateur connecté (GET /api/me)

Après une connexion réussie :

```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
curl -i -X GET 'http://localhost/TINDER22/api/me' \
  -H "Authorization: Bearer $TOKEN"
```

Réponse attendue : **200** avec les infos utilisateur

### 6. Token invalide ou expiré

```bash
curl -i -X GET 'http://localhost/TINDER22/api/me' \
  -H 'Authorization: Bearer invalid-token'
```

Réponse attendue : **401** "Authentification requise"

---

## Stockage du Token (Client)

### localStorage (démo simple, moins sécurisé)

```javascript
// Stocker
localStorage.setItem('auth_token', token);

// Récupérer
const token = localStorage.getItem('auth_token');

// Supprimer
localStorage.removeItem('auth_token');
```

**Avantage :** Simple, persiste entre les sessions  
**Inconvénient :** Vulnérable aux attaques XSS

### httpOnly Cookie (recommandé en production)

Le serveur envoie le token dans un cookie httpOnly :
```php
setcookie('auth_token', $token, [
    'expires' => time() + 3600,
    'path' => '/',
    'httponly' => true,
    'secure' => true, // HTTPS uniquement
    'samesite' => 'Strict',
]);
```

Le navigateur envoie automatiquement le cookie. Nécessite une légère modification du front-end.

---

## Sécurité

### Points implémentés

✅ Requêtes préparées (PDO) — aucune injection SQL  
✅ Vérification du mot de passe avec `password_verify()` — jamais de comparaison directe  
✅ Message d'erreur générique "Email ou mot de passe incorrect" — pas d'énumération d'utilisateurs  
✅ Blocage après 5 tentatives échouées (15 minutes)  
✅ Rate-limit par IP (max 10 tentatives/heure)  
✅ Token JWT signé avec clé secrète (expiration : 2h ou 30j si "remember me")  
✅ Middleware pour protéger les routes authentifiées  

### À faire en production

⚠️ **HTTPS obligatoire** — pour protéger le token en transit  
⚠️ **Clé JWT forte** — stocker `JWT_SECRET` en variable d'environnement sécurisée  
⚠️ **httpOnly Cookie** — au lieu de localStorage  
⚠️ **Refresh Token** — pour renouveler les tokens expirés sans redemander identifiants  
⚠️ **Token Blacklist** — si besoin de révoquer un token avant expiration  

---

## Fichiers Modifiés/Créés

### Backend
- `sql/login_schema.sql` — Script SQL
- `config/database.php` — Singleton PDO (existant)
- `models/UserModel.php` — Nouvelles méthodes (findByEmail, etc.)
- `helpers/JwtHelper.php` — Gestion des tokens JWT
- `middlewares/authMiddleware.php` — Middleware d'authentification
- `controllers/AuthController.php` — Méthodes login(), logout(), me()
- `routes/auth.php` — Routes POST /api/login, POST /api/logout, GET /api/me

### Frontend
- `public/connexion.html` — Page de connexion
- `public/js/connexion.js` — Logique de connexion
- `public/js/auth-guard.js` — Protecteur de pages authentifiées
- `public/home.html` — Exemple de page protégée

---

## Notes Techniques

### JWT vs Sessions

**Choix fait : JWT (JSON Web Token) stateless**

**Avantages :**
- Pas de stockage serveur → scalabilité
- Valide partout (multi-serveur, micro-services)
- Expiration intégrée

**Inconvénients :**
- Impossible de révoquer immédiatement (sauf blacklist)

**Alternative : Sessions PHP**
Si vous préférez les sessions, remplacer le code JWT par :
```php
if (session_status() === PHP_SESSION_NONE) session_start();
$_SESSION['user_id'] = $user['idUser'];
```

### "Remember Me"

Avec JWT : on prolonge l'expiration à 30 jours au lieu de 2h.  
Avec sessions : on peut définir `session.cookie_lifetime`.

---

## Troubleshooting

### "Erreur de connexion" au login

1. Vérifier `.env` (DB_HOST, credentials)
2. Vérifier que le script SQL a été exécuté
3. Vérifier que l'utilisateur existe dans `USER`
4. Consulter les logs PHP : `error_log('...')`

### Token expiré immédiatement

Vérifier que `JWT_SECRET` est cohérente entre génération et validation.

### CORS error

Vérifier les en-têtes CORS dans `api/index.php`.

---

## Prochaines étapes

- Implémenter "Mot de passe oublié" (reset token par email)
- Implémenter les Likes
- Implémenter les Matchs
- Implémenter les Commentaires
- Implémenter la modification du profil
