class BluetoothConstants {
  // Nom du périphérique
  static const String DEVICE_NAME = "ESP32_TempSensor";
  
  // Services UUID
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  
  // Caractéristiques
  static const String TEMPERATURE_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String BATTERY_CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  
  // Configuration
  static const int SCAN_TIMEOUT = 4; // secondes
  static const double TEMPERATURE_THRESHOLD = 30.0; // Seuil d'alerte en °C
  static const int REFRESH_INTERVAL = 2000; // ms (correspond à l'ESP32)
  
  // Format des données
  static const String TEMPERATURE_FORMAT = "SINT16"; // 0.01 °C
  static const String BATTERY_FORMAT = "UINT8"; // 0-100%
  
  // Messages d'erreur
  static const String ERROR_BLUETOOTH_OFF = "Le Bluetooth est désactivé";
  static const String ERROR_DEVICE_NOT_FOUND = "Périphérique non trouvé";
  static const String ERROR_CONNECTION_FAILED = "Échec de la connexion";
  static const String ERROR_READING_TEMPERATURE = "Erreur de lecture de température";
  static const String ERROR_READING_BATTERY = "Erreur de lecture de la batterie";
  static const String ERROR_PERMISSIONS_DENIED = "Permissions Bluetooth non accordées";
  static const String ERROR_BLUETOOTH_UNAVAILABLE = "Bluetooth non disponible sur cet appareil";
  static const String ERROR_SCAN_FAILED = "Erreur lors du scan";
}
