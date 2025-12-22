import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/custom_widgets.dart';
import 'login.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          text: "Reset Password",
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                textRoboto(
                  text: "Create a new password",
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                SpaceWidget(height: 8),
                textRoboto(
                  text: "Your new password must be different from previous passwords",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: isDarkMode ? Colors.grey : Colors.grey[700]!,
                ),
                SpaceWidget(height: 40),
                // Password Field
                TextFieldWidget(
                  title: "Password",
                  controller: _passwordController,
                  textFieldBorderColor: textFieldBorderColor,
                  textInputType: TextInputType.text,
                  textColor: isDarkMode ? Colors.white : Colors.black,
                  hint: 'Enter new password',
                  maxLines: 1,
                  obsecure: _obscurePassword,
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
                SpaceWidget(height: 20),
                // Confirm Password Field
                TextFieldWidget(
                  title: "Confirm Password",
                  controller: _confirmPasswordController,
                  textFieldBorderColor: textFieldBorderColor,
                  textInputType: TextInputType.text,
                  textColor: isDarkMode ? Colors.white : Colors.black,
                  hint: 'Confirm new password',
                  maxLines: 1,
                  obsecure: _obscureConfirmPassword,
                  hintColor: Theme.of(context).colorScheme.secondary,
                  context: context,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: isDarkMode ? Colors.grey : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                SpaceWidget(height: 40),
                button(
                  width: MediaQuery.of(context).size.width,
                  title: 'Save',
                  fontSize: 16,
                  isLoading: false,
                  fontWeight: FontWeight.w500,
                  context: context,
                  onPressed: () {
                    if (_validatePasswords()) {
                      // Here you would typically call an API to reset the password
                      // For now, we'll just navigate to login screen
                      showToast(
                        context: context,
                        message: "Password reset successfully",
                        buttonColor: Colors.green,
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _validatePasswords() {
    if (_passwordController.text.isEmpty) {
      showToast(context: context, message: "Please enter password");
      return false;
    }
    if (_passwordController.text.length < 6) {
      showToast(
        context: context,
        message: "Password must be at least 6 characters",
      );
      return false;
    }
    if (_confirmPasswordController.text.isEmpty) {
      showToast(context: context, message: "Please confirm password");
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      showToast(
        context: context,
        message: "Passwords do not match",
      );
      return false;
    }
    return true;
  }
}


