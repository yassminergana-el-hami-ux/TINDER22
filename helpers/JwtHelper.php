<?php
// Helper pour gérer les tokens JWT
// Choix technique : JWT stateless pour scalabilité; token court (2h) + option remember me (30j).
// Production: utiliser HTTPS et une clé secrète forte stockée en variable d'environnement.
class JwtHelper
{
    private string $secret;
    private int $tokenExpiry = 7200; // 2 heures par défaut
    private int $rememberMeExpiry = 2592000; // 30 jours

    public function __construct()
    {
        // Clé secrète depuis .env, fallback à une clé de développement
        $this->secret = getenv('JWT_SECRET') ?: 'dev-secret-change-in-production';
    }

    // Génère un token JWT avec payload
    public function generate(array $payload, bool $rememberMe = false): string
    {
        $header = [
            'alg' => 'HS256',
            'typ' => 'JWT',
        ];

        $now = time();
        $expiry = $rememberMe ? $this->rememberMeExpiry : $this->tokenExpiry;

        $claims = array_merge($payload, [
            'iat' => $now,
            'exp' => $now + $expiry,
        ]);

        $header64 = rtrim(strtr(base64_encode(json_encode($header)), '+/', '-_'), '=');
        $claims64 = rtrim(strtr(base64_encode(json_encode($claims)), '+/', '-_'), '=');

        $signature = hash_hmac('sha256', "{$header64}.{$claims64}", $this->secret, true);
        $signature64 = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');

        return "{$header64}.{$claims64}.{$signature64}";
    }

    // Valide et décode un token JWT
    public function decode(string $token): ?array
    {
        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        list($header64, $claims64, $signature64) = $parts;

        // Vérifier la signature
        $sig = hash_hmac('sha256', "{$header64}.{$claims64}", $this->secret, true);
        $expectedSig64 = rtrim(strtr(base64_encode($sig), '+/', '-_'), '=');

        if (!hash_equals($signature64, $expectedSig64)) {
            return null;
        }

        // Décoder les claims
        $claims = json_decode(base64_decode(strtr($claims64, '-_', '+/')), true);
        if (!is_array($claims)) {
            return null;
        }

        // Vérifier l'expiration
        if (isset($claims['exp']) && $claims['exp'] < time()) {
            return null;
        }

        return $claims;
    }
}
