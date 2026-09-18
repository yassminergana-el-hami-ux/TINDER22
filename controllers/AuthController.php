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

        // Supporter multipart/form-data (avec photo) ou JSON
        $input = [];
        $files = [];
        if (isset($_SERVER['CONTENT_TYPE']) && str_contains($_SERVER['CONTENT_TYPE'], 'multipart/form-data')) {
            // PHP remplit $_POST et $_FILES
            $input = $_POST;
            $files = $_FILES;
        } else {
            $raw = file_get_contents('php://input');
            $input = json_decode($raw, true) ?? [];
        }

        // Démarrer la session pour CSRF et autres
        if (session_status() === PHP_SESSION_NONE) session_start();

        // IP du client
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

            // CSRF token vérification si fournie (session must have token generated via /api/csrf)
            if (isset($input['csrf_token'])) {
                $token = $_SESSION['csrf_token'] ?? null;
                if (!$token || !hash_equals($token, $input['csrf_token'])) {
                    http_response_code(400);
                    echo json_encode(['success' => false, 'message' => 'Données invalides', 'errors' => ['csrf' => 'Jeton CSRF invalide']]);
                    return;
                }
            }

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

            $photoFilename = null;
            // Si fichier image envoyé
            if (!empty($files['photo'] ?? null) && ($files['photo']['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE) {
                require_once __DIR__ . '/../helpers/Upload.php';
                $u = new Upload();
                $res = $u->handle($files['photo'], __DIR__ . '/../uploads');
                if (!$res['success']) {
                    if ($res['error'] === 'FILE_TOO_LARGE') {
                        http_response_code(413);
                        echo json_encode(['success' => false, 'message' => 'Fichier trop volumineux']);
                        return;
                    }
                    if ($res['error'] === 'INVALID_FILE_TYPE') {
                        http_response_code(400);
                        echo json_encode(['success' => false, 'message' => 'Type de fichier invalide', 'errors' => ['photo' => 'Types autorisés : jpg, png, webp']]);
                        return;
                    }
                    http_response_code(500);
                    echo json_encode(['success' => false, 'message' => 'Erreur serveur']);
                    return;
                }
                $photoFilename = $res['filename'];
            }

            // Préparer tableau pour insertion
            $insertData = [
                'idGenr' => $data['idGenr'],
                'nomEUser' => $data['nomEUser'],
                'prenomUser' => $data['prenomUser'],
                'photo' => $photoFilename,
                'age' => $data['age'],
                'biographie' => $data['biographie'],
                'emailUser' => $data['emailUser'],
                'mdpUser' => $hashed,
            ];

            $user = $this->userModel->create($insertData);

            http_response_code(201);
            echo json_encode(['success' => true, 'message' => 'Compte créé', 'data' => ['idUser' => $user['idUser'], 'prenomUser' => $user['prenomUser'], 'emailUser' => $user['emailUser']]]);
            return;

        } catch (Exception $e) {
            // Log interne détaillé, réponse générique au client
            error_log('Register error: ' . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur serveur']);
            return;
        }
    }

    // Traite la connexion
    public function login()
    {
        header('Content-Type: application/json; charset=utf-8');

        $raw = file_get_contents('php://input');
        $input = json_decode($raw, true) ?? [];

        $ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';

        try {
            // 1) Vérifier champs requis
            if (empty($input['emailUser'] ?? null) || empty($input['mdpUser'] ?? null)) {
                http_response_code(400);
                echo json_encode(['success' => false, 'message' => 'Champs email et mot de passe requis']);
                return;
            }

            // Rate-limit par IP : max 10 tentatives par heure
            $stmt = $this->db->prepare('SELECT COUNT(*) FROM login_attempts WHERE ip = :ip AND attempted_at >= (NOW() - INTERVAL 1 HOUR)');
            $stmt->execute([':ip' => $ip]);
            $count = (int) $stmt->fetchColumn();
            if ($count >= 10) {
                http_response_code(429);
                echo json_encode(['success' => false, 'message' => 'Trop de tentatives. Réessayez plus tard.']);
                return;
            }

            // 2) Enregistrer la tentative
            $stmt = $this->db->prepare('INSERT INTO login_attempts (ip) VALUES (:ip)');
            $stmt->execute([':ip' => $ip]);

            // 3) Chercher l'utilisateur
            $email = mb_strtolower(trim($input['emailUser']));
            $user = $this->userModel->findByEmail($email);

            if (!$user) {
                // 3bis) Utilisateur inexistant → message générique
                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect']);
                return;
            }

            // 4) Vérifier si compte bloqué
            if ($user['bloqueJusqua'] && strtotime($user['bloqueJusqua']) > time()) {
                $minutesRestantes = (int)((strtotime($user['bloqueJusqua']) - time()) / 60);
                http_response_code(423);
                echo json_encode(['success' => false, 'message' => "Compte bloqué", 'minutesRestantes' => $minutesRestantes]);
                return;
            }

            // 5) Vérifier mot de passe
            if (!password_verify($input['mdpUser'], $user['mdpUser'])) {
                // Mauvais mot de passe
                $this->userModel->incrementerEchecs($user['idUser']);

                $newAttempts = $user['tentativesEchouees'] + 1;
                if ($newAttempts >= 5) {
                    // Bloquer 15 min
                    $this->userModel->bloquerCompte($user['idUser']);
                }

                http_response_code(401);
                echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect']);
                return;
            }

            // 7) Mot de passe correct
            $this->userModel->reinitialiserEchecs($user['idUser']);
            $this->userModel->majDerniereConnexion($user['idUser']);

            // Générer le JWT
            require_once __DIR__ . '/../helpers/JwtHelper.php';
            $jwt = new JwtHelper();
            $rememberMe = !empty($input['rememberMe']);
            $token = $jwt->generate([
                'idUser' => $user['idUser'],
                'emailUser' => $user['emailUser'],
            ], $rememberMe);

            // Récupérer les infos de l'utilisateur (sans mdp)
            $userInfos = $this->userModel->getInfos($user['idUser']);

            http_response_code(200);
            echo json_encode([
                'success' => true,
                'message' => 'Connexion réussie',
                'token' => $token,
                'user' => $userInfos,
            ]);
            return;

        } catch (Exception $e) {
            error_log('Login error: ' . $e->getMessage());
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur serveur']);
            return;
        }
    }

    // Déconnexion
    public function logout()
    {
        header('Content-Type: application/json; charset=utf-8');

        // JWT stateless: aucune action serveur nécessaire.
        // La déconnexion se fait côté client en supprimant le token.
        // Optionnel : implémenter une blacklist de tokens si besoin de révocation instantanée.

        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Déconnexion réussie']);
    }

    // Récupère l'utilisateur courant (à partir du token JWT)
    public function me()
    {
        header('Content-Type: application/json; charset=utf-8');

        require_once __DIR__ . '/../middlewares/authMiddleware.php';
        $auth = new AuthMiddleware();

        if (!$auth->handle()) {
            return;
        }

        $payload = AuthMiddleware::getCurrentUser();
        $userInfos = $this->userModel->getInfos($payload['idUser']);

        if (!$userInfos) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'Utilisateur non trouvé']);
            return;
        }

        http_response_code(200);
        echo json_encode(['success' => true, 'data' => $userInfos]);
    }
}
