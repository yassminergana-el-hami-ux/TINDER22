# 📝 Fonctionnalité Créer un Compte - Documentation Complète

## 📌 Vue d'ensemble

Cette fonctionnalité permet de créer un nouvel utilisateur de manière sécurisée avec validation complète côté serveur.

**Fichier principal :** [`views/backend/users/create.php`](views/backend/users/create.php)

## 🎯 Fonctionnalités implémentées

### ✅ Champs du formulaire
- **Prénom** (obligatoire) : 2-50 caractères
- **Nom** (obligatoire) : 2-50 caractères
- **Date de naissance** (obligatoire) : calcul automatique de l'âge
- **Genre** (obligatoire) : liste déroulante depuis la BD
- **Email** (obligatoire) : validation format + unicité
- **Mot de passe** (obligatoire) : règles de sécurité strictes
- **Confirmation MDP** (obligatoire) : doit correspondre au MDP
- **Ville** (optionnel) : 0-50 caractères
- **Biographie** (optionnel) : 0-150 caractères

### ✅ Validations

#### Email
```php
✓ Format valide (RFC 5322)
✓ Pas déjà utilisé (unique en BD)
✓ Maximum 100 caractères
✓ Converti en minuscules
```

#### Mot de passe
```php
✓ Minimum 8 caractères
✓ Au moins 1 lettre majuscule (A-Z)
✓ Au moins 1 lettre minuscule (a-z)
✓ Au moins 1 chiffre (0-9)
```

#### Date de naissance
```php
✓ Format valide (YYYY-MM-DD)
✓ Pas dans le futur
✓ Age minimum 18 ans
✓ Age maximum 120 ans
```

#### Nom/Prénom
```php
✓ 2-50 caractères
✓ Caractères spéciaux autorisés : accents, tirets, apostrophes
✓ Caractères invalides rejetés
```

#### Genre
```php
✓ Doit exister en base de données
✓ Validation numérique (entier positif)
```

## 🔐 Sécurité

### Hachage du mot de passe
```php
// Utilise PASSWORD_DEFAULT (bcrypt)
// Coût: 10 (par défaut)
// Suffisant pour années à venir
$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
```

### Protection contre l'injection SQL
```php
// Préparation des requêtes avec named placeholders
$stmt = $db->prepare("INSERT INTO USER (...) VALUES (:field1, :field2)");
$stmt->execute([':field1' => $value1, ':field2' => $value2]);
```

### Échappement des données
```php
// Affichage sécurisé en HTML
<?php echo htmlspecialchars($userInput); ?>
```

### Nettoyage des données
```php
// Trim et validation
$input = trim($_POST['field']);
if (filter_var($input, FILTER_VALIDATE_EMAIL)) { ... }
```

## 📋 Processus de création

1. **Réception du formulaire** → `$_POST`
2. **Validation de chaque champ** → collecte des erreurs
3. **Vérifications supplémentaires** → email unique, genre existe
4. **Hachage du mot de passe** → `password_hash()`
5. **Insertion en BD** → prepared statement
6. **Feedback utilisateur** → message succès/erreur

## 🗄️ Base de données

### Table USER (colonnes ajoutées)
```sql
ALTER TABLE USER ADD COLUMN `emailUser` VARCHAR(100) NOT NULL UNIQUE;
ALTER TABLE USER ADD COLUMN `mdpUser` VARCHAR(255) NOT NULL;
ALTER TABLE USER ADD COLUMN `dateInscription` DATETIME DEFAULT CURRENT_TIMESTAMP;
```

### Structure complète de USER
```sql
CREATE TABLE USER (
    idUser INT AUTO_INCREMENT PRIMARY KEY,
    idGenr INT NOT NULL,                    -- FK vers GENRE
    emailUser VARCHAR(100) UNIQUE NOT NULL, -- Email unique
    mdpUser VARCHAR(255) NOT NULL,          -- Hash bcrypt (255 chars)
    nomEUser VARCHAR(50),
    prenomUser VARCHAR(50),
    dateInscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    age INT(8),
    biographie VARCHAR(150),
    photo VARCHAR(50),
    FOREIGN KEY (idGenr) REFERENCES GENRE(idGenr)
);
```

### Table GENRE (dropdown)
```sql
SELECT idGenr, libGenr FROM GENRE ORDER BY libGenr;
```

## 🚀 Installation & Configuration

### 1. Exécuter le script SQL
```bash
mysql -u root -p TINDER22 < BDD/register_schema.sql
```

### 2. Insérer des genres (si manquants)
```sql
INSERT INTO GENRE (libGenr) VALUES 
('Homme'),
('Femme'),
('Non-binaire'),
('Autre');
```

### 3. Accéder au formulaire
```
http://localhost/TINDER22/views/backend/users/create.php
```

## 📊 Codes de réponse

### ✅ Succès
- **201 Created** : Utilisateur créé (formulaire)
- Message : "L'utilisateur a été créé avec succès"

### ❌ Erreurs
- **400 Bad Request** : Validation échouée
- **409 Conflict** : Email déjà utilisé
- **500 Internal Server Error** : Erreur BD

## 🧪 Exemples de test

