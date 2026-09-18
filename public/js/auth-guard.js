/**
 * Script de protection des pages
 * À inclure en haut de toute page protégée (home.html, profil.html, etc.)
 * Vérifie la validité du token et redirige vers connexion.html si absent/invalide
 */

const API_BASE = '/TINDER22/api'; // Adapter si nécessaire
const TOKEN_STORAGE_KEY = 'auth_token';

// Récupère le token du localStorage
function getToken() {
    return localStorage.getItem(TOKEN_STORAGE_KEY);
}

// Supprime le token du localStorage
function clearToken() {
    localStorage.removeItem(TOKEN_STORAGE_KEY);
}

// Vérifie la validité du token et charge les infos utilisateur
async function verifyAndLoadUser() {
    const token = getToken();

    if (!token) {
        // Pas de token, rediriger vers connexion
        redirectToLogin();
        return null;
    }

    try {
        const response = await fetch(`${API_BASE}/me`, {
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });

        if (response.ok) {
            const data = await response.json();
            return data.data; // Retourne les infos utilisateur
        } else if (response.status === 401) {
            // Token invalide ou expiré
            clearToken();
            redirectToLogin();
            return null;
        } else {
            // Erreur serveur, rediriger
            redirectToLogin();
            return null;
        }
    } catch (err) {
        console.error('Erreur lors de la vérification d\'authentification :', err);
        redirectToLogin();
        return null;
    }
}

// Redirige vers la page de connexion
function redirectToLogin() {
    window.location.href = 'connexion.html';
}

// Lance la vérification au chargement de la page
document.addEventListener('DOMContentLoaded', async () => {
    const user = await verifyAndLoadUser();
    if (user) {
        // Optionnel : faire quelque chose avec les infos utilisateur
        console.log('Utilisateur connecté :', user);
        // On peut aussi déclencher un événement personnalisé pour que d'autres scripts l'utilisent
        window.dispatchEvent(new CustomEvent('userLoaded', { detail: user }));
    }
});

// Fonction utilitaire : effectuer une requête API avec le token
async function apiCall(endpoint, method = 'GET', body = null) {
    const token = getToken();

    if (!token) {
        redirectToLogin();
        return null;
    }

    const options = {
        method,
        headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
        },
    };

    if (body) {
        options.body = JSON.stringify(body);
    }

    try {
        const response = await fetch(`${API_BASE}${endpoint}`, options);

        if (response.status === 401) {
            // Token invalide, rediriger
            clearToken();
            redirectToLogin();
            return null;
        }

        return response;
    } catch (err) {
        console.error('Erreur API :', err);
        throw err;
    }
}

// Fonction utilitaire : déconnexion
async function logout() {
    try {
        await fetch(`${API_BASE}/logout`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${getToken()}`,
            },
        });
    } catch (err) {
        console.error('Erreur lors de la déconnexion :', err);
    }

    clearToken();
    window.location.href = 'connexion.html';
}
