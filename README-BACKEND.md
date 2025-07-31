# DALILI App Backend

Ce dossier contient le backend de l'application DALILI, qui sert d'interface entre l'application Flutter et Firebase.

## Configuration

1. **Installation des dépendances**

```bash
npm install
```

2. **Configuration de Firebase**

Pour connecter le backend à Firebase, vous devez obtenir un fichier de compte de service Firebase:

- Allez dans la console Firebase
- Sélectionnez votre projet (dalili-app-f4792)
- Allez dans Paramètres du projet > Comptes de service
- Cliquez sur "Générer une nouvelle clé privée"
- Sauvegardez le fichier JSON téléchargé en tant que `firebase-service-account.json` à la racine du projet

OU

- Créez un fichier `.env` à la racine du projet avec le contenu du fichier `.env.example`
- Remplacez les valeurs par vos informations Firebase

## Structure du projet

- `server.js` - Point d'entrée de l'application, configuration Express
- `index.js` - Routes API et logique métier
- `package.json` - Dépendances et scripts

## Routes disponibles

### Authentication

- `POST /api/auth/register` - Inscription d'un nouvel utilisateur
- `POST /api/auth/login` - Connexion d'un utilisateur existant

### Profil utilisateur

- `GET /api/user/profile/:uid` - Récupérer le profil utilisateur

### Formulaires médicaux

- `POST /api/medical/form` - Enregistrer un nouveau formulaire médical
- `GET /api/medical/history/:userId` - Récupérer l'historique des formulaires

## Déploiement sur Render

1. Créez un nouveau Web Service sur Render
2. Connectez votre dépôt GitHub
3. Utilisez les paramètres suivants:
   - **Nom**: dalili-backend
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
4. Ajoutez les variables d'environnement:
   - `PORT`: 3000 (Render va ignorer celle-ci et utiliser sa propre variable)
   - `FIREBASE_SERVICE_ACCOUNT`: Le contenu de votre fichier firebase-service-account.json en une seule ligne

## Intégration avec l'application Flutter

Dans l'application Flutter, assurez-vous que l'URL de l'API pointe vers votre backend Render:

```dart
// Dans votre code Flutter
final response = await http.post(
  Uri.parse('https://dalili-backend.onrender.com/api/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'email': email, 'password': password}),
);
```