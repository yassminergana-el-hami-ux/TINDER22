<?php
include '../../../header.php';

// ============================================================================
// GESTION DE LA CRÉATION D'UTILISATEUR - Back-end
// Formulaire d'inscription avec validation et sécurité
// ============================================================================

// Initialiser les variables
$errors = [];
$data = [];
$success = false;

// Récupérer la base de données
require_once '../../../config/database.php';

// ============================================================================
// TRAITEMENT DU FORMULAIRE SI SOUMIS
// ============================================================================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Récupérer les données du formulaire
    $input = [
        'prenomUser' => $_POST['prenomUser'] ?? '',
        'nomEUser' => $_POST['nomEUser'] ?? '',
        'dateNaissance' => $_POST['dateNaissance'] ?? '',
        'idGenr' => $_POST['idGenr'] ?? '',
        'emailUser' => $_POST['emailUser'] ?? '',
        'mdpUser' => $_POST['mdpUser'] ?? '',
        'mdpConfirmation' => $_POST['mdpConfirmation'] ?? '',
        'ville' => $_POST['ville'] ?? '',
        'biographie' => $_POST['biographie'] ?? '',
    ];

    // ========================================================================
    // 1. VÉRIFIER LES CHAMPS OBLIGATOIRES
    // ========================================================================
    $required = ['prenomUser', 'nomEUser', 'dateNaissance', 'idGenr', 'emailUser', 'mdpUser', 'mdpConfirmation'];
    foreach ($required as $field) {
        if (empty(trim($input[$field]))) {
            $errors[$field] = 'Ce champ est obligatoire';
        }
    }

    // ========================================================================
    // 2. VALIDER L'EMAIL
    // ========================================================================
    if (!isset($errors['emailUser']) && !empty($input['emailUser'])) {
        $email = mb_strtolower(trim($input['emailUser']));
        
        // Format
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors['emailUser'] = 'L\'adresse email n\'est pas valide';
        } elseif (mb_strlen($email) > 100) {
            $errors['emailUser'] = 'L\'adresse email est trop longue';
        } else {
            // Vérifier que l'email n'existe pas déjà
            $db = Database::getInstance();
            $sql = "SELECT 1 FROM `USER` WHERE emailUser = :email LIMIT 1";
            $stmt = $db->prepare($sql);
            $stmt->execute([':email' => $email]);
            
            if ($stmt->fetchColumn()) {
                $errors['emailUser'] = 'Cette adresse email est déjà utilisée';
            } else {
                $data['emailUser'] = $email;
            }
        }
    }

    // ========================================================================
    // 3. VALIDER LE MOT DE PASSE
    // ========================================================================
    if (!isset($errors['mdpUser']) && !empty($input['mdpUser'])) {
        $pwd = $input['mdpUser'];
        
        if (mb_strlen($pwd) < 8) {
            $errors['mdpUser'] = 'Le mot de passe doit contenir au moins 8 caractères';
        } elseif (!preg_match('/[A-Z]/', $pwd)) {
            $errors['mdpUser'] = 'Le mot de passe doit contenir au moins une lettre majuscule';
        } elseif (!preg_match('/[a-z]/', $pwd)) {
            $errors['mdpUser'] = 'Le mot de passe doit contenir au moins une lettre minuscule';
        } elseif (!preg_match('/[0-9]/', $pwd)) {
            $errors['mdpUser'] = 'Le mot de passe doit contenir au moins un chiffre';
        } else {
            $data['mdpUser'] = $pwd;
        }
    }

    // ========================================================================
    // 4. VÉRIFIER LA CONFIRMATION DU MOT DE PASSE
    // ========================================================================
    if (!isset($errors['mdpConfirmation']) && isset($data['mdpUser']) && !empty($input['mdpConfirmation'])) {
        if ($input['mdpConfirmation'] !== $data['mdpUser']) {
            $errors['mdpConfirmation'] = 'La confirmation ne correspond pas au mot de passe';
        }
    }

    // ========================================================================
    // 5. VALIDER LE NOM ET LE PRÉNOM
    // ========================================================================
    $namePattern = '/^[\p{L}\s\'-]{2,50}$/u';
    
    if (!isset($errors['prenomUser']) && !empty($input['prenomUser'])) {
        $prenom = trim($input['prenomUser']);
        if (mb_strlen($prenom) < 2 || mb_strlen($prenom) > 50) {
            $errors['prenomUser'] = 'Le prénom doit contenir entre 2 et 50 caractères';
        } elseif (!preg_match($namePattern, $prenom)) {
            $errors['prenomUser'] = 'Le prénom contient des caractères invalides';
        } else {
            $data['prenomUser'] = $prenom;
        }
    }

    if (!isset($errors['nomEUser']) && !empty($input['nomEUser'])) {
        $nom = trim($input['nomEUser']);
        if (mb_strlen($nom) < 2 || mb_strlen($nom) > 50) {
            $errors['nomEUser'] = 'Le nom doit contenir entre 2 et 50 caractères';
        } elseif (!preg_match($namePattern, $nom)) {
            $errors['nomEUser'] = 'Le nom contient des caractères invalides';
        } else {
            $data['nomEUser'] = $nom;
        }
    }

    // ========================================================================
    // 6. VALIDER LA DATE DE NAISSANCE ET CALCULER L'ÂGE
    // ========================================================================
    if (!isset($errors['dateNaissance']) && !empty($input['dateNaissance'])) {
        $dateStr = $input['dateNaissance'];
        $d = DateTime::createFromFormat('Y-m-d', $dateStr);
        $now = new DateTime();
        
        if (!$d || $d > $now) {
            $errors['dateNaissance'] = 'La date de naissance n\'est pas valide';
        } else {
            $age = $d->diff($now)->y;
            if ($age < 18) {
                $errors['dateNaissance'] = 'Vous devez être majeur (18 ans minimum)';
            } elseif ($age > 120) {
                $errors['dateNaissance'] = 'L\'âge semble invalide';
            } else {
                $data['age'] = $age;
            }
        }
    }

    // ========================================================================
    // 7. VALIDER LE GENRE
    // ========================================================================
    if (!isset($errors['idGenr']) && !empty($input['idGenr'])) {
        $idGenr = filter_var($input['idGenr'], FILTER_VALIDATE_INT);
        
        if ($idGenr === false) {
            $errors['idGenr'] = 'Le genre n\'est pas valide';
        } else {
            $db = Database::getInstance();
            $sql = "SELECT 1 FROM `GENRE` WHERE idGenr = :idGenr LIMIT 1";
            $stmt = $db->prepare($sql);
            $stmt->execute([':idGenr' => $idGenr]);
            
            if (!$stmt->fetchColumn()) {
                $errors['idGenr'] = 'Le genre sélectionné n\'existe pas';
            } else {
                $data['idGenr'] = $idGenr;
            }
        }
    }

    // ========================================================================
    // 8. VALIDER LA BIOGRAPHIE (OPTIONNELLE)
    // ========================================================================
    if (isset($input['biographie']) && !empty(trim($input['biographie']))) {
        $bio = trim($input['biographie']);
        if (mb_strlen($bio) > 150) {
            $errors['biographie'] = 'La biographie ne doit pas dépasser 150 caractères';
        } else {
            $data['biographie'] = $bio;
        }
    } else {
        $data['biographie'] = null;
    }

    // ========================================================================
    // 9. VALIDER LA VILLE (OPTIONNELLE)
    // ========================================================================
    if (isset($input['ville']) && !empty(trim($input['ville']))) {
        $ville = trim($input['ville']);
        if (mb_strlen($ville) > 50) {
            $errors['ville'] = 'La ville ne doit pas dépasser 50 caractères';
        } else {
            $data['ville'] = $ville;
        }
    } else {
        $data['ville'] = null;
    }

    // ========================================================================
    // 10. SI AUCUNE ERREUR, CRÉER L'UTILISATEUR
    // ========================================================================
    if (empty($errors)) {
        try {
            // Hash du mot de passe de manière sécurisée
            $hashedPassword = password_hash($data['mdpUser'], PASSWORD_DEFAULT);
            
            // Préparer les données pour insertion
            $db = Database::getInstance();
            $sql = "INSERT INTO `USER` 
                    (idGenr, nomEUser, prenomUser, age, emailUser, mdpUser, biographie, dateInscription) 
                    VALUES 
                    (:idGenr, :nomEUser, :prenomUser, :age, :emailUser, :mdpUser, :biographie, NOW())";
            
            $stmt = $db->prepare($sql);
            $stmt->execute([
                ':idGenr' => $data['idGenr'],
                ':nomEUser' => $data['nomEUser'],
                ':prenomUser' => $data['prenomUser'],
                ':age' => $data['age'],
                ':emailUser' => $data['emailUser'],
                ':mdpUser' => $hashedPassword,
                ':biographie' => $data['biographie'],
            ]);
            
            $userId = $db->lastInsertId();
            $success = true;
            
            // Redirection vers la liste des utilisateurs pour afficher le compte fraîchement créé
            header('Location: list.php?success=1&id=' . (int)$userId);
            exit;
            
            // Message de succès
            echo '<div class="alert alert-success alert-dismissible fade show" role="alert">
                    <strong>Succès!</strong> L\'utilisateur a été créé avec succès (ID: ' . htmlspecialchars($userId) . ').
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                  </div>';
            
            // Réinitialiser le formulaire
            $input = [];
            
        } catch (Exception $e) {
            echo '<div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <strong>Erreur!</strong> Impossible de créer l\'utilisateur : ' . htmlspecialchars($e->getMessage()) . '
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                  </div>';
            error_log('Erreur création utilisateur: ' . $e->getMessage());
        }
    }
}

