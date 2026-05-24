import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/login.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_navigator.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/payment/post_login_entitlements_sync.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/payment/story_freemium.dart';
import 'package:spokiai/payment/SubscriptionService.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  /// Splash stays visible at least this long before navigating away (after work finished).
  static const Duration _minimumSplashDisplay = Duration(seconds: 6);

  bool _navigated = false;
  bool _awaitingProfileForRoute = false;
  late final DateTime _splashShownAt;

  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _fade;

  void _goHomeOrProfile(BuildContext context, GetProfileResponse? response) {
    final incomplete = profileNeedsCompletion(response?.data);
    if (incomplete) {
      CustomNavigator.pushAndRemoveUntil(
        context: context,
        screen: const Editprofile(isPostLoginSetup: true),
      );
    } else {
      CustomNavigator.pushAndRemoveUntil(
        context: context,
        screen: const DashboardScreen(),
      );
    }
  }

  bool _isUserNotFoundError(AppStates state) {
    final code = state.errorData?.code;
    final raw = (state.errorData?.message ?? state.error ?? '').toLowerCase();
    return code == 404 ||
        raw.contains('user not found') ||
        raw.contains('no user found');
  }

  Future<void> _forceLogoutToLogin(BuildContext context) async {
    await _ensureMinimumSplashElapsed();
    if (!mounted || _navigated) return;
    ChatFreemium.resetVolatileState();
    StoryFreemium.resetVolatileState();
    SubscriptionService.instance.clearSessionBillingState();
    PreferenceManager.clearPreferences();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    _navigated = true;
    CustomNavigator.pushAndRemoveUntil(
      context: context,
      screen: const LoginScreen(),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fade = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _splashShownAt = DateTime.now();
    checkApiStatus();
  }

  Future<void> _ensureMinimumSplashElapsed() async {
    final elapsed = DateTime.now().difference(_splashShownAt);
    final remaining = _minimumSplashDisplay - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) async {
          if (_navigated) return;

          if (state.status == AppStatus.checkStatusSuccess) {
            final token =
                PreferenceManager.getStringValue(key: "token") ?? "";

            if (!mounted) return;

            if (token.isEmpty) {
              await _ensureMinimumSplashElapsed();
              if (!mounted || _navigated) return;
              _navigated = true;
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                // screen: const SignUpScreen(),
                screen: const LoginScreen(),
              );
            }
            else {
              _awaitingProfileForRoute = true;
              context.read<AppCubit>().getProfile(token);
            }
            return;
          }

          if (_awaitingProfileForRoute &&
              state.status == AppStatus.getProfileSuccess) {
            _awaitingProfileForRoute = false;
            final response =
                state.responseData?.response as GetProfileResponse;
            PreferenceManager.cacheProfileDisplayName(response.data?.name);
            PreferenceManager.cacheProfileEmail(response.data?.email);
            await syncBillingAndChatQuotasAfterLogin(
              context.read<AppCubit>().repository,
            );
            await _ensureMinimumSplashElapsed();
            if (!mounted || _navigated) return;
            _navigated = true;
            _goHomeOrProfile(context, response);
            return;
          }

          if (_awaitingProfileForRoute &&
              state.status == AppStatus.getProfileError) {
            _awaitingProfileForRoute = false;
            if (_isUserNotFoundError(state)) {
              await _forceLogoutToLogin(context);
              return;
            }
            await _ensureMinimumSplashElapsed();
            if (!mounted || _navigated) return;
            _navigated = true;
            CustomNavigator.pushAndRemoveUntil(
              context: context,
              screen: const Editprofile(isPostLoginSetup: true),
            );
            return;
          }

          if (state.status == AppStatus.checkStatusError) {
            if (!mounted) return;
            final token =
                PreferenceManager.getStringValue(key: "token") ?? "";

            if (token.isNotEmpty) {
              _awaitingProfileForRoute = true;
              context.read<AppCubit>().getProfile(token);
            } else {
              await _ensureMinimumSplashElapsed();
              if (!mounted || _navigated) return;
              _navigated = true;
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                screen: const LoginScreen(),
              );
            }
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: heroGradient),
            child: Stack(
              children: [
                Positioned(
                  top: -120,
                  right: -120,
                  child: _softCircle(280, Colors.white.withOpacity(0.08)),
                ),
                Positioned(
                  bottom: -140,
                  left: -80,
                  child: _softCircle(320, tealColor.withOpacity(0.18)),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fade.value,
                            child: Transform.scale(
                              scale: _pulse.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tealColor.withOpacity(0.35),
                                blurRadius: 40,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/iv_app_icon2.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.auto_stories_rounded,
                                  color: appColor,
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        "Spoki AI",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Stories, conversations & learning — reimagined.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _softCircle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );

  void checkApiStatus() {
    context.read<AppCubit>().checkStatus();
  }
}
