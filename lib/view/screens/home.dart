import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spokiai/model/homebanner.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/settings.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';

import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';
import 'generatestory.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  final VoidCallback? onMenuTap;
  const HomeScreen({super.key, this.initialTabIndex, this.onMenuTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _streakDaysKey = 'home_drawer_streak_days';
  static const String _streakLastOpenKey = 'home_drawer_streak_last_open';
  static const String _androidAppLink =
      'https://play.google.com/store/apps/details?id=com.spokiai&pcampaignid=web_share';
  static const String _iosAppLink =
      'https://apps.apple.com/ng/app/spoki-ai/id6760191046';

  List<BannerList> bannerList = [];
  int _currentIndex = 0;
  int _streakDays = 1;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    BlocProvider.of<AppCubit>(context).bannerList();
    _updateDrawerStreak();
    super.initState();
  }

  void _updateDrawerStreak() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final String todayKey = _dateStorageKey(today);

    final String? lastOpenKey =
        PreferenceManager.getStringValue(key: _streakLastOpenKey);
    int streak = PreferenceManager.getIntegerValue(key: _streakDaysKey) ?? 1;

    if (lastOpenKey == null) {
      streak = 1;
    } else {
      final DateTime? lastOpenDate = _dateFromStorageKey(lastOpenKey);
      if (lastOpenDate != null) {
        final int dayDiff = today.difference(lastOpenDate).inDays;
        if (dayDiff == 1) {
          streak += 1;
        } else if (dayDiff > 1) {
          streak = 1;
        }
      } else {
        streak = 1;
      }
    }

    PreferenceManager.insertValue(key: _streakDaysKey, value: streak);
    PreferenceManager.insertValue(key: _streakLastOpenKey, value: todayKey);

    if (mounted) {
      setState(() {
        _streakDays = streak;
      });
    } else {
      _streakDays = streak;
    }
  }

  String _dateStorageKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  DateTime? _dateFromStorageKey(String value) {
    final List<String> parts = value.split('-');
    if (parts.length != 3) return null;

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  String get _streakText => '$_streakDays ${_streakDays == 1 ? "Day" : "Days"} Streak';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      drawer: widget.onMenuTap == null ? _buildAppDrawer() : null,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AppCubit, AppStates>(
          listener: (context, state) {
            if (state.status == AppStatus.bannerListSuccess) {
              HomeBannerResponse bannerResponse =
                  state.responseData?.response as HomeBannerResponse;

              if (bannerResponse.data?.length != 0) {
                bannerList.addAll(bannerResponse.data ?? []);
                setState(() {});
              }
            }
          },
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                _buildHeroBanner(),
                const SizedBox(height: 30),
                _buildActionCardsSection(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          Builder(
            builder: (context) => Material(
              color: cardSurface,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  if (widget.onMenuTap != null) {
                    widget.onMenuTap!.call();
                  } else {
                    Scaffold.of(context).openDrawer();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cardSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaceMuted),
                  ),
                  child: Icon(Icons.menu_rounded,
                      color: textPrimary, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Spoki AI",
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: bannerList.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: brandGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                        color: appColor.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Your AI Language Companion",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Learn English through\nstories & conversation",
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: bannerList.length,
                      itemBuilder: (context, index, realIndex) {
                        return CachedNetworkImage(
                          imageUrl: bannerList[index].bannerImage ?? "",
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration:
                                BoxDecoration(gradient: brandGradient),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration:
                                BoxDecoration(gradient: brandGradient),
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.white70, size: 50),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: double.infinity,
                        viewportFraction: 1.0,
                        autoPlay: bannerList.length > 1,
                        enableInfiniteScroll: bannerList.length > 1,
                        autoPlayInterval: const Duration(seconds: 3),
                        onPageChanged: (index, reason) {
                          setState(() => _currentIndex = index);
                        },
                      ),
                    ),
                  ),
          ),
          if (bannerList.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: bannerList.asMap().entries.map((entry) {
                final active = _currentIndex == entry.key;
                return GestureDetector(
                  onTap: () =>
                      _carouselController.animateToPage(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: active ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active ? appColor : surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionCardsSection() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          _buildHomePromoCard(
            isDark: isDark,
            borderColor:
                isDark ? appColor.withOpacity(0.5) : const Color(0xFFD9C8F5),
            leftTileBg:
                isDark ? appColor.withOpacity(0.2) : const Color(0xFFF0E8FB),
            leftIcon: Icons.auto_stories_rounded,
            leftIconColor: const Color(0xFF5B2DB8),
            title: "Learn with Stories",
            connectorColor:
                isDark ? appColor.withOpacity(0.65) : const Color(0xFFC4B0E8),
            steps: const [
              (
                color: Color(0xFF34C759),
                icon: Icons.auto_stories_rounded,
                label: "Read"
              ),
              (
                color: Color(0xFF7B4FD4),
                icon: Icons.quiz_rounded,
                label: "Quiz"
              ),
              (
                color: Color(0xFF4A7FD4),
                icon: Icons.mic_rounded,
                label: "Speak"
              ),
            ],
            illustration: _StoryCardIllustration(isDark: isDark),
            buttonLabel: "Create a Story",
            buttonColor: const Color(0xFF6D3BBF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GenerateStoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildHomePromoCard(
            isDark: isDark,
            borderColor:
                isDark ? tealColor.withOpacity(0.5) : const Color(0xFFB8E8D9),
            leftTileBg:
                isDark ? tealColor.withOpacity(0.18) : const Color(0xFFE8FAF5),
            leftIcon: Icons.settings_voice_rounded,
            leftIconColor: const Color(0xFF139E86),
            title: "AI Speaking Coach",
            connectorColor:
                isDark ? tealColor.withOpacity(0.65) : const Color(0xFF7DD4C0),
            steps: const [
              (
                color: Color(0xFF20C5A8),
                icon: Icons.mic_rounded,
                label: "Speak"
              ),
              (
                color: Color(0xFF7B4FD4),
                icon: Icons.sms_rounded,
                label: "Feedback"
              ),
              (
                color: Color(0xFF20C5A8),
                icon: Icons.trending_up_rounded,
                label: "Improve"
              ),
            ],
            illustration: _SpeakingCoachIllustration(isDark: isDark),
            buttonLabel: "Start Speaking",
            buttonColor: appColor,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const DashboardScreen(initialTabIndex: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomePromoCard({
    required bool isDark,
    required Color borderColor,
    required Color leftTileBg,
    required IconData leftIcon,
    required Color leftIconColor,
    required String title,
    required Color connectorColor,
    required List<({Color color, IconData icon, String label})> steps,
    required Widget illustration,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _promoLeftIconTile(
                  isDark: isDark,
                  bg: leftTileBg,
                  icon: leftIcon,
                  iconColor: leftIconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      _promoFeatureStepRow(
                        steps: steps,
                        connectorColor: connectorColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 78,
                  height: 72,
                  child: illustration,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _promoCtaButton(
              label: buttonLabel,
              background: buttonColor,
              onTap: onTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoLeftIconTile({
    required bool isDark,
    required Color bg,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, color: iconColor, size: 34),
      ),
    );
  }

  Widget _promoFeatureStepRow({
    required List<({Color color, IconData icon, String label})> steps,
    required Color connectorColor,
  }) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) _promoStepConnector(connectorColor),
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: steps[i].color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: steps[i].color.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    steps[i].icon,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  steps[i].label,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _promoStepConnector(Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          4,
          (i) => Container(
            width: 3,
            height: 3,
            margin: EdgeInsets.only(right: i < 3 ? 3 : 0),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _promoCtaButton({
    required String label,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              Positioned(
                right: 0,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String avatarPath =
        PreferenceManager.getStringValue(key: 'profile_avatar_asset') ?? '';
    final bool hasAvatarAsset = avatarPath.startsWith('assets/images/');
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF14141D) : const Color(0xFFF4EFFB),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            Row(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF2F2F3F) : Colors.white,
                      width: 3,
                    ),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC8B9FA), Color(0xFFB9A5F4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    image: hasAvatarAsset
                        ? DecorationImage(
                            image: AssetImage(avatarPath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: hasAvatarAsset
                      ? null
                      : const Icon(Icons.person_rounded,
                          color: Colors.white, size: 47.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _closeDrawer,
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.16)
                                  : Colors.white.withOpacity(0.82),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: isDark ? Colors.white : const Color(0xFF36206E),
                              size: 15.3,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "Mohd Salim",
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF161442),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _drawerChip(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFFF7A33),
                        text: _streakText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _drawerSectionCard(
              children: [
                _drawerRowItem(
                  icon: Icons.person_rounded,
                  title: "My Profile",
                  subtitle: "View & edit your details",
                  onTap: () async {
                    _closeDrawer();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Editprofile(),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFECE7F8),
                ),
                _drawerRowItem(
                  icon: Icons.star_rounded,
                  title: "Upgrade to Pro",
                  subtitle: "Unlock AI Chat & Unlimited Stories",
                  onTap: () {
                    _closeDrawerAndToast("Coming soon");
                  },
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _closeDrawerAndToast("Coming soon");
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded,
                              color: Colors.white, size: 18.7),
                          const SizedBox(width: 8),
                          Text(
                            "Upgrade Now",
                            style: GoogleFonts.inter(
                              fontSize: 14.96,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _drawerSectionCard(
              children: [
                _drawerRowItem(
                  icon: Icons.group_rounded,
                  title: "Invite Friends",
                  subtitle: "Earn rewards & grow together",
                  onTap: () async {
                    _closeDrawer();
                    await Future.delayed(const Duration(milliseconds: 120));
                    if (!mounted) return;
                    await _showShareAppDialog();
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFECE7F8),
                ),
                _drawerRowItem(
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  subtitle: "Manage app preferences",
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _drawerPromoCard(
              title: "Learn Daily on WhatsApp",
              subtitle: "Get tips & updates daily",
              buttonText: "Join Now",
              iconAssetPath: 'assets/images/whatsapp-png.png',
              onTap: () => _closeDrawerAndToast("Coming soon"),
            ),
            const SizedBox(height: 10),
            _drawerPromoCard(
              title: "Practice on Telegram",
              subtitle: "Free discussions & speaking",
              buttonText: "Join Now",
              iconAssetPath: 'assets/images/telegram-icon-png.webp',
              onTap: () => _closeDrawerAndToast("Coming soon"),
            ),
          ],
        ),
      ),
    );
  }

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  void _closeDrawerAndToast(String message) {
    _closeDrawer();
    showToast(context: context, message: message);
  }

  Future<void> _showShareAppDialog() async {
    final String? selectedLink = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Share app link',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shareOptionTile(
              icon: Icons.android_rounded,
              title: 'Share Android link',
              onTap: () => Navigator.pop(context, _androidAppLink),
            ),
            const SizedBox(height: 8),
            _shareOptionTile(
              icon: Icons.phone_iphone_rounded,
              title: 'Share iOS link',
              onTap: () => Navigator.pop(context, _iosAppLink),
            ),
          ],
        ),
      ),
    );

    if (selectedLink == null || selectedLink.isEmpty) return;
    await Share.share(selectedLink, subject: 'Spoki AI app link');
  }

  Widget _shareOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appColor.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Icon(icon, color: appColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _drawerChip({
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252535).withOpacity(0.9)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF3B3B50) : const Color(0xFFD6CFFA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.2, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.9,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionCard({required List<Widget> children}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFEAE5F7)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : const Color(0xFF2D1769).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _drawerRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tint = iconColor ?? appColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tint.withOpacity(0.95), tint.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 20.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.6,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.9,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFFB69CFF) : const Color(0xFF7540E5),
              size: 23.8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerPromoCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required String iconAssetPath,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF262638), Color(0xFF1E1E2D)]
              : const [Color(0xFFF4F0FE), Color(0xFFE4DAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: isDark ? const Color(0xFF34344A) : Colors.white),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.6,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.9,
                    fontWeight: FontWeight.w500,
                      color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        fontSize: 13.85,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            height: 84,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                iconAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_rounded,
                  color: appColor,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// —— Home promo card illustrations (match reference: mountain path / coach ghost) ——

class _StoryCardIllustration extends StatelessWidget {
  const _StoryCardIllustration({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StoryMountainPainter(isDark: isDark),
    );
  }
}

class _SpeakingCoachIllustration extends StatelessWidget {
  const _SpeakingCoachIllustration({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CoachGhostPainter(isDark: isDark),
    );
  }
}

class _StoryMountainPainter extends CustomPainter {
  _StoryMountainPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color mountain = isDark
        ? const Color(0xFF6D4BC4).withOpacity(0.85)
        : const Color(0xFFD4C4F5);
    final Color mountainDeep =
        isDark ? const Color(0xFF4F368F) : const Color(0xFFB9A0E8);
    final Color pathColor =
        isDark ? const Color(0xFFE8E0FF).withOpacity(0.5) : Colors.white;
    final Color tree = isDark ? const Color(0xFF7B4FD4) : const Color(0xFF8B6BD6);

    final Path m = Path()
      ..moveTo(w * 0.08, h * 0.92)
      ..quadraticBezierTo(w * 0.35, h * 0.55, w * 0.55, h * 0.38)
      ..lineTo(w * 0.92, h * 0.92)
      ..close();
    final Paint mPaint = Paint()..color = mountain;
    canvas.drawPath(m, mPaint);

    final Path m2 = Path()
      ..moveTo(w * 0.22, h * 0.92)
      ..quadraticBezierTo(w * 0.48, h * 0.62, w * 0.68, h * 0.48)
      ..lineTo(w * 0.95, h * 0.92)
      ..close();
    canvas.drawPath(m2, Paint()..color = mountainDeep);

    final Path trail = Path()
      ..moveTo(w * 0.42, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.62, w * 0.58, h * 0.42)
      ..quadraticBezierTo(w * 0.62, h * 0.28, w * 0.66, h * 0.18);
    canvas.drawPath(
      trail,
      Paint()
        ..color = pathColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    final Offset peak = Offset(w * 0.66, h * 0.14);
    canvas.drawRect(
      Rect.fromCenter(center: peak.translate(0, 4), width: 2.5, height: 10),
      Paint()..color = const Color(0xFFB39DDB),
    );
    final Path flag = Path()
      ..moveTo(peak.dx, peak.dy)
      ..lineTo(peak.dx + 10, peak.dy + 3)
      ..lineTo(peak.dx, peak.dy + 7)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFF7B4FD4));

    final Offset treeBase = Offset(w * 0.2, h * 0.88);
    canvas.drawCircle(treeBase.translate(0, -6), 5, Paint()..color = tree);
    canvas.drawRect(
      Rect.fromCenter(center: treeBase, width: 2.5, height: 7),
      Paint()..color = const Color(0xFF6D4E9A),
    );

    final Paint cloud = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.12 : 0.75);
    canvas.drawCircle(Offset(w * 0.15, h * 0.22), 5, cloud);
    canvas.drawCircle(Offset(w * 0.22, h * 0.2), 6, cloud);
    canvas.drawCircle(Offset(w * 0.28, h * 0.22), 4.5, cloud);
  }

  @override
  bool shouldRepaint(covariant _StoryMountainPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _CoachGhostPainter extends CustomPainter {
  _CoachGhostPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Color ghostFill =
        isDark ? const Color(0xFFE8E8F0) : Colors.white;
    final Color mint = const Color(0xFF20C5A8);
    final Color mintDark = const Color(0xFF139E86);

    final RRect body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.48),
        width: w * 0.52,
        height: h * 0.58,
      ),
      const Radius.circular(22),
    );
    final Path bodyPath = Path()..addRRect(body);
    canvas.drawShadow(
      bodyPath,
      Colors.black.withOpacity(isDark ? 0.4 : 0.14),
      6,
      false,
    );
    canvas.drawPath(bodyPath, Paint()..color = ghostFill);

    final Path tail = Path()
      ..moveTo(w * 0.28, h * 0.68)
      ..quadraticBezierTo(w * 0.32, h * 0.82, w * 0.38, h * 0.76)
      ..quadraticBezierTo(w * 0.44, h * 0.88, w * 0.5, h * 0.78)
      ..quadraticBezierTo(w * 0.56, h * 0.88, w * 0.62, h * 0.76)
      ..quadraticBezierTo(w * 0.68, h * 0.82, w * 0.72, h * 0.68);
    canvas.drawShadow(
      tail,
      Colors.black.withOpacity(isDark ? 0.25 : 0.08),
      3,
      false,
    );
    canvas.drawPath(tail, Paint()..color = ghostFill);

    canvas.drawCircle(Offset(w * 0.4, h * 0.42), 2.2,
        Paint()..color = const Color(0xFF2D2640));
    canvas.drawCircle(Offset(w * 0.54, h * 0.42), 2.2,
        Paint()..color = const Color(0xFF2D2640));

    final Rect band = Rect.fromLTWH(
      w * 0.22,
      h * 0.34,
      w * 0.56,
      h * 0.14,
    );
    canvas.drawArc(
      band,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(w * 0.22, h * 0.41), 5,
        Paint()..color = mintDark);
    canvas.drawCircle(Offset(w * 0.74, h * 0.41), 5,
        Paint()..color = mintDark);

    final RRect bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52, h * 0.06, w * 0.38, h * 0.22),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = mint.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final double bx = w * 0.58;
    final double by = h * 0.14;
    for (int i = 0; i < 4; i++) {
      final double t = i / 3;
      final double barH = 4 + 7 * (0.5 + 0.5 * math.sin(t * math.pi));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bx + i * 6.5, by),
            width: 3,
            height: barH,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = mint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoachGhostPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

