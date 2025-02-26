import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03A9F4);
  static const Color accent = Color(0xFF00BCD4);
  static const Color background = Color(0xFFF5F5F5);
  
  // Couleurs correspondant aux LEDs de l'ESP32
  static const Color ledGreen = Color(0xFF4CAF50);    // LED température normale
  static const Color ledRed = Color(0xFFD32F2F);      // LED température haute
  static const Color disconnected = Color(0xFFFF5722); // État déconnecté
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Couleurs d'état
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
}
