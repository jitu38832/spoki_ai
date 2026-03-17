import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/checkstatus.dart';
import 'package:spokiai/view/screens/dashboard.dart';
import 'package:spokiai/view/screens/signup.dart';
import 'package:spokiai/view/utils/custom_navigator.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';
import 'login.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  bool _navigated = false;

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
            _navigated = true;

            final CheckStatusResponse response =
            state.responseData?.response as CheckStatusResponse;

            final token =
                await PreferenceManager.getStringValue(key: "token") ?? "";

            if (!mounted) return;

            if (token.isNotEmpty) {
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                screen: DashboardScreen(),
              );
            } else if (response.key == true) {
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                screen: SignUpScreen(),
              );
            } else {
              CustomNavigator.pushAndRemoveUntil(
                context: context,
                screen: LoginScreen(),
              );
            }
          }

          // 🔴 Handle API failure
          if (state.status == AppStatus.checkStatusError) {
            _navigated = true;

            if (!mounted) return;

            CustomNavigator.pushAndRemoveUntil(
              context: context,
              screen: LoginScreen(),
            );
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
