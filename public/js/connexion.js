/**
 * Script pour la page de connexion
 * Gère l'affichage/masquage du mot de passe, l'envoi du formulaire,
 * et le stockage du token JWT
 */

// Configuration
const API_BASE = '/TINDER22/api'; // Adapter si le projet a un autre préfixe
const TOKEN_STORAGE_KEY = 'auth_token';
const REDIRECT_DELAY = 1000; // ms avant redirection

// Éléments du DOM
const form = document.getElementById('loginForm');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const togglePasswordBtn = document.getElementById('togglePassword');
const rememberMeCheckbox = document.getElementById('rememberMe');
const submitBtn = document.getElementById('submitBtn');
const spinner = document.getElementById('spinner');
const errorMessage = document.getElementById('errorMessage');

// Toggle afficher/masquer le mot de passe
togglePasswordBtn.addEventListener('click', (e) => {
    e.preventDefault();
    const type = passwordInput.type === 'password' ? 'text' : 'password';
    passwordInput.type = type;
    togglePasswordBtn.textContent = type === 'password' ? '👁' : '👁‍🗨';
});

// Gère la soumission du formulaire
form.addEventListener('submit', async (e) => {
    e.preventDefault();
    await handleLogin();
});

// Fonction pour soumettre la connexion
async function handleLogin() {
    // Masquer les erreurs précédentes
    errorMessage.style.display = 'none';
    errorMessage.textContent = '';

    // Désactiver le bouton et afficher le spinner
    submitBtn.disabled = true;
    spinner.style.display = 'inline-block';

    try {
        // Préparer les données
        const payload = {
            emailUser: emailInput.value.trim(),
            mdpUser: passwordInput.value,
            rememberMe: rememberMeCheckbox.checked,
        };

        // Envoyer la requête
        const response = await fetch(`${API_BASE}/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(payload),
        });

        const data = await response.json();

        // Gérer les réponses
        if (response.status === 200) {
            // Succès
            if (data.token) {
                // Stocker le token en httpOnly cookie (si le serveur l'envoie) 
                // Sinon, le stocker en localStorage (moins sécurisé mais ok pour démo)
                storeToken(data.token);
            }

            // Afficher un message de succès
            showSuccessMessage('Connexion réussie, redirection...');

            // Redirection après délai
            setTimeout(() => {
                window.location.href = 'home.html';
            }, REDIRECT_DELAY);
        } else if (response.status === 400) {
            // Champs manquants
            showErrorMessage(data.message || 'Données invalides');
        } else if (response.status === 401) {
            // Identifiants incorrects (message générique)
            showErrorMessage('Email ou mot de passe incorrect');
        } else if (response.status === 423) {
            // Compte bloqué temporairement
            const minutes = data.minutesRestantes || 15;
            showErrorMessage(`Compte bloqué pendant ${minutes} minute(s). Réessayez plus tard.`);
        } else if (response.status === 429) {
            // Rate-limit par IP
            showErrorMessage('Trop de tentatives. Réessayez dans une heure.');
        } else {
            // Erreur serveur
            showErrorMessage('Une erreur s\'est produite. Veuillez réessayer.');
        }
    } catch (err) {
        console.error('Erreur réseau :', err);
        showErrorMessage('Erreur de connexion. Vérifiez votre connexion internet.');
    } finally {
        // Réactiver le bouton et masquer le spinner
        submitBtn.disabled = false;
        spinner.style.display = 'none';
    }
}

// Stocke le token JWT
function storeToken(token) {
    // Option 1 : localStorage (moins sécurisé, vulnérable aux XSS)
    localStorage.setItem(TOKEN_STORAGE_KEY, token);

    // Optionnel : envoyer au serveur pour qu'il le mette en httpOnly cookie
    // (voir commentaire dans AuthController)
}

// Récupère le token JWT du stockage
function getToken() {
    return localStorage.getItem(TOKEN_STORAGE_KEY);
}

// Supprime le token JWT du stockage (utilisé pour la déconnexion)
function clearToken() {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
}

// Affiche un message d'erreur
function showErrorMessage(message) {
    errorMessage.textContent = message;
    errorMessage.style.display = 'block';
}

// Affiche un message de succès (optionnel)
function showSuccessMessage(message) {
    const btn = submitBtn.querySelector('span:last-child');
    btn.textContent = message;
}

// Vérifier si l'utilisateur est déjà connecté au chargement
document.addEventListener('DOMContentLoaded', async () => {
    const token = getToken();
    if (token) {
        // Vérifier si le token est toujours valide
        try {
            const response = await fetch(`${API_BASE}/me`, {
                headers: {
                    'Authorization': `Bearer ${token}`,
                },
            });

            if (response.ok) {
                // Déjà connecté, rediriger
                window.location.href = 'home.html';
            } else {
                // Token expiré, le supprimer
                clearToken();
            }
        } catch (err) {
            console.error('Erreur lors de la vérification de session :', err);
        }
    }
});
