import 'dart:ui';

/// Palette officielle SIC — basee sur le mockup dashboard valide par le client.
class AppColors {
  const AppColors._();

  // Marque
  static const primary = Color(0xFF1A73E8); // Sky blue (nav actif, bottom nav)
  static const primaryLight = Color(0xFF4285F4); // gradient hero, liens, retrait
  static const primaryBg = Color(0xFFE8F0FE); // fond cards actions bleu
  static const secondary = Color(0xFF1B8C5E); // depot, avatar, recharge
  static const secondaryBg = Color(0xFFE8F5EF); // fond cards actions vert

  // Etats
  static const success = Color(0xFF22C97A); // gain, statut OK, pip nav
  static const warning = Color(0xFFF59E0B); // solde faible, fond card jaune
  static const danger = Color(0xFFEF4444); // solde vide, badge alerte

  // Surfaces
  static const background = Color(0xFFF4F7FC); // fond general app
  static const surface = Color(0xFFFFFFFF); // fond cards
  static const surfaceLow = Color(0xFFFFFDE7); // fond card SIM solde faible

  // Texte
  static const textPrimary = Color(0xFF0D1B2A); // titres, montants, labels
  static const textSecondary = Color(0xFF64748B); // sous-titres, numeros SIM
  static const textTertiary = Color(0xFF94A3B8); // nav inactif, placeholders
  static const onPrimary = Color(0xFFFFFFFF);

  // Bordures
  static const border = Color(0xFFDCE6F0); // bordures legeres
  static const cardBorder = border; // alias historique

  // --- Gradients Premium ---
  static const primaryGradient = [
    Color(0xFF1A73E8), // Sky blue
    Color(0xFF4285F4), // Light sky blue
  ];

  static const heroGradient = [
    Color(0xFF1A73E8), // Primary Sky Blue
    Color(0xFF0D47A1), // Deep Royal Blue
  ];

  // Gradients par opérateur mobile (Harmonisés en nuances Bleu SIC)
  static const orangeGradient = [
    Color(0xFF1E3A8A), // Deep Navy Blue
    Color(0xFF2563EB), // Vibrant Royal Blue
  ];
  static const mtnGradient = [
    Color(0xFF0284C7), // Sky Navy Blue
    Color(0xFF0EA5E9), // Light Sky Blue
  ];
  static const moovGradient = [
    Color(0xFF0F172A), // Slate Navy
    Color(0xFF1E3A8A), // Deep Blue
  ];
  static const telecelGradient = [
    Color(0xFF1D4ED8), // Royal Blue
    Color(0xFF3B82F6), // Blue Accent
  ];

  // Surfaces de verre (Glassmorphism)
  static const glassSurface = Color(0x1EFFFFFF);
  static const glassBorder = Color(0x2BFFFFFF);

  // --- Alias de compatibilite (anciens tokens encore references) ---
  static const accent = warning;
  static const emerald = secondary;
  static const gradientStart = primary;
  static const gradientMid = primaryLight;
  static const gradientEnd = secondary;
  static const surfaceMuted = primaryBg;
}
