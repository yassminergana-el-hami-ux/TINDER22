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

    // Trouve un utilisateur par email, retourne toutes ses données (incluant hash mdp)
    public function findByEmail(string $email): ?array
    {
        $sql = "SELECT * FROM `USER` WHERE emailUser = :email LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':email' => $email]);
        $row = $stmt->fetch();
        return $row ?: null;
    }

    // Incrémente le compteur d'échecs pour un utilisateur
    public function incrementerEchecs(int $idUser): void
    {
        $sql = "UPDATE `USER` SET tentativesEchouees = tentativesEchouees + 1 WHERE idUser = :idUser";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idUser' => $idUser]);
    }

    // Réinitialise les échecs et déverrouille le compte
    public function reinitialiserEchecs(int $idUser): void
    {
        $sql = "UPDATE `USER` SET tentativesEchouees = 0, bloqueJusqua = NULL WHERE idUser = :idUser";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idUser' => $idUser]);
    }

    // Bloque le compte pour 15 minutes
    public function bloquerCompte(int $idUser): void
    {
        $bloqueJusqua = date('Y-m-d H:i:s', strtotime('+15 minutes'));
        $sql = "UPDATE `USER` SET bloqueJusqua = :bloqueJusqua, tentativesEchouees = 0 WHERE idUser = :idUser";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':bloqueJusqua' => $bloqueJusqua, ':idUser' => $idUser]);
    }

    // Met à jour la dernière connexion
    public function majDerniereConnexion(int $idUser): void
    {
        $sql = "UPDATE `USER` SET derniereConnexion = NOW() WHERE idUser = :idUser";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idUser' => $idUser]);
    }

    // Récupère les infos de l'utilisateur (sans le mot de passe)
    public function getInfos(int $idUser): ?array
    {
        $sql = "SELECT u.idUser, u.prenomUser, u.nomEUser, u.emailUser, u.photo, u.age, u.idGenr, u.biographie
                FROM `USER` u
                WHERE u.idUser = :idUser LIMIT 1";
        $stmt = $this->db->prepare($sql);
        $stmt->execute([':idUser' => $idUser]);
        $row = $stmt->fetch();
        return $row ?: null;
    }
}