// ============================================================================
// RÉCUPÉRER LES GENRES POUR LE DROPDOWN
// ============================================================================
$genres = [];
try {
    $db = Database::getInstance();

    $countStmt = $db->query('SELECT COUNT(*) FROM `GENRE`');
    $genreCount = (int) $countStmt->fetchColumn();

    if ($genreCount === 0) {
        $defaultGenres = ['Femme', 'Homme', 'Préfère ne pas répondre'];
        foreach ($defaultGenres as $label) {
            $insert = $db->prepare('INSERT INTO `GENRE` (libGenr) VALUES (:libGenr)');
            $insert->execute([':libGenr' => $label]);
        }
    }

    $stmt = $db->query('SELECT idGenr, libGenr FROM `GENRE` ORDER BY idGenr ASC');
    $genres = $stmt->fetchAll(PDO::FETCH_ASSOC);

    $preferredOrder = ['Femme' => 0, 'Homme' => 1, 'Préfère ne pas répondre' => 2];
    usort($genres, function ($a, $b) use ($preferredOrder) {
        $aOrder = $preferredOrder[$a['libGenr']] ?? 99;
        $bOrder = $preferredOrder[$b['libGenr']] ?? 99;
        return $aOrder <=> $bOrder;
    });
} catch (Exception $e) {
    error_log('Erreur récupération genres: ' . $e->getMessage());
}

