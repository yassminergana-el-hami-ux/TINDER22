<?php
require_once __DIR__ . '/../controllers/AuthController.php';

// Gestionnaire de routes pour l'auth (inscription)
function handleAuthRoutes(string $uri, string $method)
{
    // Normaliser l'uri (sans query string)
    $path = parse_url($uri, PHP_URL_PATH);

    // Supporter un préfixe d'application (ex: /TINDER22/api/register)
    if (preg_match('#/api/register$#', $path) && strtoupper($method) === 'POST') {
        $controller = new AuthController();
        $controller->register();
        return true;
    }

    return false;
}
