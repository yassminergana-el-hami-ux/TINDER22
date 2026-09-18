<?php
// Helper pour gérer l'upload d'images
// Vérifie le type MIME réel, la taille, et stocke le fichier sous /uploads avec un nom aléatoire
class Upload
{
    private array $allowed = ['image/jpeg', 'image/png', 'image/webp'];
    private int $maxSize = 2097152; // 2MB

    public function __construct() {}

    // $file is an element from $_FILES
    public function handle(array $file, string $uploadDir): array
    {
        if ($file['error'] === UPLOAD_ERR_NO_FILE) {
            return ['success' => true, 'filename' => null];
        }

        if ($file['error'] !== UPLOAD_ERR_OK) {
            return ['success' => false, 'error' => 'Upload error'];
        }

        if ($file['size'] > $this->maxSize) {
            return ['success' => false, 'error' => 'FILE_TOO_LARGE'];
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']);
        if (!in_array($mime, $this->allowed, true)) {
            return ['success' => false, 'error' => 'INVALID_FILE_TYPE'];
        }

        // Générer un nom aléatoire en conservant l'extension
        $ext = match ($mime) {
            'image/jpeg' => '.jpg',
            'image/png' => '.png',
            'image/webp' => '.webp',
            default => '',
        };

        $basename = bin2hex(random_bytes(16)) . $ext;

        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $dest = rtrim($uploadDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $basename;
        if (!move_uploaded_file($file['tmp_name'], $dest)) {
            return ['success' => false, 'error' => 'CANT_MOVE_FILE'];
        }

        return ['success' => true, 'filename' => $basename];
    }
}
