import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/custom_widgets.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: textRoboto(
          text: "Forgot Password",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  textRoboto(
                    text: "Enter your email address",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  SpaceWidget(height: 8),
                  textRoboto(
                    text: "We'll send you an OTP to reset your password",
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? Colors.grey : Colors.grey[700]!,
                  ),
                  SpaceWidget(height: 40),
                  TextFieldWidget(
                    title: "Email",
                    controller: _emailController,
                    textFieldBorderColor: textFieldBorderColor,
                    textInputType: TextInputType.emailAddress,
                    textColor: isDarkMode ? Colors.white : Colors.black,
                    hint: 'Enter your email',
                    maxLines: 1,
                    hintColor: Theme.of(context).colorScheme.secondary,
                    context: context,
                  ),
                  SpaceWidget(height: 40),
                  button(
                    width: MediaQuery.of(context).size.width,
                    title: 'Send OTP',
                    fontSize: 16,
                    isLoading: false,
                    fontWeight: FontWeight.w500,
                    context: context,
                    onPressed: () {
                      if (_validateEmail()) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OTPScreen(
                              email: _emailController.text.trim(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _validateEmail() {
    if (_emailController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter email ID");
      return false;
    }
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      showToast(context: context, message: "Please enter a valid email ID");
      return false;
    }
    return true;
  }
}


