import 'dart:io';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:spokiai/model/getprofile.dart' as profile_model;
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
  bool _routeAfterGoogleProfile = false;

  bool _isBlank(String? v) => v == null || v.trim().isEmpty;

  bool _isUserNotFoundError(AppStates state) {
    final code = state.errorData?.code;
    final raw = (state.errorData?.message ?? state.error ?? '').toLowerCase();
    return code == 404 ||
        raw.contains('user not found') ||
        raw.contains('no user found');
  }

  Future<void> _forceLogoutToLogin(BuildContext context) async {
    PreferenceManager.clearPreferences();
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    showToast(context: context, message: "Session expired. Please login again.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  bool _needsProfileCompletion(profile_model.Data? data) {
    if (data == null) return true;
    if (_isBlank(data.name) || _isBlank(data.email)) return true;
    return _isBlank(data.gender) ||
        data.age == null ||
        data.age! < 1 ||
        _isBlank(data.englishLevel) ||
        _isBlank(data.spokenLanguage);
  }

  Future<void> _onAuthSuccess({
    required BuildContext context,
    required String accessToken,
  }) async {
    await PreferenceManager.insertValue(key: "token", value: accessToken);

    if (!context.mounted) return;
    showToast(
      context: context,
      message: "Logged in successfully",
      buttonColor: successColor,
    );

    setState(() => _routeAfterGoogleProfile = true);
    context.read<AppCubit>().getProfile(accessToken);
  }

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
        child: SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(gradient: backgroundSheetGradient),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Image.asset(
                    "assets/images/logo.png",
                    height: 230,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Spoki",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Practice English with Spoki AI",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 43,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "Chat, speak, and learn with interactive AI stories.",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLoginSection(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) async {
        if (state.status == AppStatus.loginError ||
            state.status == AppStatus.appleLoginError) {
          final backendMessage = state.errorData?.message.trim().isNotEmpty == true
              ? state.errorData!.message
              : (state.error?.trim().isNotEmpty == true
                  ? state.error!
                  : "Google Sign-In failed. Please try again.");

          developer.log(
            "Login API error",
            name: "LoginScreen",
            error: backendMessage,
          );

          if (!context.mounted) return;
          showToast(
            context: context,
            message: backendMessage,
            maxLines: 6,
            toastDuration: const Duration(seconds: 6),
          );
          return;
        }

        if (state.status == AppStatus.loginSuccess) {
          GoogleLoginResponse googleLoginResponse =
              state.responseData?.response as GoogleLoginResponse;
          final accessToken =
              googleLoginResponse.data?.tokens?.access?.token.toString() ?? "";
          await _onAuthSuccess(context: context, accessToken: accessToken);
          return;
        }

        if (state.status == AppStatus.appleLoginSuccess) {
          GoogleLoginResponse appleLoginResponse =
              state.responseData?.response as GoogleLoginResponse;
          final accessToken =
              appleLoginResponse.data?.tokens?.access?.token.toString() ?? "";
          await _onAuthSuccess(context: context, accessToken: accessToken);
          return;
        }

        if (_routeAfterGoogleProfile &&
            state.status == AppStatus.getProfileSuccess) {
          setState(() => _routeAfterGoogleProfile = false);
          final response =
              state.responseData?.response as profile_model.GetProfileResponse;
          if (!context.mounted) return;
          final incomplete = _needsProfileCompletion(response.data);
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

        if (_routeAfterGoogleProfile && state.status == AppStatus.getProfileError) {
          setState(() => _routeAfterGoogleProfile = false);
          if (_isUserNotFoundError(state)) {
            await _forceLogoutToLogin(context);
            return;
          }
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const Editprofile(isPostLoginSetup: true),
            ),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final loading = state.status == AppStatus.loginLoading ||
            state.status == AppStatus.appleLoginLoading ||
            (_routeAfterGoogleProfile &&
                state.status == AppStatus.getProfileLoading);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _socialButton(
              label: loading ? "Signing you in..." : "Continue with Google",
              leading: _googleLogo(),
              isLoading: loading,
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                await signInWithGoogle(context);
              },
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              _socialButton(
                label: loading ? "Signing you in..." : "Continue with Apple",
                leading: const Icon(Icons.apple, color: Colors.black, size: 27),
                isLoading: loading,
                onTap: () async {
                  await signInWithApple(context);
                },
              ),
            ],
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                text: "By continuing, you agree to our ",
                style: GoogleFonts.inter(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
                children: [
                  TextSpan(
                    text: "Terms",
                    style: GoogleFonts.inter(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: appColorDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text: " & ",
                    style: GoogleFonts.inter(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: "Privacy Policy.",
                    style: GoogleFonts.inter(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      color: appColorDark,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _socialButton({
    required String label,
    required Widget leading,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: surfaceMuted),
            boxShadow: softCardShadow(),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: leading)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16.8,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: textSecondary,
                  size: 25,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleLogo() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
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
      // Ensure a fresh account picker/session each time.
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        showToast(
          context: context,
          message:
              "Google Sign-In configuration issue: missing ID token (check OAuth client setup).",
        );
        return;
      }
      BlocProvider.of<AppCubit>(context).login(idToken.toString());
    } catch (error, stackTrace) {
      developer.log(
        "Google Sign-In failed",
        name: "LoginScreen",
        error: error,
        stackTrace: stackTrace,
      );
      debugPrint("Google Sign-In failed (full): ${error.toString()}");
      debugPrint("Google Sign-In stack (full):\n$stackTrace");

      final messageText = error.toString();
      if (Platform.isAndroid &&
          (messageText.contains("ApiException: 10") ||
              messageText.contains("DEVELOPER_ERROR"))) {
        showToast(
          context: context,
          message:
              "Google Sign-In failed due to Android OAuth config. Add correct SHA-1/SHA-256 in Firebase and re-download google-services.json.",
          maxLines: 6,
          toastDuration: const Duration(seconds: 6),
        );
        return;
      }
      showToast(
        context: context,
        message: "Google Sign-In failed: $messageText",
        maxLines: 6,
        toastDuration: const Duration(seconds: 6),
      );
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

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.19;
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red, yellow, green, blue segments around the ring.
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -0.12 * math.pi, 0.46 * math.pi, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.30 * math.pi, 0.34 * math.pi, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.64 * math.pi, 0.56 * math.pi, false, paint);

    paint.color = const Color(0xFF4285F4);
    // Keep total ring coverage near 90% of a full circle.
    canvas.drawArc(rect, 1.20 * math.pi, 0.56 * math.pi, false, paint);

    // Cut a clean opening on the right side before drawing the bar.
    final clearPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.33,
        size.width * 0.46,
        size.height * 0.34,
      ),
      clearPaint,
    );

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.88
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.52, center.dy),
      Offset(size.width * 0.91, center.dy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
