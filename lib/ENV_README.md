# Configuration des variables d'environnement pour DALILI

## Configuration du fichier .env

1. **Créer le fichier .env**
   - Créez un fichier nommé `.env` à la racine du projet (au même niveau que pubspec.yaml)
   - Ajoutez votre clé API OpenAI dans ce fichier:
   ```
   OPENAI_API_KEY=sk-votre-nouvelle-cle-api
   ```
   - Ne mettez pas de guillemets autour de la valeur
   - Assurez-vous qu'il n'y a pas d'espaces avant ou après le signe égal

2. **Régénérer une nouvelle clé API**
   - Connectez-vous à votre compte OpenAI: https://platform.openai.com
   - Allez dans "API Keys" et créez une nouvelle clé
   - **IMPORTANT**: L'ancienne clé doit être considérée comme compromise et révoquée

## Test de la configuration

L'application démarrera automatiquement sur l'écran de test API.
1. Appuyez sur le bouton "TESTER LA CONNEXION"
2. Attendez le résultat du test
3. Si réussi, vous verrez un message de confirmation en vert
4. En cas d'échec, vérifiez les points suivants:
   - Le fichier `.env` est bien à la racine du projet
   - La clé API est correctement formatée
   - La clé API est valide et active

## Dépannage

Si vous rencontrez des erreurs:
- **"Clé API non définie"**: Vérifiez que le fichier .env existe et contient OPENAI_API_KEY
- **"Erreur API: 401"**: Votre clé API est invalide ou expirée
- **"Exception: SocketException"**: Problème de connexion Internet

## Retour à l'application principale

Une fois le test réussi:
1. Ouvrez `lib/main.dart`
2. Commentez la ligne `home: const ApiTestScreen(),`
3. Décommentez la ligne `// home: AuthScreen(),`
4. Redémarrez l'application

## Sécurité

- Ne partagez JAMAIS votre clé API
- Le fichier `.env` est dans `.gitignore` pour éviter qu'il ne soit commité
- Si vous travaillez en équipe, chaque membre doit créer son propre fichier `.env`
- En production, utilisez des variables d'environnement sécurisées