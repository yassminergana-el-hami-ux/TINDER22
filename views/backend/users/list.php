<?php
include '../../../header.php';
require_once '../../../config/database.php';

$db = Database::getInstance();

$successMessage = null;
if (isset($_GET['success']) && $_GET['success'] == '1') {
    $successMessage = 'Compte créé avec succès.';
}

$sql = "
    SELECT u.idUser, u.prenomUser, u.nomEUser, u.emailUser, u.age, g.libGenr
    FROM `USER` u
    LEFT JOIN `GENRE` g ON g.idGenr = u.idGenr
    ORDER BY u.idUser DESC
";

$stmt = $db->prepare($sql);
$stmt->execute();
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
?>

<div class="container mt-5">
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1>Utilisateurs</h1>
        <a href="create.php" class="btn btn-success">Créer un compte</a>
    </div>

    <?php if ($successMessage): ?>
        <div class="alert alert-success"><?php echo htmlspecialchars($successMessage); ?></div>
    <?php endif; ?>

    <div class="card shadow-sm">
        <div class="card-body p-0">
            <table class="table table-striped mb-0">
                <thead class="table-dark">
                    <tr>
                        <th>ID</th>
                        <th>Prénom</th>
                        <th>Nom</th>
                        <th>Email</th>
                        <th>Age</th>
                        <th>Genre</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($users)): ?>
                        <tr>
                            <td colspan="6" class="text-center text-muted">Aucun utilisateur enregistré pour le moment.</td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($users as $user): ?>
                            <tr>
                                <td><?php echo (int)$user['idUser']; ?></td>
                                <td><?php echo htmlspecialchars($user['prenomUser'] ?? '-'); ?></td>
                                <td><?php echo htmlspecialchars($user['nomEUser'] ?? '-'); ?></td>
                                <td><?php echo htmlspecialchars($user['emailUser'] ?? '-'); ?></td>
                                <td><?php echo htmlspecialchars($user['age'] ?? '-'); ?></td>
                                <td><?php echo htmlspecialchars($user['libGenr'] ?? '-'); ?></td>
                            </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php include '../../../footer.php'; ?>

