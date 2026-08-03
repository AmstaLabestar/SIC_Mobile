import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_keypad.dart';

/// Validation d'un nouvel appareil (lot A4 - device binding).
/// Redessinée selon la charte graphique premium de l'application (fond blanc,
/// badge de sécurité centré, barre d'état adaptée et typographies harmonisées).
class DeviceVerifyScreen extends ConsumerStatefulWidget {
  const DeviceVerifyScreen({
    super.key,
    required this.identifier,
    required this.password,
    required this.email,
    this.otpCode,
  });

  /// Identifiant saisi au login (numéro de téléphone ou username).
  final String identifier;

  /// Mot de passe saisi au login (re-vérifié côté backend avec l'OTP).
  final String password;

  /// Numéro de téléphone masqué vers lequel l'OTP a été envoyé.
  final String email;

  /// Code de test temporaire renvoyé par l'API pour faciliter les tests.
  final String? otpCode;

  @override
  ConsumerState<DeviceVerifyScreen> createState() => _DeviceVerifyScreenState();
}

class _DeviceVerifyScreenState extends ConsumerState<DeviceVerifyScreen> {
  static const _otpLength = 6;

  String _otp = '';
  bool _otpError = false;
  bool _submitting = false;
  String? _error;

  void _onDigit(String d) {
    if (_submitting || _otp.length >= _otpLength) return;
    setState(() {
      _otpError = false;
      _error = null;
      _otp += d;
    });
    if (_otp.length == _otpLength) {
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) _verify();
      });
    }
  }

  void _onBackspace() {
    if (_submitting || _otp.isEmpty) return;
    setState(() {
      _otpError = false;
      _otp = _otp.substring(0, _otp.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref.read(authControllerProvider.notifier).verifyDevice(
          identifier: widget.identifier,
          password: widget.password,
          otp: _otp,
        );

    if (!mounted) return;
    if (error == null) {
      // Succès : la garde de route redirige vers /pin-setup, /lock ou /dashboard.
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _submitting = false;
      _otpError = true;
      _otp = '';
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Android (icônes sombres)
        statusBarBrightness: Brightness.light, // iOS (icônes sombres)
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Barre d'outils supérieure avec le bouton de retour premium
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                      onPressed: _submitting ? null : () => context.go('/login'),
                    ),
                  ],
                ),
              ),

              // Contenu principal (Badge de sécurité, Titres, Sous-titre et Dots)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    // Badge de sécurité premium
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _otpError
                            ? AppColors.danger.withOpacity(0.1)
                            : AppColors.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_rounded,
                        color: _otpError ? AppColors.danger : AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Titre principal
                    Text(
                      _otpError ? 'Code incorrect' : 'Nouvel appareil',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: _otpError ? AppColors.danger : AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Sous-titre indicatif / d'erreur
                    Text(
                      _otpError
                          ? (_error ?? 'Réessayez.')
                          : 'Pour votre sécurité, entrez le code à 6 chiffres\nenvoyé au ${widget.email}'
                              '${widget.otpCode != null && widget.otpCode!.isNotEmpty ? "\n\nCode de test : ${widget.otpCode}" : ""}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _otpError ? AppColors.danger : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Pastilles du code OTP
                    PinDots(
                      count: _otp.length,
                      max: _otpLength,
                      error: _otpError,
                      onLight: false, // Fond clair -> pastilles sombres
                    ),
                  ],
                ),
              ),

              // Pavé numérique de saisie
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: PinKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    enabled: !_submitting,
                  ),
                ),
              ),

              // Message de bas de page explicatif
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  'Ce code protège votre compte contre une connexion depuis un appareil inconnu.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