### Données valides
```
Prénom: Yassmine
Nom: Rgana
Date: 2007-08-15
Genre: Femme
Email: yassmine@example.com
MDP: SecurePass123
Confirmation: SecurePass123
Ville: Bordeaux
```

### Erreurs attendues
```
❌ Email invalide: "test@"
❌ MDP trop court: "Pass1" (< 8 caractères)
❌ MDP sans majuscule: "password123"
❌ MDP sans chiffre: "Password"
❌ Confirmations différentes
❌ Age < 18: date trop récente
❌ Email déjà utilisé
```

## 🛠️ Maintenance

### Vérifier les utilisateurs créés
```sql
SELECT idUser, prenomUser, nomEUser, emailUser, dateInscription 
FROM USER 
WHERE dateInscription >= DATE_SUB(NOW(), INTERVAL 1 DAY)
ORDER BY dateInscription DESC;
```

### Réinitialiser la table
```sql
DELETE FROM USER WHERE idGenr IS NOT NULL;
ALTER TABLE USER AUTO_INCREMENT = 1;
```

### Logs d'erreur
```php
// Activé via config/debug.php
error_log('Erreur création utilisateur: ' . $e->getMessage());
// Fichier: /Applications/MAMP/logs/php_error.log
```

## 📋 Checklist de sécurité

- ✅ Mots de passe hashés (bcrypt)
- ✅ Emails uniques en BD
- ✅ Préparation des requêtes SQL
- ✅ Échappement HTML (`htmlspecialchars`)
- ✅ Validation email (format + unicité)
- ✅ Validation MDP (8+ chars, maj, min, chiffre)
- ✅ Validation âge (18-120 ans)
- ✅ Limitation caractères (nom, bio, etc.)
- ✅ Messages d'erreur génériques (pas d'énumération d'users)
- ✅ Gestion des exceptions

## 📄 Structure du fichier

```php
1. Inclusion du header
2. Initialisation variables
3. Connexion BD (Database::getInstance())
4. Traitement POST (si soumis)
   4.1 Récupération des données
   4.2 Validation champs obligatoires
   4.3 Validation email
   4.4 Validation MDP
   4.5 Validation confirmation MDP
   4.6 Validation nom/prénom
   4.7 Validation date naissance
   4.8 Validation genre
   4.9 Validation optionnels (bio, ville)
   4.10 Insertion BD si valide
5. Récupération genres (dropdown)
6. Affichage du formulaire HTML
7. Affichage footer
```

## 💡 Points techniques clés

### Pourquoi PASSWORD_DEFAULT ?
```php
// Bcrypt, salé automatiquement, évolutif
password_hash($pwd, PASSWORD_DEFAULT);
// Peut changer en argon2id à l'avenir sans cassure
```

### Pourquoi prepared statements ?
```php
// Protège contre l'injection SQL
// Les paramètres sont traités séparément
$stmt = $db->prepare("SELECT * FROM USER WHERE email = ?");
$stmt->execute([$userInput]);
```

### Pourquoi hashé côté serveur ?
```php
// Jamais exposer le mot de passe en clair
// Le backend fait le hachage
// Le mot de passe ne voyage qu'en HTTPS (en production)
```

### Pourquoi validation stricte ?
```php
// Prévient spam/bots
// Assure données cohérentes
// Facilite maintenance
```

## 🔄 Workflow simplifié

```
Utilisateur soumet formulaire
    ↓
Serveur reçoit $_POST
    ↓
Validation champs obligatoires
    ↓
Validation email (format + unicité)
    ↓
Validation MDP (règles + confirmation)
    ↓
Validation autres champs
    ↓
Erreurs trouvées? OUI → Affiche formulaire avec erreurs
    ↓ NON
Hash du MDP avec bcrypt
    ↓
Insertion en BD
    ↓
Message succès → Formulaire vide
```

## 📞 Support & Troubleshooting

### Erreur: "Cette adresse email est déjà utilisée"
```php
// Chercher l'utilisateur existant
SELECT * FROM USER WHERE emailUser = 'test@example.com';
// Réinitialiser si test
DELETE FROM USER WHERE emailUser = 'test@example.com';
```

### Erreur: "Le genre sélectionné n'existe pas"
```php
// Vérifier les genres disponibles
SELECT * FROM GENRE;
// Ajouter si manquant
INSERT INTO GENRE (libGenr) VALUES ('Nouveau genre');
```

### Erreur: "Impossible de créer l'utilisateur"
```php
// Vérifier les logs
tail -f /Applications/MAMP/logs/php_error.log
// Vérifier les colonnes de USER
DESCRIBE USER;
// Vérifier les permissions
SHOW GRANTS FOR 'root'@'localhost';
```

### Le formulaire ne charge pas
```php
// Vérifier le chemin
// /TINDER22/views/backend/users/create.php
// Vérifier que header.php existe
// Vérifier que config.php charge bien config/database.php
```

## ✨ Améliorations futures

- [ ] Upload de photo de profil
- [ ] Vérification d'email (lien de confirmation)
- [ ] Intégration connexion automatique après inscription
- [ ] Rate-limiting per IP
- [ ] Captcha anti-spam
- [ ] Authentification par OAuth (Google, Facebook)
- [ ] Authentification 2FA
