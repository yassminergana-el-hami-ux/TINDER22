<?php
require_once __DIR__ . '/../controllers/AuthController.php';
require_once __DIR__ . '/../models/GenreModel.php';

// Endpoint CSRF token
function handleCsrf()
{
    if (session_status() === PHP_SESSION_NONE) session_start();
    $token = bin2hex(random_bytes(32));
    $_SESSION['csrf_token'] = $token;
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['success' => true, 'csrf_token' => $token]);
}

// Endpoint GET /api/genres
function handleGenres()
{
    header('Content-Type: application/json; charset=utf-8');
    $model = new GenreModel();
    $data = $model->findAll();
    echo json_encode(['success' => true, 'data' => $data]);
}

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

    if (preg_match('#/api/genres$#', $path) && strtoupper($method) === 'GET') {
        handleGenres();
        return true;
    }

    if (preg_match('#/api/csrf$#', $path) && strtoupper($method) === 'GET') {
        handleCsrf();
        return true;
    }

    return false;
}
