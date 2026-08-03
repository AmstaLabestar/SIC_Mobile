import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/biometric_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/avatar_provider.dart';

/// Ecran "Mon compte" : profil de l'agent + acces parametres / securite /
/// deconnexion.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isClient = user?.isClient ?? false;
    // Un CLIENT n'a pas de profil agent (puces/float) : on s'appuie sur AuthUser
    // et on masque le code agent + le badge "Verifie" agent.
    final summary =
        isClient ? null : ref.watch(dashboardNotifierProvider).valueOrNull;
    final name = user?.fullName ?? summary?.agentName ?? 'Compte SIC';
    final code = isClient ? '' : (summary?.agentCode ?? '—');
    final initials = summary?.agentInitials ?? _initialsFrom(name);
    final tier = user?.kycTier ?? 0;
    final kycSubmitted = user?.kycSubmitted ?? false;
    final avatarPath = ref.watch(avatarProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Mon compte', 
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileHeader(
              name: name,
              code: code,
              initials: initials,
              avatarPath: avatarPath,
              showVerified: !isClient,
            ),
            const SizedBox(height: AppSpacing.md),
            _LimitsCard(
              tier: tier,
              kycSubmitted: kycSubmitted,
            ),
            const SizedBox(height: AppSpacing.md),
            
            _GroupedSection(
              title: 'Paramètres généraux',
              children: [
                _SettingsTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Vérification d\'identité',
                  subtitle: kycSubmitted 
                      ? 'Dossier en cours de vérification'
                      : tier >= 2
                          ? 'Identité vérifiée — Palier maximum'
                          : 'Valider votre dossier d\'identité',
                  onTap: () => context.push('/kyc'),
                ),
                _SettingsTile(
                  icon: Icons.settings_suggest_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Paramètres',
                  subtitle: 'Préférences de l\'application',
                  onTap: () => context.push('/dashboard/settings'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _GroupedSection(
              title: 'Sécurité & Accès',
              children: [
                const _BiometricTile(),
                _SettingsTile(
                  icon: Icons.lock_person_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Sécurité',
                  subtitle: 'Code PIN et sessions',
                  onTap: () => context.push('/securite'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            _GroupedSection(
              title: 'Compte',
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.danger,
                  title: 'Déconnexion',
                  subtitle: 'Fermer la session en toute sécurité',
                  danger: true,
                  onTap: () => _confirmLogout(context, ref),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'SIC Mobile · v1.0.0',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous fermer votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'SIC';
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'SIC' : letters;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.code,
    required this.initials,
    this.avatarPath,
    this.showVerified = true,
  });

  final String name;
  final String code;
  final String initials;
  final String? avatarPath;
  final bool showVerified;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: avatarPath != null && avatarPath!.isNotEmpty && File(avatarPath!).existsSync()
                  ? Image.file(
                      File(avatarPath!),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    )
                  : Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.primaryGradient,
                        ),
                      ),
                      child: Text(
                        initials,
                        style: AppTextStyles.avatarInitials.copyWith(fontSize: 22),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                showVerified
                    ? Row(
                        children: [
                          Text(
                            code, 
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Vérifié',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Client',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  const _LimitsCard({required this.tier, required this.kycSubmitted});

  final int tier;
  final bool kycSubmitted;

  @override
  Widget build(BuildContext context) {
    final String limitFormatted = tier == 0
        ? '200 000 FCFA'
        : tier == 1
            ? '500 000 FCFA'
            : '2 000 000 FCFA';

    final double progress = tier == 0
        ? 0.1
        : tier == 1
            ? 0.5
            : 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Limites de transaction',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Palier $tier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plafond quotidien',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                limitFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  kycSubmitted
                      ? 'Vérification du dossier en cours…'
                      : tier < 2
                          ? 'Vérifiez votre identité pour augmenter vos plafonds.'
                          : 'Plafonds maximaux débloqués.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ),
              if (!kycSubmitted && tier < 2) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => context.push('/kyc'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Vérifier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupedSection extends StatelessWidget {
  const _GroupedSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.8,
                      color: Color(0xFFF1F5F9),
                      indent: 54,
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final finalColor = danger ? AppColors.danger : iconColor;

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: finalColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: finalColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: danger ? AppColors.danger : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricTile extends ConsumerStatefulWidget {
  const _BiometricTile();

  @override
  ConsumerState<_BiometricTile> createState() => _BiometricTileState();
}

class _BiometricTileState extends ConsumerState<_BiometricTile> {
  bool? _available;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bio = ref.read(biometricRepositoryProvider);
    final available = await bio.isAvailable();
    final enabled = available && await bio.isEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    final bio = ref.read(biometricRepositoryProvider);
    String? error;
    if (value) {
      final result = await bio.enable();
      error = result.fold((f) => f.message, (_) => null);
    } else {
      await bio.disable();
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) _enabled = value;
    });
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    final subtitle = available == null
        ? 'Vérification...'
        : !available
            ? 'Indisponible sur cet appareil'
            : _enabled
                ? 'Activée — empreinte pour connexion'
                : 'Désactivée — utiliser l\'empreinte';

    final finalColor = const Color(0xFF8B5CF6);

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: finalColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fingerprint_rounded, color: finalColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connexion biométrique',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_busy)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: _enabled,
              activeColor: AppColors.success,
              onChanged: (available ?? false) ? _toggle : null,
            ),
        ],
      ),
    );
  }
}

