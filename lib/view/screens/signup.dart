import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../model/getprofile.dart';
import '../../model/signup.dart';
import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/custom_widgets.dart';
import 'package:spokiai/payment/chat_freemium.dart';
import 'package:spokiai/payment/story_freemium.dart';
import 'package:spokiai/payment/post_login_entitlements_sync.dart';
import 'package:spokiai/payment/SubscriptionService.dart';

import '../utils/preference_manager.dart';
import 'dashboard.dart';
import 'editprofile.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _routeAfterSignupProfile = false;

  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  bool _isUserNotFoundError(AppStates state) {
    final code = state.errorData?.code;
    final raw = (state.errorData?.message ?? state.error ?? '').toLowerCase();
    return code == 404 ||
        raw.contains('user not found') ||
        raw.contains('no user found');
  }

  void _forceLogoutToLogin() {
    ChatFreemium.resetVolatileState();
    StoryFreemium.resetVolatileState();
    SubscriptionService.instance.clearSessionBillingState();
    PreferenceManager.clearPreferences();
    if (!mounted) return;
    showToast(context: context, message: "Session expired. Please login again.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    SpokiLogoMark(size: 72),
                    const SizedBox(height: 18),
                    Text(
                      "Welcome back",
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to keep learning with Spoki AI",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SectionCard(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFieldWidget(
                      title: 'Email Id',
                      controller: emailController,
                      textFieldBorderColor: textFieldBorderColor,
                      textInputType: TextInputType.emailAddress,
                      textColor: textPrimary,
                      hint: 'Enter email',
                      maxLines: 1,
                      hintColor: textMuted,
                      prefixIcon:
                          Icon(Icons.mail_rounded, color: appColor, size: 20),
                      context: context,
                    ),
                    const SizedBox(height: 18),
                    TextFieldWidget(
                      title: "Password",
                      obsecure: _obscurePassword,
                      controller: passwordController,
                      textFieldBorderColor: textFieldBorderColor,
                      textInputType: TextInputType.visiblePassword,
                      textColor: textPrimary,
                      hint: 'Enter password',
                      maxLines: 1,
                      hintColor: textMuted,
                      prefixIcon:
                          Icon(Icons.lock_rounded, color: appColor, size: 20),
                      context: context,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                    BlocConsumer<AppCubit, AppStates>(
                      listener: (context, state) async {
                        if (state.status == AppStatus.signupSuccess) {
                          SignUpResponse signUpResponse =
                              state.responseData?.response as SignUpResponse;
                          final accessToken =
                              signUpResponse.accessToken.toString();

                          await PreferenceManager.insertValue(
                              key: "token", value: accessToken);
                          PreferenceManager.cacheProfileEmail(
                              emailController.text.trim());

                          if (!context.mounted) return;
                          showToast(
                            context: context,
                            message: "Logged in successfully",
                            buttonColor: successColor,
                          );

                          setState(() => _routeAfterSignupProfile = true);
                          context.read<AppCubit>().getProfile(accessToken);
                          return;
                        }

                        if (_routeAfterSignupProfile &&
                            state.status == AppStatus.getProfileSuccess) {
                          setState(() => _routeAfterSignupProfile = false);
                          final response = state.responseData?.response
                              as GetProfileResponse;
                          PreferenceManager.cacheProfileDisplayName(
                              response.data?.name);
                          await syncBillingAndChatQuotasAfterLogin(
                            context.read<AppCubit>().repository,
                          );
                          if (!context.mounted) return;
                          final incomplete =
                              profileNeedsCompletion(response.data);
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

                        if (_routeAfterSignupProfile &&
                            state.status == AppStatus.getProfileError) {
                          setState(() => _routeAfterSignupProfile = false);
                          if (_isUserNotFoundError(state)) {
                            _forceLogoutToLogin();
                            return;
                          }
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Editprofile(
                                  isPostLoginSetup: true),
                            ),
                            (route) => false,
                          );
                          return;
                        }

                        if (state.status == AppStatus.signupError) {
                          showToast(
                              context: context,
                              message:
                                  state.errorData?.message.toString() ?? "");
                        }
                      },
                      builder: (context, state) {
                        final loading =
                            state.status == AppStatus.signupLoading ||
                                (_routeAfterSignupProfile &&
                                    state.status ==
                                        AppStatus.getProfileLoading);
                        return button(
                          width: MediaQuery.of(context).size.width,
                          title: 'Login',
                          fontSize: 16,
                          isLoading: loading,
                          fontWeight: FontWeight.w600,
                          icon: Icons.arrow_forward_rounded,
                          context: context,
                          onPressed: () async {
                            if (isValidation()) {
                              FocusManager.instance.primaryFocus?.unfocus();
                              Map<String, dynamic> signUpDetails = {
                                "email": emailController.text.trim(),
                                "password": passwordController.text.trim(),
                              };

                              isInternetConnected().then((value) {
                                if (value) {
                                  BlocProvider.of<AppCubit>(context)
                                      .signUp(signUpDetails);
                                } else {
                                  showToast(
                                      context: context, message: notConnected);
                                }
                              });
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isValidation() {
    if (emailController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter email ID");
      return false;
    }
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      showToast(context: context, message: "Please enter a valid email ID");
      return false;
    }

    if (passwordController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter password");
      return false;
    }

    return true;
  }
}
