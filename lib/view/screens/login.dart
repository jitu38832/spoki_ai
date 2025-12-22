import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:spokiai/model/googlelogin.dart';
import 'package:spokiai/view/utils/preference_manager.dart';

import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _termsAccepted = true; // Checked by default
  final TextEditingController _phoneController = TextEditingController();

  final List<SlideData> _slides = [
    SlideData(
      image: "assets/images/iv_login_slider.png",
      tagline: "Unlock Your English Fluency",
    ),
    SlideData(
      image: "assets/images/iv_login_slider2.png",
      tagline: "Start Your Personalized Learning Journey",
    ),
    SlideData(
      image: "assets/images/iv_login_slider3.png",
      tagline: "Join Now & Grow",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {}); // Rebuild to update button state
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: _slides.length,
                itemBuilder: (context, index, realIndex) {
                  return Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          _slides[index].image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, size: 50),
                              ),
                            );
                          },
                        ),
                      ),

                      // TAGLINE – directly under the image
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: textInter(
                          text: _slides[index].tagline,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
                options: CarouselOptions(
                  height: double.infinity,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: true,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 3),
                  onPageChanged: (index, reason) {
                    setState(() => _currentIndex = index);
                  },
                ),
              ),
            ),

            // ---------- DOTS INDICATOR ----------
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DotsIndicator(
                dotsCount: _slides.length,
                position: _currentIndex.toDouble(),
                decorator: DotsDecorator(
                  size: const Size.square(9.0),
                  activeSize: const Size(24.0, 9.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  color: Colors.grey[300]!,
                  activeColor: appColor,
                  spacing: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),

            // ---------- LOGIN SECTION ----------
            _buildLoginSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          // color: const Color(0xFF9B59B6).withOpacity(0.1),
        ),
        child: Column(
          children: [
            textInter(
              text: "Login or Signup",
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            const SizedBox(height: 20),

            // Phone input

            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  activeColor: appColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                        children: [
                          const TextSpan(
                              text: "By continuing, you agree to our "),
                          TextSpan(
                            text: "Terms and Conditions",
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: appColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text: " and ",
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[700],
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: appColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            BlocConsumer<AppCubit, AppStates>(
              listener: (context, state) async {
                if (state.status == AppStatus.loginSuccess) {
                  GoogleLoginResponse googleLoginResponse =
                      state.responseData?.response as GoogleLoginResponse;

                  await PreferenceManager.insertValue(
                      key: "token",
                      value: googleLoginResponse.data?.tokens?.access?.token
                              .toString() ??
                          "");

                  showToast(context: context, message: "Logged in successfully");

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return DashboardScreen();
                      },
                    ),
                    (route) => false,
                  );
                }
              },
              builder: (context, state) {
                return state.status == AppStatus.loginLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: appColor,
                        ),
                      )
                    : GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          await signInWithGoogle(context);
                          //
                          // /Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) {
                          //   return DashboardScreen();
                          // },), (route) => false,);
                        },
                        child: Card(
                          elevation: 6,
                          shadowColor: appColor.withOpacity(0.8),
                          child: Container(
                            decoration: BoxDecoration(
                                color: appColor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            child: Padding(
                              padding: const EdgeInsets.all(13.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  textInter(
                                      text: "Continue with google",
                                      fontSize: 17,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400)
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
      serverClientId:
          "303958409160-dkuk2e7fq58bvsdij0l79v7do6j0krfo.apps.googleusercontent.com",
    );

    try {

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (context.mounted) {}
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print("USER EMAIL: ${googleUser.email}");
      print("ID TOKEN: $idToken");
      print("ACCESS TOKEN: $accessToken");

      BlocProvider.of<AppCubit>(context).login(idToken.toString());

      // showToast(context: context, message: "Signed in as ${googleUser.email}");
    } catch (error) {
      print("Google Sign-In error: $error");
      showToast(context: context, message: "Google Sign-In failed.");
    }
  }
}

class SlideData {
  final String image;
  final String tagline;

  SlideData({required this.image, required this.tagline});
}