?>

<div class="container mt-5">
    <div class="row">
        <div class="col-md-8 offset-md-2">
            <h1 class="mb-4">Créer un nouveau compte utilisateur</h1>

            <!-- AFFICHER LES ERREURS SI PRÉSENTES -->
            <?php if (!empty($errors)): ?>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <strong>Veuillez corriger les erreurs suivantes :</strong>
                    <ul class="mt-2 mb-0">
                        <?php foreach ($errors as $field => $message): ?>
                            <li><?php echo htmlspecialchars($message); ?></li>
                        <?php endforeach; ?>
                    </ul>
                    <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
                </div>
            <?php endif; ?>

            <!-- FORMULAIRE D'INSCRIPTION -->
            <form method="POST" class="bg-light p-4 rounded">
                
                <!-- LIGNE 1: PRÉNOM ET NOM -->
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="prenomUser" class="form-label">Prénom <span class="text-danger">*</span></label>
                        <input type="text" class="form-control <?php echo isset($errors['prenomUser']) ? 'is-invalid' : ''; ?>" 
                               id="prenomUser" name="prenomUser" placeholder="Yassmine"
                               value="<?php echo htmlspecialchars($_POST['prenomUser'] ?? ''); ?>" required>
                        <?php if (isset($errors['prenomUser'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['prenomUser']); ?></div>
                        <?php endif; ?>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="nomEUser" class="form-label">Nom <span class="text-danger">*</span></label>
                        <input type="text" class="form-control <?php echo isset($errors['nomEUser']) ? 'is-invalid' : ''; ?>" 
                               id="nomEUser" name="nomEUser" placeholder="Rgana"
                               value="<?php echo htmlspecialchars($_POST['nomEUser'] ?? ''); ?>" required>
                        <?php if (isset($errors['nomEUser'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['nomEUser']); ?></div>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- LIGNE 2: DATE DE NAISSANCE ET GENRE -->
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="dateNaissance" class="form-label">Date de naissance <span class="text-danger">*</span></label>
                        <input type="date" class="form-control <?php echo isset($errors['dateNaissance']) ? 'is-invalid' : ''; ?>" 
                               id="dateNaissance" name="dateNaissance"
                               value="<?php echo htmlspecialchars($_POST['dateNaissance'] ?? ''); ?>" required>
                        <small class="form-text text-muted">Vous devez avoir au moins 18 ans</small>
                        <?php if (isset($errors['dateNaissance'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['dateNaissance']); ?></div>
                        <?php endif; ?>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="idGenr" class="form-label">Genre <span class="text-danger">*</span></label>
                        <select class="form-select <?php echo isset($errors['idGenr']) ? 'is-invalid' : ''; ?>" 
                                id="idGenr" name="idGenr" required>
                            <option value="">-- Sélectionner un genre --</option>
                            <?php foreach ($genres as $genre): ?>
                                <option value="<?php echo (int)$genre['idGenr']; ?>" 
                                        <?php echo (isset($_POST['idGenr']) && $_POST['idGenr'] == $genre['idGenr']) ? 'selected' : ''; ?>>
                                    <?php echo htmlspecialchars($genre['libGenr']); ?>
                                </option>
                            <?php endforeach; ?>
                        </select>
                        <?php if (isset($errors['idGenr'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['idGenr']); ?></div>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- LIGNE 3: EMAIL -->
                <div class="mb-3">
                    <label for="emailUser" class="form-label">Adresse e-mail <span class="text-danger">*</span></label>
                    <input type="email" class="form-control <?php echo isset($errors['emailUser']) ? 'is-invalid' : ''; ?>" 
                           id="emailUser" name="emailUser" placeholder="utilisateur@email.com"
                           value="<?php echo htmlspecialchars($_POST['emailUser'] ?? ''); ?>" required>
                    <?php if (isset($errors['emailUser'])): ?>
                        <div class="invalid-feedback"><?php echo htmlspecialchars($errors['emailUser']); ?></div>
                    <?php endif; ?>
                </div>

                <!-- LIGNE 4: MOT DE PASSE -->
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="mdpUser" class="form-label">Mot de passe <span class="text-danger">*</span></label>
                        <input type="password" class="form-control <?php echo isset($errors['mdpUser']) ? 'is-invalid' : ''; ?>" 
                               id="mdpUser" name="mdpUser" placeholder="••••••••"
                               required>
                        <small class="form-text text-muted">
                            Minimum 8 caractères, au moins une majuscule, une minuscule et un chiffre
                        </small>
                        <?php if (isset($errors['mdpUser'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['mdpUser']); ?></div>
                        <?php endif; ?>
                    </div>
                    <div class="col-md-6 mb-3">
                        <label for="mdpConfirmation" class="form-label">Confirmer le mot de passe <span class="text-danger">*</span></label>
                        <input type="password" class="form-control <?php echo isset($errors['mdpConfirmation']) ? 'is-invalid' : ''; ?>" 
                               id="mdpConfirmation" name="mdpConfirmation" placeholder="••••••••"
                               required>
                        <?php if (isset($errors['mdpConfirmation'])): ?>
                            <div class="invalid-feedback"><?php echo htmlspecialchars($errors['mdpConfirmation']); ?></div>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- LIGNE 5: VILLE (OPTIONNELLE) -->
                <div class="mb-3">
                    <label for="ville" class="form-label">Ville / Localisation</label>
                    <input type="text" class="form-control <?php echo isset($errors['ville']) ? 'is-invalid' : ''; ?>" 
                           id="ville" name="ville" placeholder="Bordeaux"
                           value="<?php echo htmlspecialchars($_POST['ville'] ?? ''); ?>">
                    <?php if (isset($errors['ville'])): ?>
                        <div class="invalid-feedback"><?php echo htmlspecialchars($errors['ville']); ?></div>
                    <?php endif; ?>
                </div>

                <!-- LIGNE 6: BIOGRAPHIE (OPTIONNELLE) -->
                <div class="mb-3">
                    <label for="biographie" class="form-label">Biographie</label>
                    <textarea class="form-control <?php echo isset($errors['biographie']) ? 'is-invalid' : ''; ?>" 
                              id="biographie" name="biographie" rows="3" placeholder="Parlez un peu de vous..."
                              maxlength="150"><?php echo htmlspecialchars($_POST['biographie'] ?? ''); ?></textarea>
                    <small class="form-text text-muted">Maximum 150 caractères</small>
                    <?php if (isset($errors['biographie'])): ?>
                        <div class="invalid-feedback"><?php echo htmlspecialchars($errors['biographie']); ?></div>
                    <?php endif; ?>
                </div>

                <!-- BOUTONS -->
                <div class="d-flex gap-2 mt-4">
                    <button type="submit" class="btn btn-primary">
                        <i class="bi bi-person-plus"></i> Créer le compte
                    </button>
                    <a href="../dashboard.php" class="btn btn-secondary">Annuler</a>
                </div>

            </form>

            <!-- NOTES DE SÉCURITÉ -->
            <div class="alert alert-info mt-4">
                <strong>ℹ️ Informations de sécurité :</strong>
                <ul class="mb-0 mt-2">
                    <li>Les mots de passe sont hashés avec bcrypt avant stockage</li>
                    <li>Les adresses email doivent être uniques dans la base de données</li>
                    <li>Tous les champs sont validés côté serveur</li>
                    <li>Les données sont échappées pour éviter les injections SQL</li>
                </ul>
            </div>

        </div>
    </div>
</div>

