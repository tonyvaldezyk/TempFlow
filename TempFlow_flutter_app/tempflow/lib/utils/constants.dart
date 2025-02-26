class AppConstants {
  // App information
  static const String appName = 'TempFlow';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Control everything';
  
  // Navigation
  static const int splashDuration = 4; // secondes
  
  // Settings
  static const int dataRefreshInterval = 2; // seconds (match ESP32)
  static const double temperatureThreshold = 30.0; // °C
  
  // Storage keys
  static const String lastDeviceKey = 'last_device';
  static const String settingsKey = 'app_settings';
  
  // Messages
  static const String connectingMessage = 'Connexion en cours...';
  static const String connectedMessage = 'Connecté';
  static const String disconnectedMessage = 'Déconnecté';
  static const String highTempMessage = '⚠️ Température élevée';
  static const String lowBatteryMessage = '⚠️ Batterie faible';
  
  // Error messages
  static const String bluetoothError = 'Erreur Bluetooth';
  static const String deviceError = 'Erreur de connexion au capteur';
  static const String generalError = 'Une erreur est survenue';
  
  // Animations
  static const int fadeAnimationDuration = 1500; // millisecondes
  static const int transitionDuration = 800; // millisecondes
}
