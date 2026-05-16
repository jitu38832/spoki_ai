import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/model/googlelogin.dart';
import 'package:spokiai/view/utils/preference_manager.dart';

import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';
import 'editprofile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _termsAccepted = true;
  bool _routeAfterGoogleProfile = false;

  final List<_SlideData> _slides = [
    _SlideData(
      image: "assets/images/iv_login_slider.png",
      tagline: "Unlock Your English Fluency",
    ),
    _SlideData(
      image: "assets/images/iv_login_slider2.png",
      tagline: "Start Your Personalized Learning Journey",
    ),
    _SlideData(
      image: "assets/images/iv_login_slider3.png",
      tagline: "Join Now & Grow",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: surfaceBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildBrandHeader(),
            const SizedBox(height: 20),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.36,
              child: CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: _slides.length,
                itemBuilder: (context, index, realIndex) {
                  return Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                            boxShadow: softCardShadow(),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              _slides[index].image,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: backgroundSheetGradient,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.auto_stories_rounded,
                                      size: 80,
                                      color: appColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          _slides[index].tagline,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            height: 1.3,
                          ),
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
                  autoPlayInterval: const Duration(seconds: 3),
                  onPageChanged: (index, reason) {
                    setState(() => _currentIndex = index);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: DotsIndicator(
                dotsCount: _slides.length,
                position: _currentIndex.toDouble(),
                decorator: DotsDecorator(
                  size: const Size.square(8.0),
                  activeSize: const Size(26.0, 8.0),
                  activeShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  color: surfaceMuted,
                  activeColor: appColor,
                  spacing: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ),
            const Spacer(),
            _buildLoginSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpokiLogoMark(size: 36),
        const SizedBox(width: 10),
        Text(
          "Spoki AI",
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          children: [
            Text(
              "Sign in to continue",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Create your personalized learning companion",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.05,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) =>
                        setState(() => _termsAccepted = v ?? false),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: textSecondary,
                          height: 1.45,
                        ),
                        children: [
                          const TextSpan(
                              text: "By continuing, you agree to our "),
                          TextSpan(
                            text: "Terms",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: appColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
            const SizedBox(height: 14),
            BlocConsumer<AppCubit, AppStates>(
              listener: (context, state) async {
                if (state.status == AppStatus.loginSuccess) {
                  GoogleLoginResponse googleLoginResponse =
                      state.responseData?.response as GoogleLoginResponse;
                  final accessToken = googleLoginResponse
                          .data?.tokens?.access?.token
                          .toString() ??
                      "";
                  await PreferenceManager.insertValue(
                      key: "token", value: accessToken);

                  if (!context.mounted) return;
                  showToast(
                    context: context,
                    message: "Logged in successfully",
                    buttonColor: successColor,
                  );

                  setState(() => _routeAfterGoogleProfile = true);
                  context.read<AppCubit>().getProfile(accessToken);
                  return;
                }

                if (_routeAfterGoogleProfile &&
                    state.status == AppStatus.getProfileSuccess) {
                  setState(() => _routeAfterGoogleProfile = false);
                  final response =
                      state.responseData?.response as GetProfileResponse;
                  if (!context.mounted) return;
                  final incomplete = profileNeedsCompletion(response.data);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => incomplete
                          ? const Editprofile(isPostLoginSetup: true)
                          : const DashboardScreen(),
                    ),
                    (route) => false,
                  );
                  return;
                }

                if (_routeAfterGoogleProfile &&
                    state.status == AppStatus.getProfileError) {
                  setState(() => _routeAfterGoogleProfile = false);
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const Editprofile(isPostLoginSetup: true),
                    ),
                    (route) => false,
                  );
                }
              },
              builder: (context, state) {
                final loading = state.status == AppStatus.loginLoading ||
                    (_routeAfterGoogleProfile &&
                        state.status == AppStatus.getProfileLoading);
                return Column(
                  children: [
                    button(
                      context: context,
                      width: double.infinity,
                      title:
                          loading ? 'Signing you in…' : 'Continue with Google',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      isLoading: loading,
                      icon: Icons.g_mobiledata_rounded,
                      onPressed: () async {
                        if (!_termsAccepted) {
                          showToast(
                            context: context,
                            message: "Please accept the terms to continue",
                          );
                          return;
                        }
                        await FirebaseAuth.instance.signOut();
                        await signInWithGoogle(context);
                      },
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Platform.isIOS
                        ? button(
                            context: context,
                            width: double.infinity,
                            title: loading
                                ? 'Signing you in…'
                                : 'Continue with Apple',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            isLoading: loading,
                            icon: Icons.apple,
                            onPressed: () async {
                              if (!_termsAccepted) {
                                showToast(
                                  context: context,
                                  message:
                                      "Please accept the terms to continue",
                                );
                                return;
                              }
                              await signInWithApple(context);
                            },
                          )
                        : SizedBox(),
                  ],
                );
              },
            ),
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
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      BlocProvider.of<AppCubit>(context).login(idToken.toString());
    } catch (error) {
      showToast(context: context, message: "Google Sign-In failed.");
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    Map<String, dynamic> appleDetails = {
      "name": credential.givenName,
      "email": credential.email,
      "identityToken": credential.userIdentifier
    };

    BlocProvider.of<AppCubit>(context).appleLogin(appleDetails);
  }
}

class _SlideData {
  final String image;
  final String tagline;

  _SlideData({required this.image, required this.tagline});
}
