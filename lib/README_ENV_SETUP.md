# Configuration du fichier .env pour DALILI App

## Installation

1. Créez un fichier `.env` à la racine du projet
2. Ajoutez votre clé API OpenAI dans ce fichier avec le format suivant:
   ```
   OPENAI_API_KEY=sk-votre-cle-api-regeneree
   ```

## Comment tester la configuration

1. Ouvrez `lib/main.dart`
2. Décommentez la ligne `home: const ApiTestScreen(),` (ligne 95)
3. Commentez la ligne `home: AuthScreen(),` juste en dessous
4. Exécutez l'application avec `flutter run`
5. Appuyez sur le bouton "Tester la connexion à OpenAI API"
6. Vérifiez que le test est réussi

## Dépannage

Si vous rencontrez des problèmes:

1. **Vérifiez que le fichier `.env` est bien à la racine du projet** (même niveau que pubspec.yaml)
2. **Assurez-vous que la clé API est valide** et a été régénérée depuis l'exposition de l'ancienne clé
3. **Vérifiez le format** de la variable dans le fichier .env (pas de guillemets ou d'espaces)
4. **Exécutez `flutter clean` puis `flutter pub get`** pour réinitialiser le cache

## Sécurité

- Le fichier `.env` est configuré pour être ignoré par Git (dans .gitignore)
- Ne partagez JAMAIS votre clé API avec qui que ce soit
- Si vous soupçonnez que votre clé a été exposée, régénérez-en une nouvelle immédiatement

## Après les tests

Une fois les tests terminés, n'oubliez pas de:

1. Restaurer le code original dans `lib/main.dart` (commentez `ApiTestScreen` et décommentez `AuthScreen`)
2. Vérifier que l'application principale fonctionne correctement