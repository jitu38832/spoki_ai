import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/homebanner.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/signup.dart';
import 'package:spokiai/view/screens/privacypolicy.dart';
import 'package:spokiai/view/screens/termscondition.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';

import '../../viewmodel/cubit/appcubit.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';
import 'generatestory.dart';

class HomeScreen extends StatefulWidget {
  final int? initialTabIndex;
  const HomeScreen({super.key, this.initialTabIndex});

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
      drawer: _buildAppDrawer(),
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
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: bannerList.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: brandGradient,
                      borderRadius: BorderRadius.circular(22),
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
                    borderRadius: BorderRadius.circular(22),
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
      padding: const EdgeInsets.symmetric(horizontal: 10),
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
      padding: const EdgeInsets.fromLTRB(5, 14, 6, 14),
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: appColor.withOpacity(0.6), width: 1.2),
        borderRadius: BorderRadius.circular(24),
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
                              decoration: const BoxDecoration(
                                color: Colors.white,
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
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              decoration: BoxDecoration(
                gradient: heroGradient,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(26),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: appColor.withOpacity(0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(Icons.person_rounded,
                        size: 40, color: appColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Hi, Learner",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage your profile",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _drawerTile(Icons.person_outline_rounded, "Profile", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => const Editprofile(),
              ));
            }),
            _drawerTile(Icons.privacy_tip_outlined, "Privacy Policy", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => PrivacyPolicyScreen(),
              ));
            }),
            _drawerTile(Icons.info_outline_rounded, "Terms & Conditions", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => TermsConditionScreen(),
              ));
            }),
            _drawerTile(Icons.share_outlined, "Share", () {
              showToast(context: context, message: "Coming soon");
              Navigator.pop(context);
            }),
            _drawerTile(
              Icons.delete_outline_rounded,
              "Delete Account",
              () => _confirmAccountAction(
                title: "Confirm Delete",
                body: "Are you sure you want to delete your account?",
                confirmLabel: "Yes, Delete",
              ),
              color: errorColor,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: outlineButton(
                context: context,
                width: double.infinity,
                title: "Logout",
                icon: Icons.logout_rounded,
                onPressed: () => _confirmAccountAction(
                  title: "Confirm Logout",
                  body: "Are you sure you want to logout?",
                  confirmLabel: "Yes, Logout",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? appColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: color ?? appColor),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: color ?? textPrimary,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: textMuted, size: 20),
      onTap: onTap,
    );
  }

  Future<void> _confirmAccountAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                PreferenceManager.clearPreferences();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(confirmLabel,
                  style: TextStyle(color: errorColor)),
            ),
          ],
        );
      },
    );
  }
}

