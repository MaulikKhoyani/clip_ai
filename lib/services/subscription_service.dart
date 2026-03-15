import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const entitlementId = 'pro_access';
  static const maxFreeTemplates = 3;

  // Set to true after Purchases.configure() is called in main.dart
  static bool _configured = false;
  static bool get isConfigured => _configured;
  static void markConfigured() => _configured = true;

  Future<bool> get isProUser async {
    if (!_configured) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> loginUser(String userId) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  Future<void> logoutUser() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  // ── Feature gates ──

  bool canExportHD({required bool isPro}) => isPro;

  bool canRemoveWatermark({required bool isPro}) => isPro;

  bool canUseBackgroundRemoval({required bool isPro}) => isPro;

  bool canAccessAllTemplates({required bool isPro}) => isPro;
}
