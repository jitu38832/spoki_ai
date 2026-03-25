import 'dart:convert';

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
import 'chat.dart';
import 'chatlist.dart'; // ✅ Added Chatlist import

class HomeScreen extends StatefulWidget {
  final int? initialTabIndex; // ✅ Added for tab selection

  const HomeScreen({super.key, this.initialTabIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Color scheme based on the design
  final Color purpleColor = const Color(0xFF9B59B6);
  final Color tealColor = const Color(0xFF1ABC9C);
  final Color darkGrey = const Color(0xFF2C3E50);
  final Color lightBlue = const Color(0xFF87CEEB);
  final Color orangeStart = const Color(0xFFFFA500);
  final Color orangeEnd = const Color(0xFFFF6B35);

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
      backgroundColor: Colors.white,
      drawer: _buildAppDrawer(),
      body: SafeArea(
        child: BlocConsumer<AppCubit, AppStates>(
          listener: (context, state) {
            if (state.status == AppStatus.bannerListSuccess) {
              HomeBannerResponse bannerResponse =
              state.responseData?.response as HomeBannerResponse;

              if (bannerResponse.data?.length != 0) {
                bannerList.addAll(bannerResponse.data ?? []);
                setState(() {});

                print("Banner list");
                print(jsonEncode(bannerList));
              }
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Create Your Story
                          _buildStepSection(
                            stepNumber: "Step 1:",
                            title: "Create Your Story",
                            buttonText: "Generate a New Story",
                            icon: Icons.auto_awesome,
                            gradientColors: [appColor, appColor],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const GenerateStoryScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Step 2: Converse & Practice ✅ FIXED - Go to Dashboard with Chat tab selected
                          _buildStepSection(
                            stepNumber: "Step 2:",
                            title: "Converse & Practice",
                            buttonText: "Speak with AI Avatar",
                            icon: Icons.star,
                            gradientColors: [appColor, appColor],
                            onTap: () {
                              Navigator.pushReplacement( // ✅ Use pushReplacement to replace current screen
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DashboardScreen(
                                    initialTabIndex: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => InkWell(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: const Icon(
                    Icons.menu,
                    size: 30,
                    color: Colors.black,
                  ),
                ),
              ),

              Text(
                "Spoki",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              // Gift Icon
              InkWell(
                onTap: () {
                  // navigate to gifts or rewards
                },
                child: const Icon(
                  Icons.card_giftcard,
                  size: 30,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.24,
            child: bannerList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: CarouselSlider.builder(
                      carouselController: _carouselController,
                      itemCount: bannerList.length,
                      itemBuilder: (context, index, realIndex) {
                        return CachedNetworkImage(
                          imageUrl: bannerList[index].bannerImage ?? "",
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            "assets/images/iv_banner.jpeg",
                            fit: BoxFit.cover,
                            width: double.infinity,
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
                SizedBox(
                  height: 10,
                ),


                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: bannerList.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _carouselController.animateToPage(entry.key),
                      child: Container(
                        width: 10.0,
                        height: 10.0,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == entry.key
                              ? appColor // Active dot color
                              : Colors.grey.withOpacity(0.7),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: appColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Profile",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Profile Item
            ListTile(
              leading: const Icon(Icons.person, size: 26),
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return Editprofile();
                  },
                ));
              },
            ),

            // Privacy Policy
            ListTile(
              leading: const Icon(Icons.privacy_tip, size: 26),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return PrivacyPolicyScreen();
                  },
                ));
                // Navigator.pop(context);
                // Navigate to Policy Page
              },
            ),

            // Terms & Conditions
            ListTile(
              leading: const Icon(Icons.info_outline, size: 26),
              title: const Text("Terms & Conditions"),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return TermsConditionScreen();
                  },
                ));
                // Navigator.pop(context);
                // Navigate to Terms Page
              },
            ),

            ListTile(
              leading: const Icon(Icons.share, size: 26),
              title: const Text("Share"),
              onTap: () {
                showToast(context: context, message: "Coming soon");
            Navigator.pop(context);
                // Navigate to Terms Page
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete, size: 26, ),
              title: const Text("Delete Account", ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Confirm Delete"),
                      content: const Text("Are you sure you want to delete your account?"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context), // close dialog
                        ),
                        TextButton(
                          child: const Text(
                            "Yes, Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            PreferenceManager.clearPreferences();
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            const Spacer(),

            // Logout (optional)
            ListTile(
              leading: const Icon(Icons.logout, size: 26, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context), // close dialog
                        ),
                        TextButton(
                          child: const Text(
                            "Yes, Logout",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () async {
                            PreferenceManager.clearPreferences();
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                                  (route) => false,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepSection({
    required String stepNumber,
    required String title,
    required String buttonText,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Step Heading
              textInter(
                text: "$stepNumber $title",
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: darkGrey,
              ),

              const SizedBox(height: 16),

              // Gradient Button
              Card(
                elevation: 6,
                shadowColor: appColor.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: appColor,
                    borderRadius: BorderRadius.circular(12),

                    // Soft outer shadow
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // Icon Box
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Button Text
                            Expanded(
                              child: textInter(
                                text: buttonText,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}