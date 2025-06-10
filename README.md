# WackyMonkey

Ce projet embarque un plugin `FirebaseAnalyticsMock` simplifié. Celui-ci se contente d'afficher les évènements dans la console et **n'envoie pas** d'informations à Firebase.

Pour voir ces logs sur iOS et Android :

1. Téléchargez les fichiers de configuration Firebase depuis la console :
   - `GoogleService-Info.plist` pour iOS
   - `google-services.json` pour Android
2. Copiez ces fichiers à la racine du projet **avant la compilation**.
3. Dans l'éditeur Godot, activez le plugin `FirebaseAnalyticsMock` (menu Plugins).

Les appels aux évènements sont effectués dans les scripts via `Firebase.Analytics.log_event()`.

## Utilisation du véritable module `godot-firebase`

Si vous souhaitez réellement envoyer les événements à Firebase :

1. Clonez le dépôt [GodotFirebase](https://github.com/GodotNuts/GodotFirebase) et copiez son dossier `addons/godot-firebase` dans ce projet.
2. Activez le plugin `Godot Firebase` dans l'éditeur.
3. Placez à la racine du projet les fichiers `GoogleService-Info.plist` et `google-services.json` téléchargés depuis la console Firebase.
4. Configurez ensuite vos exports Android et iOS selon la documentation du module (gradle, import dans Xcode, etc.).
