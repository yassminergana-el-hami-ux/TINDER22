<?php
require_once __DIR__ . '/../models/UserModel.php';
require_once __DIR__ . '/../validators/UserValidator.php';
require_once __DIR__ . '/../config/database.php';

// Contrôleur pour l'authentification / inscription
class AuthController
{
    private UserModel $userModel;
    private PDO $db;
    private int $maxAttempts = 5; // max par IP par heure

    public function __construct()
    {
        $this->userModel = new UserModel();
        $this->db = Database::getInstance();
    }

    // Orchestration de l'inscription
    public function register()
    {
        // Headers JSON
        header('Content-Type: application/json; charset=utf-8');

        // Lecture du JSON body
        $raw = file_get_contents('php://input');
        $input = json_decode($raw, true);
        if (!is_array($input)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Données invalides', 'errors' => ['body' => 'JSON malformé']]);
            return;
        }

        // IP du client (simple)
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

        try {
            // Rate-limit : compter les tentatives dans la dernière heure
            $stmt = $this->db->prepare('SELECT COUNT(*) FROM registration_attempts WHERE ip = :ip AND attempted_at >= (NOW() - INTERVAL 1 HOUR)');
            $stmt->execute([':ip' => $ip]);
            $count = (int) $stmt->fetchColumn();
            if ($count >= $this->maxAttempts) {
                http_response_code(429);
                echo json_encode(['success' => false, 'message' => 'Trop de tentatives. Réessayez plus tard.']);
                return;
            }

            // Enregistrer la tentative (on compte aussi les échecs)
            $stmt = $this->db->prepare('INSERT INTO registration_attempts (ip) VALUES (:ip)');
            $stmt->execute([':ip' => $ip]);

            // Validation
            $validation = UserValidator::validate($input, $this->userModel);
            $errors = $validation['errors'];
            $data = $validation['data'];

            // Si erreurs de validation, renvoyer 400 (sauf cas spéciaux gérés plus bas)
            if (!empty($errors)) {
                // Si email exists => 409
                if (isset($errors['emailUser']) && $errors['emailUser'] === 'EMAIL_ALREADY_EXISTS') {
                    http_response_code(409);
                    echo json_encode(['success' => false, 'message' => 'Adresse email déjà utilisée', 'errors' => ['emailUser' => 'Adresse email déjà utilisée']]);
                    return;
                }

                // Si idGenr not found => 422
                if (isset($errors['idGenr']) && $errors['idGenr'] === 'GENRE_NOT_FOUND' || (isset($errors['idGenr']) && $errors['idGenr'] === 'GENRE_NOT_FOUND')) {
                    http_response_code(422);
                    echo json_encode(['success' => false, 'message' => 'Genre inconnu', 'errors' => ['idGenr' => 'Le genre spécifié n\'existe pas']]);
                    return;
                }

                // Remplacer les codes d'erreurs internes par des messages lisibles
                $humanErrors = [];
                foreach ($errors as $k => $v) {
                    if ($v === 'EMAIL_ALREADY_EXISTS') {
                        $humanErrors[$k] = 'Adresse email déjà utilisée';
                    } elseif ($v === 'GENRE_NOT_FOUND') {
                        $humanErrors[$k] = 'Le genre spécifié n\'existe pas';
                    } else {
                        $humanErrors[$k] = $v;
                    }
                }

                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Données invalides', 'errors' => $humanErrors]);
                return;
            }

            // Hash du mot de passe (ne jamais logger mdp)
            $hashed = password_hash($data['mdpUser'], PASSWORD_DEFAULT);

            // Préparer tableau pour insertion
            $insertData = [
                'idGenr' => $data['idGenr'],
                'nomEUser' => $data['nomEUser'],
                'prenomUser' => $data['prenomUser'],
                'photo' => null,
                'age' => $data['age'],
                'biographie' => $data['biographie'],
                'emailUser' => $data['emailUser'],
                'mdpUser' => $hashed,
            ];

            $user = $this->userModel->create($insertData);

            http_response_code(201);
            echo json_encode(['success' => true, 'message' => 'Compte créé avec succès', 'data' => $user]);
            return;

        } catch (Exception $e) {
            // Log interne détaillé, réponse générique au client
            error_log('Register error: ' . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur serveur']);
            return;
        }
    }
}
