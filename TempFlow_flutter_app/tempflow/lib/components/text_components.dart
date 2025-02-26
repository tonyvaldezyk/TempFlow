import 'package:flutter/material.dart';
import '../utils/colors.dart';

class TextComponents {
  static Text titleText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  static Text subtitleText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
      ),
    );
  }

  static Text bodyText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
  }

  static Text errorText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.error,
      ),
    );
  }
}
