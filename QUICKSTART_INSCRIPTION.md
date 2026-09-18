# ⚡ Quick Start - Créer un Compte

## 5 minutes pour être prêt!

### 1️⃣ Exécuter le SQL (1 minute)
```bash
mysql -u root -p TINDER22 < BDD/register_schema.sql
```

### 2️⃣ Ajouter les genres (30 secondes)
```bash
mysql -u root -p TINDER22
```
```sql
INSERT INTO GENRE (libGenr) VALUES ('Homme'), ('Femme'), ('Non-binaire'), ('Autre');
EXIT;
```

### 3️⃣ Vérifier (30 secondes)
```bash
mysql -u root -p TINDER22
```
```sql
DESCRIBE USER;
-- Vérifier: emailUser, mdpUser, dateInscription
SELECT * FROM GENRE;
-- Vérifier: au moins 1 genre
EXIT;
```

### 4️⃣ Ouvrir le formulaire (10 secondes)
```
http://localhost/TINDER22/views/backend/users/create.php
```

### 5️⃣ Tester avec ces données (1 minute)
```
Prénom:       Yassmine
Nom:          Rgana
Naissance:    2007-08-15
Genre:        Femme (ou autre)
Email:        test@example.com
MDP:          SecurePass123!
Confirmation: SecurePass123!
```

## ✅ C'est bon!

Vous devriez voir: **"L'utilisateur a été créé avec succès"**

---

## 📁 Fichiers importants

| Fichier | But |
|---------|-----|
| `views/backend/users/create.php` | Formulaire + toute la logique |
| `BDD/register_schema.sql` | Colonnes de la BD |
| `INSCRIPTION_README.md` | Doc complète (500+ lignes) |
| `LIVRAISON_INSCRIPTION.md` | Synthèse (cette livraison) |

## 🧪 Tester les erreurs

```
❌ Email: "test@"              → Format invalide
❌ MDP: "Pass1"                → < 8 caractères
❌ MDP: "password123"          → Pas de majuscule
❌ Naissance: 2025-01-01       → Trop jeune
❌ Email: test@example.com     → Déjà utilisé (après premier test)
```

## 🔐 Sécurité garantie

✓ Mots de passe hashés (bcrypt)  
✓ Emails uniques  
✓ Protection SQL injection  
✓ Validation stricte  
✓ Échappement HTML  

## 📊 Vérifier les utilisateurs créés

```bash
mysql -u root -p TINDER22
```
```sql
SELECT idUser, prenomUser, nomEUser, emailUser, dateInscription FROM USER;
EXIT;
```

## 🧹 Nettoyer (après tests)

```bash
mysql -u root -p TINDER22
```
```sql
DELETE FROM USER WHERE emailUser = 'test@example.com';
ALTER TABLE USER AUTO_INCREMENT = 1;
EXIT;
```

---

**Besoin d'aide?** Consultez `INSCRIPTION_README.md` ou exécutez `bash TEST_INSCRIPTION.sh`
