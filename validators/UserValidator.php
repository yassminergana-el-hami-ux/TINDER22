<?php
require_once __DIR__ . '/../models/UserModel.php';

// Classe de validation pour l'inscription
// Retourne un tableau ['errors' => [], 'data' => []]
class UserValidator
{
    public static function validate(array $input, UserModel $model): array
    {
        $errors = [];
        $data = [];

        // 1) Champs obligatoires (le front envoie la date de naissance; on calcule l'âge côté serveur)
        $required = ['emailUser', 'mdpUser', 'mdpConfirmation', 'nomEUser', 'prenomUser', 'dateNaissance', 'idGenr'];
        foreach ($required as $field) {
            if (!isset($input[$field]) || (is_string($input[$field]) && trim($input[$field]) === '')) {
                $errors[$field] = 'Champ requis';
            }
        }

        // Si champs manquants, on s'arrête ici (mais on renvoie toutes les erreurs trouvées jusqu'ici)
        // 2) email : format + longueur + normalisation
        if (!isset($errors['emailUser']) && isset($input['emailUser'])) {
            $email = mb_strtolower(trim($input['emailUser']));
            if (mb_strlen($email) > 100) {
                $errors['emailUser'] = 'Adresse email trop longue';
            } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
                $errors['emailUser'] = 'Adresse email invalide';
            } else {
                $data['emailUser'] = $email;
            }
        }

        // 3) email déjà existant -> marque spéciale pour controller (409)
        if (!isset($errors['emailUser']) && isset($data['emailUser'])) {
            if ($model->emailExiste($data['emailUser'])) {
                $errors['emailUser'] = 'EMAIL_ALREADY_EXISTS';
                // expliquer dans code : UX vs sécurité (on renvoie explicite)
            }
        }

        // 4) mot de passe règles
        if (!isset($errors['mdpUser']) && isset($input['mdpUser'])) {
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
                $data['mdpUser'] = $pwd; // hashé plus tard
            }
        }

        // 5) confirmation
        if (!isset($errors['mdpConfirmation']) && isset($input['mdpConfirmation']) && isset($data['mdpUser'])) {
            if ($input['mdpConfirmation'] !== $data['mdpUser']) {
                $errors['mdpConfirmation'] = 'La confirmation ne correspond pas au mot de passe';
            }
        }

        // 6) nom/prenom validation
        $namePattern = '/^[\p{L}\s\'-]{2,50}$/u';
        if (!isset($errors['nomEUser']) && isset($input['nomEUser'])) {
            $nom = trim($input['nomEUser']);
            if (mb_strlen($nom) < 2 || mb_strlen($nom) > 50) {
                $errors['nomEUser'] = 'Le nom doit contenir entre 2 et 50 caractères';
            } elseif (!preg_match($namePattern, $nom)) {
                $errors['nomEUser'] = 'Caractères invalides dans le nom';
            } else {
                $data['nomEUser'] = $nom;
            }
        }

        if (!isset($errors['prenomUser']) && isset($input['prenomUser'])) {
            $prenom = trim($input['prenomUser']);
            if (mb_strlen($prenom) < 2 || mb_strlen($prenom) > 50) {
                $errors['prenomUser'] = 'Le prénom doit contenir entre 2 et 50 caractères';
            } elseif (!preg_match($namePattern, $prenom)) {
                $errors['prenomUser'] = 'Caractères invalides dans le prénom';
            } else {
                $data['prenomUser'] = $prenom;
            }
        }

        // 7) dateNaissance -> calcul de l'âge (18-120)
        if (!isset($errors['dateNaissance']) && isset($input['dateNaissance'])) {
            $dob = $input['dateNaissance'];
            $d = DateTime::createFromFormat('Y-m-d', $dob);
            $now = new DateTime();
            if (!$d) {
                $errors['dateNaissance'] = 'Date de naissance invalide';
            } else {
                $age = $d->diff($now)->y;
                if ($age < 18) {
                    $errors['dateNaissance'] = 'Vous devez être majeur (18+)';
                } elseif ($age > 120) {
                    $errors['dateNaissance'] = 'Âge invalide';
                } else {
                    $data['age'] = $age;
                }
            }
        }

        // 8) idGenr existe
        if (!isset($errors['idGenr']) && isset($input['idGenr'])) {
            $idGenr = filter_var($input['idGenr'], FILTER_VALIDATE_INT);
            if ($idGenr === false) {
                $errors['idGenr'] = 'idGenr invalide';
            } else {
                if (!$model->genreExiste($idGenr)) {
                    $errors['idGenr'] = 'GENRE_NOT_FOUND';
                } else {
                    $data['idGenr'] = $idGenr;
                }
            }
        }

        // 9) biographie optionnelle
        if (isset($input['biographie']) && $input['biographie'] !== null && $input['biographie'] !== '') {
            $bio = trim($input['biographie']);
            if (mb_strlen($bio) > 150) {
                $errors['biographie'] = 'La biographie ne doit pas dépasser 150 caractères';
            } else {
                $data['biographie'] = $bio;
            }
        } else {
            $data['biographie'] = null;
        }

        // photo non fournie -> null
        $data['photo'] = null;

        return ['errors' => $errors, 'data' => $data];
    }
}
