import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> with WidgetsBindingObserver {
  late final Box _box;
  bool _permissionGranted = false;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _box = Hive.box('settings');
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check permission when user returns from system settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.instance.isPermissionGranted();
    if (mounted) {
      setState(() {
        _permissionGranted = granted;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!granted && mounted) {
      // User denied — send them to system settings
      await ph.openAppSettings();
    }
    await _checkPermission();
  }

  bool _getPref(String key, {bool defaultValue = true}) =>
      _box.get(key, defaultValue: defaultValue) as bool;

  Future<void> _setPref(String key, bool value) async {
    await _box.put(key, value);
    setState(() {});
  }

  bool get _masterEnabled => _getPref(NotifPrefs.enabled);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Iconsax.arrow_left,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _checkingPermission
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                if (!_permissionGranted) _buildPermissionBanner(),
                const SizedBox(height: 16),
                _buildSectionTitle('General'),
                const SizedBox(height: 12),
                _buildMasterToggle(),
                const SizedBox(height: 28),
                _buildSectionTitle('Notification Types'),
                const SizedBox(height: 12),
                _buildToggleTile(
                  icon: Iconsax.export_1,
                  iconColor: AppColors.primary,
                  title: 'Export Complete',
                  subtitle: 'Get notified when your video export finishes',
                  prefKey: NotifPrefs.exportComplete,
                  enabled: _masterEnabled && _permissionGranted,
                ),
                _buildToggleTile(
                  icon: Iconsax.video_play,
                  iconColor: const Color(0xFF00E676),
                  title: 'New Templates',
                  subtitle: 'Be the first to know about new video templates',
                  prefKey: NotifPrefs.newTemplates,
                  enabled: _masterEnabled && _permissionGranted,
                ),
                _buildToggleTile(
                  icon: Iconsax.discount_shape,
                  iconColor: AppColors.proBadge,
                  title: 'Promotions & Offers',
                  subtitle: 'Special deals and limited-time discounts',
                  prefKey: NotifPrefs.promotions,
                  enabled: _masterEnabled && _permissionGranted,
                ),
                if (Platform.isAndroid) ...[
                  const SizedBox(height: 28),
                  _buildSectionTitle('System'),
                  const SizedBox(height: 12),
                  _buildOpenSettingsTile(),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.notification_status,
            color: AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are disabled',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable notifications to stay updated.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _requestPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Enable',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardDark.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'All Notifications',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Master switch for all push notifications',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        value: _masterEnabled && _permissionGranted,
        onChanged: _permissionGranted
            ? (val) => _setPref(NotifPrefs.enabled, val)
            : null,
        activeColor: AppColors.primary,
        inactiveThumbColor: AppColors.textTertiary,
        inactiveTrackColor: AppColors.cardDark,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String prefKey,
    required bool enabled,
  }) {
    final isOn = _getPref(prefKey) && enabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.cardDark.withValues(alpha: 0.5),
          ),
        ),
        child: SwitchListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          secondary: Container(
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
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
          value: isOn,
          onChanged: enabled ? (val) => _setPref(prefKey, val) : null,
          activeColor: AppColors.primary,
          inactiveThumbColor: AppColors.textTertiary,
          inactiveTrackColor: AppColors.cardDark,
        ),
      ),
    );
  }

  Widget _buildOpenSettingsTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ph.openAppSettings(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.cardDark.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Iconsax.setting_2,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Open System Settings',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
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
}
