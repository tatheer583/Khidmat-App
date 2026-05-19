import 'package:flutter/material.dart';

class AppColors {
  // Design tokens — terracotta accent (#e06a4a from Figma handoff)
  static const Color accent = Color(0xFFE06A4A);
  static const Color accentDeep = Color(0xFFA04A2E);
  static const Color gold = Color(0xFFD4A857);

  // Backwards-compat aliases used by existing screens
  static const Color primary = accent;
  static const Color primaryDark = accentDeep;
  static const Color primaryLight = Color(0xFFFF9B7D);
  static const Color primaryContainer = Color(0xFF3D1A0E);
  static const Color onPrimary = Color(0xFF1A0A05);
  static const Color onPrimaryContainer = Color(0xFFFFB59D);

  // Backgrounds
  static const Color background = Color(0xFF0A0C0F);
  static const Color surface = Color(0xFF14181D);
  static const Color surfaceElevated = Color(0xFF14181D);
  static const Color surfaceCard = Color(0xFF1C2128);
  static const Color surfaceHighest = Color(0xFF242B33);
  static const Color divider = Color(0x14F1EDE4);

  // Lines
  static const Color line = Color(0x14F1EDE4);   // 8% opacity of text
  static const Color line2 = Color(0x24F1EDE4);  // 14% opacity of text

  // Text
  static const Color textPrimary = Color(0xFFF1EDE4);
  static const Color textSecondary = Color(0xFFB8BCC2);
  static const Color textMuted = Color(0xFF6E747C);
  static const Color textOnDark = Color(0xFFF1EDE4);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Agent Identity (unchanged — used by logs/negotiation screens)
  static const Color agentFaham = Color(0xFF3B82F6);
  static const Color agentFahamBg = Color(0xFF0D1C35);
  static const Color agentFahamGlow = Color(0x4D3B82F6);

  static const Color agentDhoond = Color(0xFFF59E0B);
  static const Color agentDhoondBg = Color(0xFF2A1D00);
  static const Color agentDhoondGlow = Color(0x4DF59E0B);

  static const Color agentBharosa = Color(0xFF10B981);
  static const Color agentBharosaBg = Color(0xFF052918);
  static const Color agentBharosaGlow = Color(0x4D10B981);

  static const Color agentMolBhaav = Color(0xFF8B5CF6);
  static const Color agentMolBhaavBg = Color(0xFF1A0D35);
  static const Color agentMolBhaavGlow = Color(0x4D8B5CF6);

  static const Color agentBook = Color(0xFF14B8A6);
  static const Color agentBookBg = Color(0xFF042520);
  static const Color agentBookGlow = Color(0x4D14B8A6);

  static const Color agentYaadDahani = Color(0xFFF97316);
  static const Color agentYaadDahaniBg = Color(0xFF2A1000);
  static const Color agentYaadDahaniGlow = Color(0x4DF97316);

  // Trust
  static const Color trustHigh = Color(0xFF10B981);
  static const Color trustMedium = Color(0xFFF59E0B);
  static const Color trustLow = Color(0xFFEF4444);

  // Glass
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassOverlay = Color(0x80000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE06A4A), Color(0xFFA04A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF14100E), Color(0xFF0D0F12)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2128), Color(0xFF14181D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD4A857), Color(0xFF8A6A30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient agentGradient(Color color) => LinearGradient(
    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
