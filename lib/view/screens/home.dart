import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/homebanner.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/settings.dart';
import 'package:spokiai/view/utils/colors.dart';
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
  List<BannerList> bannerList = [];
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    BlocProvider.of<AppCubit>(context).bannerList();
    super.initState();
  }

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _buildHomeActionCard(
            imageIcon: Icons.menu_book_rounded,
            title: "Learn with Stories",
            subtitle: "Read, listen, and build your English step by step.",
            chipsText: "Read • Quiz • Speak",
            buttonText: "Start a Story",
            detailText: "Level-based stories to begin your learning journey.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GenerateStoryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          _buildHomeActionCard(
            imageIcon: Icons.record_voice_over_rounded,
            title: "AI Speaking Coach",
            subtitle: "Practice real conversations with your AI coach.",
            chipsText: "Speak • Feedback • Improve",
            buttonText: "Start Speaking",
            detailText: "Have real-time conversations and improve your speaking.",
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

  Widget _buildHomeActionCard({
    required IconData imageIcon,
    required String title,
    required String subtitle,
    required String chipsText,
    required String buttonText,
    required String detailText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: cardSurface,
        border: Border.all(color: appColor.withOpacity(0.6), width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 84,
                decoration: BoxDecoration(
                  color: appColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(imageIcon, color: appColor, size: 26),
              ),
              const SizedBox(width: 7),
              Expanded(
                flex: 15,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      constraints: const BoxConstraints(minWidth: 118),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 5),
                      decoration: BoxDecoration(
                        color: appColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        chipsText,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: appColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 12,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: appColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                buttonText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: cardSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: appColor, size: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detailText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppDrawer() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
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
                  ),
                  child: const Icon(Icons.person_rounded,
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
                      const SizedBox(height: 4),
                      Text(
                        "Learning English Daily",
                        style: GoogleFonts.inter(
                          fontSize: 11.9,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.88)
                              : const Color(0xFF5F5C7A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _drawerChip(
                            icon: Icons.circle,
                            iconColor: const Color(0xFF8ED06F),
                            text: "Active Learner",
                          ),
                          _drawerChip(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: const Color(0xFFFF7A33),
                            text: "3 Day Streak",
                          ),
                        ],
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
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Editprofile(),
                      ),
                    );
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
                  onTap: () {
                    _closeDrawerAndToast("Coming soon");
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
              icon: Icons.call,
              onTap: () => _closeDrawerAndToast("Coming soon"),
            ),
            const SizedBox(height: 10),
            _drawerPromoCard(
              title: "Practice on Telegram",
              subtitle: "Free discussions & speaking",
              buttonText: "Join Now",
              icon: Icons.send_rounded,
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
    required IconData icon,
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: appColor.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 35.7),
          ),
        ],
      ),
    );
  }

}

