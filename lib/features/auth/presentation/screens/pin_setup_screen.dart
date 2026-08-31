import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/pin_rules.dart';
import '../../../../core/widgets/sic_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_header.dart';
import '../widgets/pin_keypad.dart';
import '../../../../core/widgets/sic_logo.dart';

enum _Phase { currentPin, enterPin, confirmPin, password }

/// Ecran de creation OU de changement du code PIN.
///
/// Creation (apres login si `has_pin=false`) : saisie du PIN, confirmation,
/// puis mot de passe du compte.
/// Changement (`isChange=true`, depuis Securite) : une etape supplementaire en
/// tete demande le PIN ACTUEL — exige par le backend pour modifier un PIN
/// existant (sinon un voleur ayant reset le mot de passe pourrait reposer un
/// PIN et vider les comptes).
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.isChange = false});

  /// true = modification d'un PIN existant (demande le PIN actuel d'abord).
  final bool isChange;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  /// PIN a longueur fixe (standard mobile money). Le backend accepte 4 a 6.
  static const _pinLength = 4;

  late _Phase _phase =
      widget.isChange ? _Phase.currentPin : _Phase.enterPin;
  String _currentPin = '';
  String _pin = '';
  String _confirm = '';
  bool _mismatch = false;
  // Message si le PIN saisi est trop simple (lot A6), sinon null.
  String? _weakPin;

  final _password = TextEditingController();
  final _passwordKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  String get _current {
    switch (_phase) {
      case _Phase.currentPin:
        return _currentPin;
      case _Phase.confirmPin:
        return _confirm;
      default:
        return _pin;
    }
  }

  void _onDigit(String d) {
    if (_current.length >= _pinLength) return;
    setState(() {
      _mismatch = false;
      _weakPin = null;
      switch (_phase) {
        case _Phase.currentPin:
          _currentPin += d;
        case _Phase.confirmPin:
          _confirm += d;
        default:
          _pin += d;
      }
    });
    // Auto-validation des que les 4 chiffres sont saisis (laisse la 4e
    // pastille s'afficher avant d'enchainer).
    if (_current.length == _pinLength) {
      final phase = _phase;
      Future.delayed(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        switch (phase) {
          case _Phase.currentPin:
            // Le PIN actuel est validé côté serveur à la soumission finale.
            setState(() => _phase = _Phase.enterPin);
          case _Phase.confirmPin:
            _validateConfirm();
          default:
            _goToConfirm();
        }
      });
    }
  }

  void _onBackspace() {
    if (_current.isEmpty) return;
    setState(() {
      _mismatch = false;
      _weakPin = null;
      switch (_phase) {
        case _Phase.currentPin:
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
        case _Phase.confirmPin:
          _confirm = _confirm.substring(0, _confirm.length - 1);
        default:
          _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  void _goToConfirm() {
    // Refuser un PIN trivial (lot A6) avant la confirmation.
    final weak = weakPinReason(_pin);
    if (weak != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _weakPin = weak;
        _pin = '';
      });
      return;
    }
    setState(() {
      _phase = _Phase.confirmPin;
      _confirm = '';
      _mismatch = false;
    });
  }

  void _validateConfirm() {
    if (_confirm != _pin) {
      HapticFeedback.heavyImpact();
      setState(() {
        _mismatch = true;
        _confirm = '';
      });
      return;
    }
    setState(() => _phase = _Phase.password);
  }

  Future<void> _submitPassword() async {
    FocusScope.of(context).unfocus();
    if (!_passwordKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    HapticFeedback.selectionClick();

    final error = await ref.read(authControllerProvider.notifier).setupPin(
          password: _password.text,
          pin: _pin,
          pinConfirm: _confirm,
          currentPin: widget.isChange ? _currentPin : null,
        );

    if (!mounted) return;
    // Mode changement : le claim hasPin est deja true, la garde ne redirige pas.
    // On confirme et on revient a l'ecran Securite.
    if (error == null && widget.isChange) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Code PIN modifié avec succès.'),
        ));
      context.go('/securite');
      return;
    }
    setState(() {
      _submitting = false;
      _error = error;
    });
    // Creation : le claim hasPin passe a true -> la garde de route redirige
    // automatiquement vers /dashboard.
  }

  void _onBack() {
    switch (_phase) {
      case _Phase.currentPin:
        // Mode changement : quitter vers Sécurité.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/securite');
        }
      case _Phase.enterPin:
        // Changement : revenir au PIN actuel. Création : étape initiale, pas de sortie.
        if (widget.isChange) {
          setState(() {
            _phase = _Phase.currentPin;
            _currentPin = '';
            _weakPin = null;
          });
        }
      case _Phase.confirmPin:
        setState(() {
          _phase = _Phase.enterPin;
          _confirm = '';
          _mismatch = false;
        });
      case _Phase.password:
        setState(() {
          _phase = _Phase.confirmPin;
          _error = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = widget.isChange || _phase != _Phase.enterPin;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canGoBack) _onBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: _phase == _Phase.password ? _passwordStep() : _pinStep(canGoBack),
      ),
    );
  }

  // --- Étapes PIN (Saisie / Confirmation) ---
  Widget _pinStep(bool canGoBack) {
    final isConfirm = _phase == _Phase.confirmPin;
    final isCurrentPin = _phase == _Phase.currentPin;
    final isError = _mismatch || _weakPin != null;
    final subtitle = _weakPin != null
        ? _weakPin!
        : _mismatch
            ? 'Les codes ne correspondent pas. Réessayez.'
            : isCurrentPin
                ? 'Entrez votre code secret actuel pour autoriser le changement.'
                : isConfirm
                    ? 'Saisissez à nouveau votre code à 4 chiffres.'
                    : widget.isChange
                        ? 'Choisissez votre nouveau code à 4 chiffres.'
                        : 'Choisissez un code secret à 4 chiffres pour valider vos opérations.';

    final String stepText;
    if (isCurrentPin) {
      stepText = 'Modification du code PIN';
    } else if (widget.isChange) {
      stepText = isConfirm ? 'Confirmation du nouveau code' : 'Nouveau code';
    } else {
      stepText = isConfirm ? 'Étape 2 sur 2 : Confirmation' : 'Étape 1 sur 2 : Création';
    }

    return Column(
      children: [
        // En-tête de marque SIC avec dégradé bleu profond
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (canGoBack)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: _onBack,
                        )
                      else
                        const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stepText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SicLogo(size: 52, elevated: false),
                  const SizedBox(height: 12),
                  Text(
                    isCurrentPin
                        ? 'Saisissez votre PIN actuel'
                        : isConfirm
                            ? (widget.isChange
                                ? 'Confirmez le nouveau code'
                                : 'Confirmez le code secret')
                            : (widget.isChange
                                ? 'Créez votre nouveau code'
                                : 'Créez votre code secret'),
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
                    subtitle,
                    style: TextStyle(
                      color: isError
                          ? const Color(0xFFFCA5A5)
                          : Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PinDots(
                    count: _current.length,
                    max: _pinLength,
                    error: isError,
                    onLight: true,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Clavier numérique responsive
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: PinKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Étape Validation par Mot de passe ---
  Widget _passwordStep() {
    return Column(
      children: [
        // En-tête de marque SIC
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                        onPressed: _onBack,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Étape 3 sur 3 : Sécurisation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const SicLogo(size: 52, elevated: false),
                  const SizedBox(height: 12),
                  const Text(
                    'Validation du Code PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Entrez le mot de passe de votre compte pour activer définitivement votre code secret.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _passwordKey,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mot de passe du compte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitPassword(),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: Color(0xFF64748B)),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Mot de passe requis.' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      PinErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 24),
                    SicButton(
                      label: 'Activer définitivement mon code PIN',
                      isLoading: _submitting,
                      onPressed: _submitPassword,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
