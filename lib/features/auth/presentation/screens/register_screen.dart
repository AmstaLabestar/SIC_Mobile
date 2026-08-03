import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radii.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/fade_slide_in.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../core/widgets/sic_button.dart';
import '../../../../core/widgets/sic_phone_field.dart';
import '../../../../core/widgets/sic_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/pin_header.dart';
import '../widgets/pin_keypad.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.isAgent});

  final bool isAgent;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _otpLength = 6;
  static const _resendSeconds = 60;

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _merchantCode = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  // Type de compte choisi a l'inscription (lot D1).
  late bool _isAgent;

  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _isAgent = widget.isAgent;
  }

  @override
  void didUpdateWidget(RegisterScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAgent != widget.isAgent) {
      _isAgent = widget.isAgent;
    }
  }

  void _nextStep() {
    if (_submitting) return;
    if (_currentStepIndex == 0) {
      if (!(_step0Key.currentState?.validate() ?? false)) return;
      _goToStep(1);
    } else if (_currentStepIndex == 1) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;
      _goToStep(2);
    } else if (_currentStepIndex == 2) {
      if (!(_step2Key.currentState?.validate() ?? false)) return;
      _continue();
    }
  }

  void _prevStep() {
    if (_submitting || _currentStepIndex <= 0) return;
    _goToStep(_currentStepIndex - 1);
  }

  void _goToStep(int step) {
    setState(() => _currentStepIndex = step);
  }

  bool _submitting = false;
  String? _error;

  // Phase 2 (OTP)
  bool _otpPhase = false;
  String _otp = '';
  bool _otpError = false;
  String? _devCode; // code expose par le backend en DEBUG (helper dev)
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _username.dispose();
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _merchantCode.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  String get _emailValue => _email.text.trim();

  // --- Phase 1 : formulaire -> envoi OTP --------------------------------

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });
    HapticFeedback.selectionClick();

    final normalizedPhone = Validators.normalizePhone(_phone.text.trim());
    final result = await ref.read(authControllerProvider.notifier).sendOtp(
          phoneNumber: normalizedPhone,
        );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = result.error;
      if (result.error == null) {
        _otpPhase = true;
        _otp = '';
        _otpError = false;
        _devCode = result.devCode;
      }
    });
    if (result.error == null) _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn -= 1);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resendIn > 0) return;
    final normalizedPhone = Validators.normalizePhone(_phone.text.trim());
    final result = await ref.read(authControllerProvider.notifier).sendOtp(
          phoneNumber: normalizedPhone,
        );
    if (!mounted) return;
    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }
    setState(() {
      _otp = '';
      _otpError = false;
      _error = null;
      _devCode = result.devCode;
    });
    _startResendTimer();
  }

  // --- Phase 2 : OTP -> inscription -------------------------------------

  void _onDigit(String d) {
    if (_submitting || _otp.length >= _otpLength) return;
    setState(() {
      _otpError = false;
      _error = null;
      _otp += d;
    });
    if (_otp.length == _otpLength) {
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted) _register();
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

  Future<void> _register() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref.read(authControllerProvider.notifier).register(
          username: _username.text.trim(),
          email: _emailValue,
          password: _password.text,
          passwordConfirm: _passwordConfirm.text,
          phoneNumber: Validators.normalizePhone(_phone.text.trim()),
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          otp: _otp,
          accountType: _isAgent ? 'AGENT' : 'CLIENT',
          merchantCode: _isAgent ? _merchantCode.text.trim() : '',
        );

    if (!mounted) return;
    if (error == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Inscription reussie. Connectez-vous pour continuer.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      context.go('/login');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _otpPhase
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () {
                  if (_currentStepIndex > 0) {
                    setState(() {
                      _currentStepIndex -= 1;
                    });
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/register/select');
                    }
                  }
                },
              ),
            ),
      body: Stack(
        children: [
          if (!_otpPhase) ...[
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.04),
                ),
              ),
            ),
          ],
          _otpPhase ? _buildOtpPhase() : _buildFormPhase(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------

  Widget _buildOtpPhase() {
    final masked = _maskPhone(_phone.text.trim());
    return Column(
      children: [
        PinGradientHeader(
          icon: Icons.sms_outlined,
          title: 'Vérifiez votre téléphone',
          subtitle: _otpError
              ? (_error ?? 'Code incorrect.')
              : 'Entrez le code à 6 chiffres envoyé par SMS au\n$masked',
          subtitleError: _otpError,
          showBack: true,
          onBack: _submitting
              ? null
              : () => setState(() {
                    _otpPhase = false;
                    _error = null;
                  }),
          child: PinDots(
            count: _otp.length,
            max: _otpLength,
            error: _otpError,
            onLight: true,
          ),
        ),
        if (kDebugMode && _devCode != null) _buildDevBanner(),
        Expanded(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  Expanded(
                    child: PinKeypad(
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                      enabled: !_submitting,
                    ),
                  ),
                  TextButton(
                    onPressed: (_resendIn > 0 || _submitting) ? null : _resend,
                    child: Text(
                      _resendIn > 0
                          ? 'Renvoyer le code (${_resendIn}s)'
                          : 'Renvoyer le code',
                      style: AppTextStyles.caption.copyWith(
                        color: _resendIn > 0
                            ? AppColors.textTertiary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormPhase() {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FadeSlideIn(
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 100,
                                  width: 100,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withOpacity(0.08),
                                  ),
                                  child: Icon(
                                    _isAgent
                                        ? Icons.store_rounded
                                        : Icons.person_outline_rounded,
                                    color: AppColors.primary,
                                    size: 52,
                                  ),
                                ),
                                Text(
                                  _isAgent
                                      ? 'Inscription Agent'
                                      : 'Inscription Client',
                                  style: AppTextStyles.displayLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isAgent
                                      ? 'Compte agent : gérez vos SIM, le float et la compensation.'
                                      : 'Compte client : envoyez et recevez de l\'argent simplement.',
                                  style: AppTextStyles.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        // Visual Stepper Progress Bar
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 40),
                          child: Column(
                            children: [
                              _buildStepIndicator(),
                              const SizedBox(height: 8),
                              _buildStepLabel(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 70),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.03),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0.1, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ));
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildStepContent(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 140),
                      child: Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md),
                                    child: _ErrorBanner(message: _error!),
                                  ),
                          ),
                          _buildNavButtons(),
                          const SizedBox(height: AppSpacing.sm),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text.rich(
                              TextSpan(
                                text: 'J\'ai déjà un compte ?  ',
                                style: AppTextStyles.caption,
                                children: [
                                  TextSpan(
                                    text: 'Se connecter',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStepCircle(0),
          _buildStepLine(1),
          _buildStepCircle(1),
          _buildStepLine(2),
          _buildStepCircle(2),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index) {
    final isCompleted = index < _currentStepIndex;
    final isActive = index == _currentStepIndex;

    Color bgColor;
    Color borderColor;
    Widget content;

    if (isCompleted) {
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
      content = const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 14,
      );
    } else if (isActive) {
      bgColor = AppColors.primaryBg;
      borderColor = AppColors.primary;
      content = Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      );
    } else {
      bgColor = Colors.white;
      borderColor = AppColors.border;
      content = Text(
        '${index + 1}',
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: content,
    );
  }

  Widget _buildStepLine(int targetIndex) {
    final isPassed = _currentStepIndex >= targetIndex;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isPassed ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStepLabel() {
    final labels = [
      'Étape 1 sur 3 : Identifiants de connexion',
      'Étape 2 sur 3 : Informations personnelles',
      'Étape 3 sur 3 : Sécurisation du compte',
    ];
    return Text(
      labels[_currentStepIndex],
      style: AppTextStyles.microLabel.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildStepContent() {
    switch (_currentStepIndex) {
      case 0:
        return Form(
          key: _step0Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SicTextField(
                label: 'Identifiant',
                controller: _username,
                icon: Icons.alternate_email_rounded,
                hint: 'nom_utilisateur',
                textInputAction: TextInputAction.next,
                validator: _validateUsername,
              ),
              const SizedBox(height: AppSpacing.md),
              SicTextField(
                label: 'Email',
                controller: _email,
                icon: Icons.mail_outline_rounded,
                hint: 'agent@exemple.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _nextStep(),
                validator: _validateEmail,
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _step1Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SicTextField(
                      label: 'Prénom',
                      controller: _firstName,
                      icon: Icons.person_outline_rounded,
                      hint: 'Moussa',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SicTextField(
                      label: 'Nom',
                      controller: _lastName,
                      icon: Icons.person_outline_rounded,
                      hint: 'Koné',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SicPhoneField(
                label: 'Numéro de téléphone',
                controller: _phone,
                hint: '64 59 82 58',
                textInputAction:
                    _isAgent ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _isAgent ? null : (_) => _nextStep(),
                helperText: _isAgent
                    ? 'Ce numéro deviendra votre première SIM.'
                    : 'Numéro utilisé pour vos transferts.',
                validator: Validators.validateAnyPhone,
              ),
              if (_isAgent) ...[
                const SizedBox(height: AppSpacing.md),
                SicTextField(
                  label: 'Code marchand',
                  controller: _merchantCode,
                  icon: Icons.store_rounded,
                  hint: '8170275',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _nextStep(),
                  helperText:
                      'Votre numéro de caisse opérateur (validé ensuite par SIC).',
                  validator: (v) {
                    if (!_isAgent) return null;
                    if ((v ?? '').trim().isEmpty) {
                      return 'Code marchand requis pour un agent.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        );
      case 2:
        return Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SicTextField(
                label: 'Mot de passe',
                controller: _password,
                icon: Icons.lock_outline_rounded,
                hint: '••••••••',
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: _validatePassword,
              ),
              _PasswordStrengthBar(listenable: _password),
              const SizedBox(height: AppSpacing.md),
              SicTextField(
                label: 'Confirmer le mot de passe',
                controller: _passwordConfirm,
                icon: Icons.lock_outline_rounded,
                hint: '••••••••',
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _nextStep(),
                validator: (v) => (v != _password.text)
                    ? 'Les mots de passe ne correspondent pas.'
                    : null,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavButtons() {
    final isLast = _currentStepIndex == 2;
    return Row(
      children: [
        if (_currentStepIndex > 0) ...[
          Expanded(
            child: Pressable(
              onTap: _submitting ? null : _prevStep,
              pressedScale: 0.95,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  'Retour',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          flex: 2,
          child: SicButton(
            label: isLast ? 'Créer mon compte' : 'Continuer',
            isLoading: _submitting,
            onPressed: _nextStep,
          ),
        ),
      ],
    );
  }

  /// Bannière de confort dev (DEBUG uniquement) : affiche le code OTP renvoyé
  /// par le backend et le pré-remplit au toucher. Jamais compilée en release.
  Widget _buildDevBanner() {
    final code = _devCode!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitting
              ? null
              : () {
                  setState(() {
                    _otpError = false;
                    _otp = code;
                  });
                  _register();
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bug_report_outlined,
                    size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'DEV · code $code — toucher pour remplir',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 4) return phone;
    final end = phone.substring(phone.length - 4);
    return '${phone.substring(0, phone.length - 8)} •• •• $end';
  }

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 3) return 'Au moins 3 caracteres.';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) {
      return 'Lettres et chiffres uniquement.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email requis.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Email invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Au moins 8 caracteres.';
    return null;
  }
}

/// Indicateur de force du mot de passe : 4 segments qui se remplissent au fur
/// et a mesure de la saisie, avec une couleur qui passe du rouge au vert. Se
/// reconstruit en ecoutant le controleur du champ.
class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.listenable});

  final TextEditingController listenable;

  /// Score 0..4 selon longueur et variete de caracteres.
  int _score(String v) {
    if (v.isEmpty) return 0;
    var score = 0;
    if (v.length >= 8) score++;
    if (v.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(v) && RegExp(r'[a-z]').hasMatch(v)) score++;
    if (RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
      score++;
    }
    return score.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final value = listenable.text;
        if (value.isEmpty) {
          return const SizedBox(height: AppSpacing.sm);
        }
        final score = _score(value);
        const labels = ['Faible', 'Faible', 'Moyen', 'Bon', 'Excellent'];
        final colors = [
          AppColors.danger,
          AppColors.danger,
          AppColors.warning,
          AppColors.success,
          AppColors.success,
        ];
        final color = colors[score];
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < score ? color : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 6),
              ],
              const SizedBox(width: AppSpacing.sm),
              Text(
                labels[score],
                style: AppTextStyles.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
