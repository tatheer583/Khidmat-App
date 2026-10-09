import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFFE06A4A);
  static const primary = accent;
  static const primaryLight = Color(0xFFFF9B7D);
  static const primaryContainer = Color(0xFF3D1A0E);
  static const onPrimary = Color(0xFF1A0A05);
  static const onPrimaryContainer = Color(0xFFFFB59D);
  static const background = Color(0xFF0A0C0F);
  static const surface = Color(0xFF14181D);
  static const surfaceElevated = surface;
  static const surfaceCard = Color(0xFF1C2128);
  static const surfaceHighest = Color(0xFF242B33);
  static const divider = Color(0x14F1EDE4);
  static const textPrimary = Color(0xFFF1EDE4);
  static const textSecondary = Color(0xFFB8BCC2);
  static const textMuted = Color(0xFF9099A6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF79ADFF);
  static const cardGradient = LinearGradient(
    colors: [surfaceCard, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
