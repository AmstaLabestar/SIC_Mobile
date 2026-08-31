import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/app_lock_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';
import '../widgets/pin_keypad.dart';
import '../../../../core/widgets/sic_logo.dart';

/// Ecran de verrouillage : l'agent saisit son code PIN pour deverrouiller
/// l'app (ouverture a froid ou retour d'arriere-plan apres inactivite).
///
/// Le PIN est verifie cote backend (`/auth/pin/verify/`). En cas de succes,
/// l'app se deverrouille et la garde de route redirige vers le tableau de bord.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  static const _pinLength = 4;

  String _pin = '';
  bool _error = false;
  bool _verifying = false;
  String? _message;
  bool _biometricReady = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  /// Si la biometrie est disponible ET activee, on l'affiche et on la propose
  /// automatiquement (palier P2 : deverrouillage privilegie, PIN en secours).
  Future<void> _initBiometric() async {
    final bio = ref.read(biometricRepositoryProvider);
    final available = await bio.isAvailable();
    final enabled = available && await bio.isEnabled();
    if (!mounted || !enabled) return;
    setState(() => _biometricReady = true);
    _unlockWithBiometric();
  }

  Future<void> _unlockWithBiometric() async {
    if (_verifying) return;
    final ok = await ref.read(biometricRepositoryProvider).unlock();
    if (!mounted) return;
    if (ok) {
      // Succes : la garde de route redirige automatiquement vers /dashboard.
      ref.read(appLockProvider.notifier).unlock();
    }
  }

  void _onDigit(String d) {
    if (_verifying || _pin.length >= _pinLength) return;
    setState(() {
      _error = false;
      _message = null;
      _pin += d;
    });
    if (_pin.length == _pinLength) {
      // Laisse la 4e pastille s'afficher avant la verification.
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) _verify();
      });
    }
  }

  void _onBackspace() {
    if (_verifying || _pin.isEmpty) return;
    setState(() {
      _error = false;
      _message = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final result =
        await ref.read(authControllerProvider.notifier).verifyPin(_pin);
    if (!mounted) return;
    if (result.error == null) {
      // Succes : la garde de route redirige automatiquement vers /dashboard.
      ref.read(appLockProvider.notifier).unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _verifying = false;
      _error = true;
      _message = result.error;
      _pin = '';
    });
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final greeting = (user != null && user.firstName.trim().isNotEmpty)
        ? 'Bonjour ${user.firstName}, saisissez votre code pour déverrouiller.'
        : 'Saisissez votre code pour déverrouiller l\'application.';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Header SIC dégradé bleu profond
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.heroGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SicLogo(size: 52, elevated: false),
                      const SizedBox(height: 12),
                      Text(
                        _error ? 'Code PIN incorrect' : 'Déverrouillage SIC',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error ? (_message ?? 'Réessayez.') : greeting,
                        style: TextStyle(
                          color: _error
                              ? const Color(0xFFFCA5A5)
                              : Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PinDots(
                        count: _pin.length,
                        max: _pinLength,
                        error: _error,
                        onLight: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pavé numérique
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: PinKeypad(
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                    enabled: !_verifying,
                  ),
                ),
              ),
            ),

            // Actions inférieures
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_biometricReady) ...[
                      TextButton.icon(
                        onPressed: _verifying ? null : _unlockWithBiometric,
                        icon: const Icon(Icons.fingerprint_rounded,
                            size: 20, color: AppColors.primary),
                        label: const Text(
                          'Empreinte',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    TextButton(
                      onPressed: () {
                        if (!_verifying) _logout();
                      },
                      child: const Text(
                        'PIN oublié ?',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: _verifying ? null : _logout,
                      icon: const Icon(Icons.logout_rounded,
                          size: 16, color: Color(0xFF64748B)),
                      label: const Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
