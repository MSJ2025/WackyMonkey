# WackyMonkey

Ce projet utilise Firebase pour l'analytics. Pour activer cette fonctionnalité sur iOS et Android :

1. Téléchargez les fichiers de configuration Firebase depuis la console :
   - `GoogleService-Info.plist` pour iOS
   - `google-services.json` pour Android
2. Copiez ces fichiers à la racine du projet **avant la compilation**.
3. Lors de l'export, assurez-vous que le plugin `FirebaseAnalytics` est activé dans l'éditeur (menu Plugins).

Les appels aux évènements sont effectués dans les scripts via `Firebase.Analytics.log_event()`.

