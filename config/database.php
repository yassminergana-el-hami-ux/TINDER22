<?php
// Singleton PDO pour la connexion à la base MySQL
// Choix technique : PDO avec charset utf8mb4 et exceptions pour une gestion d'erreurs propre.
class Database
{
    private static ?\PDO $instance = null;

    private function __construct() {}

    public static function getInstance(): ?\PDO
    {
        if (self::$instance === null) {
            $host = getenv('DB_HOST') ?: '127.0.0.1';
            $db   = getenv('DB_DATABASE') ?: 'TINDER22';
            $user = getenv('DB_USER') ?: 'root';
            $pass = getenv('DB_PASSWORD') ?: '';
            $charset = 'utf8mb4';

            $dsn = "mysql:host={$host};dbname={$db};charset={$charset}";
            $options = [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ];

            try {
                self::$instance = new PDO($dsn, $user, $pass, $options);
            } catch (PDOException $e) {
                // Ne pas exposer les détails en production
                error_log('DB Connection error: ' . $e->getMessage());
                throw $e;
            }
        }

        return self::$instance;
    }
}
