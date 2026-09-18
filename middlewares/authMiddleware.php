<?php
require_once __DIR__ . '/../helpers/JwtHelper.php';

// Middleware d'authentification
// Extrait et valide le token JWT depuis l'en-tête Authorization: Bearer <token>
// Attache l'utilisateur à la requête (en global, pour les routes qui en ont besoin)
class AuthMiddleware
{
    private JwtHelper $jwt;

    public function __construct()
    {
        $this->jwt = new JwtHelper();
    }

    // Valide le token et retourne le payload si valide, null sinon
    public function authenticate(): ?array
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';

        // Parser "Bearer <token>"
        if (!preg_match('/^Bearer\s+(.+)$/', $header, $m)) {
            return null;
        }

        $token = $m[1];
        $payload = $this->jwt->decode($token);

        if (!$payload) {
            return null;
        }

        // Vérifier que le payload contient les champs attendus
        if (!isset($payload['idUser'], $payload['emailUser'])) {
            return null;
        }

        return $payload;
    }

    // Middleware pour les routes protégées: vérifie le token et retourne 401 si invalide
    public function handle(): bool
    {
        $payload = $this->authenticate();
        if (!$payload) {
            http_response_code(401);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode(['success' => false, 'message' => 'Authentification requise']);
            return false;
        }

        // Attacher au contexte global pour utilisation dans les routes
        $GLOBALS['currentUser'] = $payload;
        return true;
    }

    // Récupère l'utilisateur actuel si le middleware a validé le token
    public static function getCurrentUser(): ?array
    {
        return $GLOBALS['currentUser'] ?? null;
    }
}
