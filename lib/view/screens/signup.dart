import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../viewmodel/cubit/app_state.dart';
import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  final RegExp emailRegex = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode ? Colors.black : Colors.white,
        statusBarIconBrightness:
        isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                  textRoboto(
                      text: "Sign Up",
                      color: const Color(0xff6B6B6B),
                      fontWeight: FontWeight.w600,
                      fontSize: 20),
                  SpaceWidget(height: 20),

                  TextFieldWidget(
                    title: "User Name",
                    controller: userNameController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.name,
                    textColor: isDarkMode ? Colors.white : Colors.black,
                    hint: 'Enter User Name',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                  ),
                  SpaceWidget(height: 20),

                  TextFieldWidget(
                    title: 'Email Id',
                    controller: emailController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.emailAddress,
                    textColor: isDarkMode ? Colors.white : Colors.black,
                    hint: 'Enter Email Id',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                  ),
                  SpaceWidget(height: 20),

                  TextFieldWidget(
                    title: "Password",
                    obsecure: _obscurePassword,
                    controller: passwordController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.visiblePassword,
                    textColor: isDarkMode ? Colors.white : Colors.black,
                    hint: 'Enter Password',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: isDarkMode ? Colors.grey : Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  SpaceWidget(height: 50),

                  BlocConsumer<AppCubit, AppStates>(
                    listener: (context, state) async {
                      // if (state.status == AppStatus.signupSuccess) {
                      //  SignUpResponse signUpResponse =
                      //   state.responseData?.response as SignUpResponse;
                      //   showToast(
                      //       context: context,
                      //       buttonColor: Colors.green,
                      //       message: signUpResponse.message.toString());
                      //   Navigator.pop(context);
                      // } else if (state.status == AppStatus.signupError) {
                      //   showToast(
                      //       context: context,
                      //       message: state.errorData?.message.toString() ?? "");
                      // }
                    },
                    builder: (context, state) {
                      return button(
                        width: MediaQuery.of(context).size.width,
                        title: 'Sign Up',
                        fontSize: 16,
                        isLoading: false,
                        fontWeight: FontWeight.w500,
                        context: context,
                        onPressed: () async {

                          CustomNavigator.pushAndRemoveUntil(
                            context: context,
                            screen:  DashboardScreen(),
                          );
                          // if (isValidation()) {
                          //   FocusManager.instance.primaryFocus?.unfocus();
                          //   Map<String, dynamic> signUpDetails = {
                          //     "email": emailController.text.trim(),
                          //     "password": passwordController.text.trim(),
                          //     "username": userNameController.text.trim(),
                          //   };

                            // isInternetConnected().then((value) {
                            //   if (value) {
                            //     BlocProvider.of<AppCubit>(context)
                            //         .signUp(signUpDetails);
                            //   } else {
                            //     showToast(
                            //         context: context, message: notConnected);
                            //   }
                            // });
                          // }
                        },
                      );
                    },
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  textRoboto(text: "OR", fontSize: 16),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  GestureDetector(

                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: greyColor),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login),
                          const SizedBox(width: 20),
                          textInter(
                              text: "Continue with Google",
                              fontSize: 15,
                              color: Colors.black,
                              fontWeight: FontWeight.w400),
                        ],
                      ),
                    ),
                  ),
                  SpaceWidget(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      textInter(
                          text: "Already have an account?",
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.w400),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: textInter(
                            text: "Sign In",
                            fontSize: 15,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                            fontWeight: FontWeight.w400),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isValidation() {
    if (userNameController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter username");
      return false;
    }

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
