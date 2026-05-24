import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:spokiai/payment/active_subscription_summary.dart';
import 'package:spokiai/payment/subscription_store_launcher.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/repository/app_repository.dart';

import 'SubscriptionService.dart';

enum _PremiumPlanTier { monthly, yearly }

/// Go Premium — matches subscription marketing layout (pricing display + store purchase).
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService.instance;

  bool _loading = true;
  _PremiumPlanTier _selected = _PremiumPlanTier.yearly;
  ActiveSubscriptionSummary? _serverSub;

  bool get _premiumFlag =>
      _serverSub?.hasActivePremium == true || _service.isSubscribed;

  BillingTier get _resolvedCurrentTier {
    if (_serverSub?.hasActivePremium == true) return _serverSub!.tier;
    return BillingTier.unknown;
  }

  static const Color _gold = Color(0xFFE6B422);
  static const Color _goldDeep = Color(0xFFB8860B);
  static const Color _lavenderPremium = Color(0xFFB8A9FF);
  static const Color _headerPurpleTop = Color(0xFF2D1F5E);
  static const Color _headerPurpleBottom = Color(0xFF0C0A12);

  ProductDetails? get _monthlyProduct => _pickProduct(const [
        'montlhy_subs',
        'monthly_subs',
        'montlhy',
      ]);
  ProductDetails? get _yearlyProduct => _pickProduct(const [
        'yearly_subs',
        'yearly',
      ]);

  ProductDetails? _pickProduct(List<String> ids) {
    for (final id in ids) {
      final key = id.toLowerCase();
      try {
        return _service.products.firstWhere((p) => p.id.toLowerCase() == key);
      } catch (_) {}
    }
    return null;
  }

  /// Uses [ProductDetails.price] when non-empty; otherwise builds from rawPrice /
  /// currencySymbol (some SKUs omit the formatted label).
  static String formattedProductPrice(ProductDetails? p, String fallback) {
    if (p == null) return fallback;
    final label = p.price.trim();
    if (label.isNotEmpty) return label;
    final sym = p.currencySymbol.trim();
    if (p.rawPrice > 0 && sym.isNotEmpty) {
      return '$sym${_trimMoneyDecimals(p.rawPrice)}';
    }
    if (p.rawPrice > 0 && p.currencyCode.trim().isNotEmpty) {
      return '${_trimMoneyDecimals(p.rawPrice)} ${p.currencyCode.trim()}';
    }
    if (p.rawPrice > 0) {
      return _trimMoneyDecimals(p.rawPrice);
    }
    return fallback;
  }

  static String _trimMoneyDecimals(double raw) {
    if (raw == raw.roundToDouble()) return raw.round().toString();
    final s = raw.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  ProductDetails? _productForTier(_PremiumPlanTier tier) {
    switch (tier) {
      case _PremiumPlanTier.monthly:
        return _monthlyProduct;
      case _PremiumPlanTier.yearly:
        return _yearlyProduct;
    }
  }

  void _presetSelectionForPremiumSwitch() {
    if (!_premiumFlag) return;
    final cur = _resolvedCurrentTier;
    if (cur == BillingTier.monthly) {
      _selected = _PremiumPlanTier.yearly;
    } else if (cur == BillingTier.yearly) {
      _selected = _PremiumPlanTier.monthly;
    }
  }

  bool _selectedMatchesActivePlan() {
    if (!_premiumFlag) return false;
    final cur = _resolvedCurrentTier;
    switch (cur) {
      case BillingTier.monthly:
        return _selected == _PremiumPlanTier.monthly;
      case BillingTier.yearly:
        return _selected == _PremiumPlanTier.yearly;
      case BillingTier.unknown:
        return false;
    }
  }

  Future<void> _fetchServerSubscription() async {
    final token =
        PreferenceManager.getStringValue(key: 'token')?.trim() ?? '';
    if (token.isEmpty) return;
    final s = await AppRepository().getMySubscription(token);
    if (!mounted) return;
    setState(() {
      _serverSub = s;
      _presetSelectionForPremiumSwitch();
    });
  }

  Future<void> _openManageSubscriptions(BuildContext ctx) async {
    final ok = await SubscriptionStoreLauncher.openManageSubscriptions();
    if (!ctx.mounted) return;
    if (!ok) {
      showToast(
        context: ctx,
        message: 'Could not open the subscription manager.',
      );
    }
  }

  String _currentPlanHeading() {
    if (!_premiumFlag) return '';
    if (_serverSub?.isQaBypass == true) return 'Premium (QA test access)';
    switch (_resolvedCurrentTier) {
      case BillingTier.monthly:
        return 'Monthly Premium';
      case BillingTier.yearly:
        return 'Annual Premium';
      case BillingTier.unknown:
        return 'Premium active';
    }
  }

  String _renewalLine() {
    final e = _serverSub?.endsAt;
    if (e == null) return '';
    final d = DateFormat.yMMMd().format(e.toLocal());
    return 'Renews / valid through $d';
  }

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    await _service.ensureInitialized();
    _service.reloadBillingFlagFromPrefs();
    await _fetchServerSubscription();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _onContinue(BuildContext context) async {
    if (await _service.tryGrantQaSubscriptionBypassViaServer()) {
      if (!context.mounted) return;
      showToast(
          context: context,
          message:
              'Premium activated (QA test — no payment).');
      await _fetchServerSubscription();
      setState(() {});
      return;
    }
    if (_serverSub?.isQaBypass == true && _premiumFlag) {
      if (!context.mounted) return;
      showToast(
        context: context,
        message: 'QA Premium is already active for this account.',
      );
      return;
    }
    if (_selectedMatchesActivePlan()) {
      if (!context.mounted) return;
      showToast(
        context: context,
        message:
            'You’re already on this plan. Tap “Manage subscription” in the App Store or Google Play to cancel or change billing.',
      );
      return;
    }
    final product = _productForTier(_selected);
    if (product != null) {
      await _service.buySubscription(product);
      if (!context.mounted) return;
      showToast(context: context, message: 'Processing payment…');
      return;
    }
    if (!context.mounted) return;
    showToast(
      context: context,
      message: _service.products.isEmpty
          ? 'Plans loading from store… try again shortly'
          : 'This plan was not found in the store.',
    );
  }

  Future<void> _restore(BuildContext context) async {
    await _service.restorePurchases();
    await _fetchServerSubscription();
    if (!context.mounted) return;
    showToast(context: context, message: 'Restoring purchases…');
  }

  String _continueCtaLabel() {
    if (!_premiumFlag || _resolvedCurrentTier == BillingTier.unknown) {
      return 'Continue';
    }
    if (_selectedMatchesActivePlan()) {
      return 'Current plan';
    }
    if (_resolvedCurrentTier == BillingTier.monthly &&
        _selected == _PremiumPlanTier.yearly) {
      return 'Upgrade to yearly';
    }
    if (_resolvedCurrentTier == BillingTier.yearly &&
        _selected == _PremiumPlanTier.monthly) {
      return 'Switch to monthly';
    }
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FA),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6D3BBF)))
            : Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final headerH =
                            (MediaQuery.sizeOf(context).height * 0.19)
                                .clamp(128.0, 176.0);
                        const overlap = 14.0;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          clipBehavior: Clip.none,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(context, height: headerH),
                              Transform.translate(
                                offset: const Offset(0, -overlap),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _currentSubscriptionCard(context),
                                      if (_premiumFlag) ...[
                                        const SizedBox(height: 10),
                                        _planSwitchHint(),
                                        const SizedBox(height: 8),
                                      ],
                                      _featuresCard(context),
                                      const SizedBox(height: 11),
                                      _monthlyYearlyPlansRow(context),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _bottomBar(context),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required double height}) {
    final h = height;
    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _headerPurpleTop,
                    _headerPurpleBottom.withOpacity(0.94),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter:
                  _HeaderDecorPainter(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          _starDots(h),
          Positioned(
            top: 2,
            left: 0,
            child: IconButton(
              padding: const EdgeInsets.all(8),
              constraints:
                  BoxConstraints(minWidth: h > 126 ? 40 : 32, minHeight: 32),
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withOpacity(0.95),
                size: (h * 0.138).clamp(16.0, 21.0),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                math.max(40.0, h * 0.34),
                14,
                6,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: (h * 0.23).clamp(24.0, 36.0),
                    color: _gold,
                  ),
                  SizedBox(height: math.max(h * 0.022, 2)),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Go ',
                          style: GoogleFonts.inter(
                            fontSize: (h * 0.13).clamp(16.5, 23.0),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.06,
                          ),
                        ),
                        TextSpan(
                          text: 'Premium',
                          style: GoogleFonts.inter(
                            fontSize: (h * 0.13).clamp(16.5, 23.0),
                            fontWeight: FontWeight.w900,
                            color: _lavenderPremium,
                            height: 1.06,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: math.max(h * 0.026, 3)),
                  Text(
                    'Unlock unlimited access to all features',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: (h * 0.079).clamp(10.5, 12.8),
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.88),
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _starDots(double h) {
    final rnd = math.Random(4);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(12, (i) {
            final x = rnd.nextDouble() * 320 + (i % 3) * 40.0;
            final y = rnd.nextDouble() * (h * 0.55);
            final s = 4.0 + rnd.nextDouble() * 7;
            return Positioned(
              left: x % 340,
              top: y,
              child: Icon(Icons.star_rounded,
                  size: s, color: const Color(0xFFFFEE88).withOpacity(0.35)),
            );
          }),
        ),
      ),
    );
  }

  Widget _currentSubscriptionCard(BuildContext context) {
    if (!_premiumFlag) return const SizedBox.shrink();
    final renewal = _renewalLine();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            appColor.withOpacity(0.12),
            const Color(0xFFE8DDFE).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColor.withOpacity(0.28), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_rounded, color: appColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Your current plan',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currentPlanHeading(),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1D2E),
              height: 1.15,
            ),
          ),
          if (renewal.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              renewal,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openManageSubscriptions(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: appColor,
                side: BorderSide(color: appColor.withOpacity(0.55)),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              icon: Icon(Icons.open_in_new_rounded, size: 17, color: appColor),
              label: Text(
                'Manage subscription',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To switch billing (monthly ↔ yearly) or cancel, use your App Store '
            'or Google Play subscription settings above. After you subscribe to a '
            'new plan below, cancel the old one there so you are not billed twice.',
            style: GoogleFonts.inter(
              fontSize: 9.8,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planSwitchHint() {
    if (!_premiumFlag || _resolvedCurrentTier == BillingTier.unknown) {
      return const SizedBox.shrink();
    }
    final String msg;
    if (_resolvedCurrentTier == BillingTier.monthly) {
      msg =
          'You’re on Monthly — select Yearly below to upgrade. Cancel Monthly in Manage subscription after the new purchase if both appear.';
    } else {
      msg =
          'You’re on Annual — select Monthly below if you prefer monthly billing. Cancel Annual in Manage subscription after subscribing to Monthly if needed.';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Colors.blueGrey.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.32,
                color: const Color(0xFF2E3448),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuresCard(BuildContext context) {
    const features = <(IconData, String)>[
      (Icons.auto_fix_high_rounded, 'Unlimited AI Story Generation'),
      (Icons.headphones_rounded, 'Premium Story Voice'),
      (Icons.fact_check_rounded, 'Smart AI Quizzes'),
      (Icons.language_rounded, 'Instant Translation'),
      (Icons.chat_rounded, 'Improve Sentence & Corrections'),
      (Icons.chat_bubble_outline_rounded, 'Unlimited AI Chat'),
      (Icons.menu_book_rounded, 'Reading & Listening Practice'),
      (Icons.lightbulb_outline_rounded, 'Vocabulary Builder'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.18)),
            _featureRow(features[i]),
          ],
        ],
      ),
    );
  }

  Widget _featureRow((IconData, String) pair) {
    final (icon, label) = pair;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E8FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: appColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: appColor, size: 16),
        ],
      ),
    );
  }

  Widget _monthlyYearlyPlansRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _planCard(
              showCurrentRibbon:
                  _premiumFlag && _resolvedCurrentTier == BillingTier.monthly,
              selected: _selected == _PremiumPlanTier.monthly,
              onTap: () => setState(() => _selected = _PremiumPlanTier.monthly),
              title: 'Monthly Plan',
              iconPlan: Icons.calendar_month_rounded,
              iconAccent: appColor,
              original: '₹499',
              price: formattedProductPrice(_monthlyProduct, '₹349'),
              footerBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE6FA),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Save 30%',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: appColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _planCard(
              showCurrentRibbon:
                  _premiumFlag && _resolvedCurrentTier == BillingTier.yearly,
              selected: _selected == _PremiumPlanTier.yearly,
              onTap: () => setState(() => _selected = _PremiumPlanTier.yearly),
              title: 'Yearly Plan',
              iconPlan: Icons.workspace_premium_rounded,
              iconAccent: _goldDeep,
              original: '₹5,999',
              price: formattedProductPrice(_yearlyProduct, '₹2,499'),
              showPopular: true,
              footerBadge: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDD55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Save Upto 60%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF222222),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only ₹208/month',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3E4266),
                    ),
                  ),
                ],
              ),
              selectedBorderGold: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    bool showCurrentRibbon = false,
    required bool selected,
    required VoidCallback onTap,
    required String title,
    required IconData iconPlan,
    required Color iconAccent,
    String? original,
    required String price,
    required Widget footerBadge,
    bool showPopular = false,
    bool selectedBorderGold = false,
  }) {
    final strikeOriginal = original?.trim() ?? '';
    final borderColor = selected && selectedBorderGold
        ? _gold
        : selected
            ? appColor.withOpacity(0.45)
            : Colors.grey.shade300;
    final width = selected ? 2.0 : 1.2;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (showCurrentRibbon)
            Positioned(
              top: -9,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tealColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'YOUR PLAN',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(10, showPopular ? 16 : 12, 10, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: width),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconPlan, size: 18, color: iconAccent),
                    const Spacer(),
                    _miniRadio(
                        selected: selected,
                        goldAccent: selectedBorderGold && selected),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1D2E),
                    height: 1.18,
                  ),
                ),
                if (strikeOriginal.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    strikeOriginal,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.grey.shade400,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                ] else ...[
                  const SizedBox(height: 6),
                ],
                Text(
                  price,
                  maxLines: 3,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: appColor,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 7),
                Align(alignment: Alignment.centerLeft, child: footerBadge),
              ],
            ),
          ),
          if (showPopular)
            Positioned(
              top: -10,
              left: 0,
              right: 0,
              child: Align(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_gold, Color(0xFFFFEA9E)],
                    ),
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 12, color: Colors.black.withOpacity(0.75)),
                      const SizedBox(width: 3),
                      Text(
                        'MOST POPULAR',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.35,
                          color: const Color(0xFF1A1D2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniRadio({required bool selected, bool goldAccent = false}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? (goldAccent ? _goldDeep : appColor)
              : Colors.grey.shade400,
          width: 1.75,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: goldAccent ? _goldDeep : appColor,
                ),
              ),
            )
          : null,
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, 6, 16, MediaQuery.paddingOf(context).bottom + 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () => _openManageSubscriptions(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: appColor,
              side: BorderSide(color: appColor.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.settings_suggest_rounded, size: 18, color: appColor),
            label: Text(
              'Manage in App Store / Google Play',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 11.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: appColor,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _onContinue(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _premiumFlag &&
                              !_selectedMatchesActivePlan() &&
                              _resolvedCurrentTier !=
                                  BillingTier.unknown
                          ? Icons.swap_horiz_rounded
                          : Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _continueCtaLabel(),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 21),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Secure payment • Cancel anytime',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
            onPressed: () => _restore(context),
            child: Text(
              'Restore purchases',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: appColor,
                fontSize: 11.5,
              ),
            ),
          ),
          if (_premiumFlag)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Premium active',
                style: GoogleFonts.inter(
                  color: tealColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderDecorPainter extends CustomPainter {
  _HeaderDecorPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var lane = 0; lane < 5; lane++) {
      final path = Path();
      final dy = lane * size.height / 6 + size.height * 0.06;
      for (var x = -20.0; x < size.width + 20; x += 8) {
        final ox = lane * 12.0;
        path.moveTo(x, dy + math.sin((x + ox) / 28) * 6);
        path.lineTo(x + 8, dy + math.sin((x + 8 + ox) / 28) * 6);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
