import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:clip_ai/core/constants/app_colors.dart';
import 'package:clip_ai/core/constants/app_strings.dart';
import 'package:clip_ai/core/di/injection.dart';
import 'package:clip_ai/services/analytics_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1;
  bool _isLoadingOfferings = false;
  bool _isPurchasing = false;
  List<Package> _packages = [];

  static const _features = [
    'HD Export (1080p)',
    'No Watermark',
    'All Templates Unlocked',
    'Background Removal',
    'Advanced AI Captions',
    'Priority Support',
  ];

  static const _fallbackPlans = [
    _PlanData(title: 'Monthly', price: '\$9.99', period: '/month', badge: null),
    _PlanData(
      title: 'Yearly',
      price: '\$59.99',
      period: '/year',
      badge: AppStrings.bestValue,
    ),
    _PlanData(
      title: 'Lifetime',
      price: '\$99.99',
      period: ' one-time',
      badge: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
    getIt<AnalyticsService>().logPaywallShown(source: 'paywall_screen');
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoadingOfferings = true);
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && mounted) {
        setState(() {
          _packages = offerings.current!.availablePackages;
        });
      }
    } catch (_) {
      // Fall back to static plan data if RevenueCat is not yet configured
    } finally {
      if (mounted) setState(() => _isLoadingOfferings = false);
    }
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    final planTitle = _getPlanTitle(_selectedPlan);
    await getIt<AnalyticsService>().logPurchaseStarted(productId: planTitle);
    try {
      if (_packages.isNotEmpty && _selectedPlan < _packages.length) {
        final package = _packages[_selectedPlan];
        await Purchases.purchasePackage(package);
        await getIt<AnalyticsService>().logPurchaseCompleted(
          productId: planTitle,
          revenue: package.storeProduct.price,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You are now a Pro member!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          context.pop();
        }
      } else {
        // RevenueCat not configured — show informational message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Configure RevenueCat API keys to enable ${_getPlanTitle(_selectedPlan)} purchases.',
              ),
              backgroundColor: AppColors.surfaceDark,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (!msg.contains('cancel')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchase failed: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isActive =
          customerInfo.entitlements.all['pro_access']?.isActive ?? false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Pro access restored!'
                  : 'No active purchases found.',
            ),
            backgroundColor:
                isActive ? AppColors.success : AppColors.surfaceDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (isActive) context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to restore purchases.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  String _getPlanTitle(int index) {
    if (_packages.isNotEmpty && index < _packages.length) {
      switch (_packages[index].packageType) {
        case PackageType.monthly:
          return 'Monthly';
        case PackageType.annual:
          return 'Yearly';
        case PackageType.lifetime:
          return 'Lifetime';
        default:
          return _packages[index].identifier;
      }
    }
    return _fallbackPlans[index].title;
  }

  String _getPlanPrice(int index) {
    if (_packages.isNotEmpty && index < _packages.length) {
      return _packages[index].storeProduct.priceString;
    }
    return _fallbackPlans[index].price;
  }

  String _getPlanPeriod(int index) {
    if (_packages.isNotEmpty && index < _packages.length) {
      switch (_packages[index].packageType) {
        case PackageType.monthly:
          return '/month';
        case PackageType.annual:
          return '/year';
        case PackageType.lifetime:
          return ' one-time';
        default:
          return '';
      }
    }
    return _fallbackPlans[index].period;
  }

  String? _getPlanBadge(int index) {
    if (_packages.isNotEmpty && index < _packages.length) {
      return _packages[index].packageType == PackageType.annual
          ? AppStrings.bestValue
          : null;
    }
    return _fallbackPlans[index].badge;
  }

  int get _planCount =>
      _packages.isNotEmpty ? _packages.length : _fallbackPlans.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoadingOfferings
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildHeader(),
                              const SizedBox(height: 32),
                              _buildFeatureList(),
                              const SizedBox(height: 32),
                              _buildPlanCards(),
                              const SizedBox(height: 28),
                              _buildSubscribeButton(),
                              const SizedBox(height: 20),
                              _buildRestore(),
                              const SizedBox(height: 16),
                              _buildLegalLinks(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_isPurchasing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Positioned(
      top: -100,
      left: -50,
      right: -50,
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.25),
              AppColors.backgroundDark.withValues(alpha: 0.0),
            ],
            radius: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Iconsax.close_circle,
              color: AppColors.textSecondary,
              size: 28,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppColors.proBadgeGradientStart,
                AppColors.proBadgeGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.proBadge.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Iconsax.crown_1,
            color: Colors.black,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              AppColors.proBadgeGradientStart,
              AppColors.proBadgeGradientEnd,
            ],
          ).createShader(bounds),
          child: Text(
            AppStrings.goPro,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.unlockAllFeatures,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: _features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    feature,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCards() {
    return Column(
      children: List.generate(_planCount, (index) {
        final isSelected = _selectedPlan == index;
        final badge = _getPlanBadge(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.cardDark.withValues(alpha: 0.5),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: AppColors.textTertiary,
                              width: 2,
                            ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _getPlanTitle(index),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.proBadgeGradientStart,
                                  AppColors.proBadgeGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _getPlanPrice(index),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: _getPlanPeriod(index),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
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
      }),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isPurchasing ? null : _purchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Subscribe Now',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestore() {
    return TextButton(
      onPressed: _isPurchasing ? null : _restorePurchases,
      child: Text(
        AppStrings.restore,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse('https://clipai.app/terms'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            AppStrings.termsOfService,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '•',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => launchUrl(
            Uri.parse('https://clipai.app/privacy'),
            mode: LaunchMode.externalApplication,
          ),
          child: Text(
            AppStrings.privacyPolicy,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textTertiary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String title;
  final String price;
  final String period;
  final String? badge;

  const _PlanData({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
  });
}
