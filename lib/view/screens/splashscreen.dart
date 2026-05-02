import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/login.dart';
import 'package:spokiai/view/screens/signup.dart';
import 'package:spokiai/view/utils/custom_navigator.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _navigated = false;
  bool _awaitingProfileForRoute = false;

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

  @override
  void initState() {
    super.initState();
    checkApiStatus();
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
            _navigated = true;
            final response =
                state.responseData?.response as GetProfileResponse;
            if (!mounted) return;
            _goHomeOrProfile(context, response);
            return;
          }

          if (_awaitingProfileForRoute &&
              state.status == AppStatus.getProfileError) {
            _awaitingProfileForRoute = false;
            _navigated = true;
            if (!mounted) return;
            CustomNavigator.pushAndRemoveUntil(
              context: context,
              screen: const Editprofile(isPostLoginSetup: true),
            );
            return;
          }

          if (state.status == AppStatus.checkStatusError) {
            if (!mounted) return;

            // If the `users/key` check fails but we already have a token,
            // still route using the profile completeness check.
            final token =
                PreferenceManager.getStringValue(key: "token") ?? "";

            if (token.isNotEmpty) {
              _awaitingProfileForRoute = true;
              context.read<AppCubit>().getProfile(token);
            } else {
              _navigated = true;
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                screen: const SignUpScreen(),
              );
            }
          }
        },
        builder: (context, state) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/iv_splash_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  void checkApiStatus() {
    context.read<AppCubit>().checkStatus();
  }
}
