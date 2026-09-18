<?php
require_once __DIR__ . '/../config/database.php';

// Modèle pour la table USER
// Choix technique : méthodes petites et testables, aucune requête avec concaténation.
class UserModel
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::getInstance();
    }

    // Retourne true si l'email existe
    public function emailExiste(string $email): bool
    {
        $sql = "SELECT 1 FROM `USER` WHERE emailUser = :email LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':email' => $email]);
        return (bool) $stmt->fetchColumn();
    }

    // Retourne true si le genre existe
    public function genreExiste(int $idGenr): bool
    {
        $sql = "SELECT 1 FROM `GENRE` WHERE idGenr = :idGenr LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idGenr' => $idGenr]);
        return (bool) $stmt->fetchColumn();
    }

    // Crée l'utilisateur. $data doit contenir clefs validées.
    // Retourne le tableau de l'utilisateur inséré (sans mdpUser)
    public function create(array $data): array
    {
        $sql = "INSERT INTO `USER` (idGenr, nomEUser, prenomUser, photo, age, biographie, emailUser, mdpUser)
                VALUES (:idGenr, :nomEUser, :prenomUser, :photo, :age, :biographie, :emailUser, :mdpUser)";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':idGenr' => $data['idGenr'],
            ':nomEUser' => $data['nomEUser'],
            ':prenomUser' => $data['prenomUser'],
            ':photo' => $data['photo'] ?? null,
            ':age' => $data['age'],
            ':biographie' => $data['biographie'] ?? null,
            ':emailUser' => $data['emailUser'],
            ':mdpUser' => $data['mdpUser'], // doit être hashé avant l'appel
        ]);

        $id = (int) $this->db->lastInsertId();

        // Récupérer l'utilisateur avec le libGenr pour la réponse
        $sql = "SELECT u.idUser, u.emailUser, u.nomEUser, u.prenomUser, u.age, u.idGenr, g.libGenr, u.biographie, u.photo
                FROM `USER` u
                JOIN `GENRE` g ON g.idGenr = u.idGenr
                WHERE u.idUser = :idUser LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idUser' => $id]);
        $row = $stmt->fetch();
        if (!$row) {
            throw new RuntimeException('Impossible de récupérer l\'utilisateur après insertion');
        }

        // Normaliser les valeurs null correctement
        $row['biographie'] = $row['biographie'] ?? null;
        $row['photo'] = $row['photo'] ?? null;

        return $row;
    }
}
