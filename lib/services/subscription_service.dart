import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  static const entitlementId = 'pro_access';
  static const maxFreeTemplates = 3;

  /// Purchases is configured in main.dart during app startup.
  /// This method is kept as a hook for any additional RevenueCat setup.
  Future<void> initialize() async {
    // TODO: add any post-configure RevenueCat setup here
  }

  Future<bool> get isProUser async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo
          .entitlements.all[entitlementId]?.isActive ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> loginUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {
      // RevenueCat not configured — skip silently
    }
  }

  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
    } catch (_) {
      // RevenueCat not configured — skip silently
    }
  }

  // ── Feature gates ──

  bool canExportHD({required bool isPro}) => isPro;

  bool canRemoveWatermark({required bool isPro}) => isPro;

  bool canUseBackgroundRemoval({required bool isPro}) => isPro;

  bool canAccessAllTemplates({required bool isPro}) => isPro;
}
