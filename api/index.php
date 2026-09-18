<?php
// Point d'entrée pour l'API (simple router)
// Choix : un routeur minimal pour rester simple et compatible avec l'infrastructure existante.

// CORS et headers JSON
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

require_once __DIR__ . '/../routes/auth.php';

$uri = $_SERVER['REQUEST_URI'] ?? '/';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

// Déléguer aux handlers
if (handleAuthRoutes($uri, $method)) {
    exit;
}

// 404 par défaut
header('Content-Type: application/json; charset=utf-8');
http_response_code(404);
echo json_encode(['success' => false, 'message' => 'Route introuvable']);
