import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'package:clip_ai/domain/entities/user_entity.dart';
import 'package:clip_ai/presentation/auth/bloc/auth_bloc.dart';
import 'package:clip_ai/presentation/auth/bloc/auth_event.dart';
import 'package:clip_ai/presentation/auth/bloc/auth_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/auth');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDark,
          surfaceTintColor: Colors.transparent,
          title: Text(
            AppStrings.settings,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                _buildProfileCard(context, user),
                const SizedBox(height: 28),
                _buildSectionTitle('Account'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Iconsax.user,
                  title: AppStrings.profile,
                  iconColor: AppColors.primary,
                  onTap: () => _showEditProfileSheet(context, user),
                ),
                _SettingsTile(
                  icon: Iconsax.crown_1,
                  title: AppStrings.subscription,
                  iconColor: AppColors.proBadge,
                  trailing: user?.isPro == true
                      ? _ProBadge()
                      : Text(
                          'Free',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                  onTap: () => context.push('/paywall'),
                ),
                _SettingsTile(
                  icon: Iconsax.notification,
                  title: AppStrings.notifications,
                  iconColor: AppColors.accent,
                  onTap: () => context.push('/notification-settings'),
                ),
                const SizedBox(height: 28),
                _buildSectionTitle('App'),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Iconsax.star,
                  title: AppStrings.rateApp,
                  iconColor: const Color(0xFFFFD740),
                  onTap: () => _rateApp(),
                ),
                _SettingsTile(
                  icon: Iconsax.share,
                  title: AppStrings.shareApp,
                  iconColor: const Color(0xFF00E676),
                  onTap: () => _shareApp(),
                ),
                _SettingsTile(
                  icon: Iconsax.message_question,
                  title: AppStrings.helpSupport,
                  iconColor: AppColors.info,
                  onTap: () => _openHelpSupport(),
                ),
                const SizedBox(height: 28),
                _buildSectionTitle(AppStrings.aboutApp),
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Iconsax.info_circle,
                  title: AppStrings.version,
                  iconColor: AppColors.textTertiary,
                  trailing: Text(
                    '1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Iconsax.document_text,
                  title: AppStrings.termsOfService,
                  iconColor: AppColors.textTertiary,
                  onTap: () => launchUrl(
                    Uri.parse('https://clipai.app/terms'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                _SettingsTile(
                  icon: Iconsax.shield_tick,
                  title: AppStrings.privacyPolicy,
                  iconColor: AppColors.textTertiary,
                  onTap: () => launchUrl(
                    Uri.parse('https://clipai.app/privacy'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSignOutButton(context),
                const SizedBox(height: 16),
                _buildDeleteAccountButton(context),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserEntity? user) {
    final name = user?.displayName ?? 'User';
    final email = user?.email ?? '';
    final isPro = user?.isPro ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceDark,
            AppColors.cardDark.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.accent.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              if (isPro)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.proBadgeGradientStart,
                          AppColors.proBadgeGradientEnd,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.backgroundDark,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Iconsax.crown_1,
                      size: 10,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isPro)
            GestureDetector(
              onTap: () => context.push('/paywall'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.goPro,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserEntity? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _EditProfileSheet(currentName: user?.displayName ?? ''),
      ),
    );
  }

  Future<void> _rateApp() async {
    // Replace with your actual App Store / Play Store ID
    final uri = Uri.parse(
      'https://apps.apple.com/app/clipai/id0000000000',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Create amazing short videos with ClipAI! Download now: https://clipai.app',
      subject: 'ClipAI — Create Crazy Videos in Seconds',
    );
  }

  Future<void> _openHelpSupport() async {
    final uri = Uri.parse('mailto:support@clipai.app?subject=ClipAI Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(
        Uri.parse('https://clipai.app/support'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _buildSignOutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              AppStrings.signOut,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            content: Text(
              'Are you sure you want to sign out?',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.cancel,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(AuthSignOutRequested());
                },
                child: Text(
                  AppStrings.signOut,
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            AppStrings.signOut,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              AppStrings.deleteAccount,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            content: Text(
              'This will permanently delete your account and all your data. This action cannot be undone.',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppStrings.cancel,
                  style: GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(AuthDeleteAccountRequested());
                },
                child: Text(
                  AppStrings.deleteAccount,
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Center(
        child: Text(
          AppStrings.deleteAccount,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textTertiary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  final String currentName;
  const _EditProfileSheet({required this.currentName});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSaving = true);
    context.read<AuthBloc>().add(AuthUpdateProfile(displayName: name));
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.displayName,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundDark,
              hintText: 'Your display name',
              hintStyle: GoogleFonts.inter(color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.cardDark.withValues(alpha: 0.6),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.cardDark.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppStrings.save,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: trailing ??
              Icon(
                Iconsax.arrow_right_3,
                color: AppColors.textTertiary,
                size: 18,
              ),
        ),
      ),
    );
  }
}

class _ProBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.proBadgeGradientStart,
            AppColors.proBadgeGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'PRO',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.black,
        ),
      ),
    );
  }
}
