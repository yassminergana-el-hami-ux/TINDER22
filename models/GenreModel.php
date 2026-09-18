<?php
require_once __DIR__ . '/../config/database.php';

// Modèle pour la table GENRE
class GenreModel
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    // Retourne la liste des genres
    public function findAll(): array
    {
        $sql = 'SELECT idGenr, libGenr FROM GENRE ORDER BY idGenr';
        $stmt = $this->db->query($sql);
        return $stmt->fetchAll();
    }
}
