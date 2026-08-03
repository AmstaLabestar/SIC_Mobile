import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/avatar_provider.dart';

/// Ecran "Profil" en lecture seule avec photo de profil modifiable.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _kycLabels = {0: 'Starter', 1: 'Verifie', 2: 'Complet'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isAgent = user?.isAgent ?? false;
    final summary = isAgent
        ? ref.watch(dashboardNotifierProvider).valueOrNull
        : null;
    final avatarPath = ref.watch(avatarProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // Avatar interactif pour modifier la photo
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.08),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(48),
                          child: avatarPath != null && avatarPath.isNotEmpty && File(avatarPath).existsSync()
                              ? Image.file(
                                  File(avatarPath),
                                  fit: BoxFit.cover,
                                  width: 96,
                                  height: 96,
                                )
                              : Center(
                                  child: Text(
                                    user?.firstName.isNotEmpty ?? false
                                        ? user!.firstName[0].toUpperCase()
                                        : 'S',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () => _showImageSourceSheet(context, ref),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showImageSourceSheet(context, ref),
                    child: Text(
                      avatarPath == null ? 'Ajouter une photo' : 'Modifier la photo',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _Section(
              title: 'Identite',
              rows: [
                _Row('Nom complet', user?.fullName ?? '—'),
                _Row('Type de compte', isAgent ? 'Agent (PDV)' : 'Client'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Contact',
              rows: [
                _Row('Telephone', user?.phoneNumber ?? '—'),
                _Row('Email', user?.email ?? '—'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Section(
              title: 'Compte',
              rows: [
                if (isAgent)
                  _Row('Code marchand', summary?.agentCode ?? '—'),
                _Row(
                  'Palier KYC',
                  user == null
                      ? '—'
                      : 'Palier ${user.kycTier} — ${_kycLabels[user.kycTier] ?? ''}',
                ),
                _Row('Statut KYC', _kycStatusLabel(user?.kycStatus)),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Pour modifier ces informations, contactez le support SIC.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, WidgetRef ref) {
    final avatarPath = ref.read(avatarProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Photo de profil',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              ),
              title: const Text('Choisir depuis la galerie', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.of(context).pop();
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await ref.read(avatarProvider.notifier).setAvatar(picked.path);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              ),
              title: const Text('Prendre une photo', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.of(context).pop();
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await ref.read(avatarProvider.notifier).setAvatar(picked.path);
                }
              },
            ),
            if (avatarPath != null) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                ),
                title: const Text('Supprimer la photo', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(avatarProvider.notifier).clearAvatar();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _kycStatusLabel(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'APPROVED':
        return 'Verifie';
      case 'SUBMITTED':
        return 'En cours de verification';
      case 'REJECTED':
        return 'Refuse';
      default:
        return 'Non verifie';
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.microLabel),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTextStyles.caption),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
