import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        backgroundColor: surfaceBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Reset Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: brandGradient,
                    boxShadow: brandShadow(opacity: 0.22, blur: 20),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                "Create a new password",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your new password must be different\nfrom previous passwords",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextFieldWidget(
                title: "Password",
                controller: _passwordController,
                textFieldBorderColor: textFieldBorderColor,
                textInputType: TextInputType.text,
                textColor: textPrimary,
                hint: 'Enter new password',
                maxLines: 1,
                obsecure: _obscurePassword,
                hintColor: textMuted,
                context: context,
                prefixIcon: Icon(Icons.lock_outline_rounded, color: appColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              TextFieldWidget(
                title: "Confirm Password",
                controller: _confirmPasswordController,
                textFieldBorderColor: textFieldBorderColor,
                textInputType: TextInputType.text,
                textColor: textPrimary,
                hint: 'Confirm new password',
                maxLines: 1,
                obsecure: _obscureConfirmPassword,
                hintColor: textMuted,
                context: context,
                prefixIcon:
                    Icon(Icons.lock_outline_rounded, color: appColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: textMuted,
                  ),
                  onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 32),
              button(
                width: MediaQuery.of(context).size.width,
                title: 'Save Password',
                fontSize: 16,
                isLoading: false,
                fontWeight: FontWeight.w600,
                context: context,
                icon: Icons.check_circle_rounded,
                onPressed: () {
                  if (_validatePasswords()) {
                    showToast(
                      context: context,
                      message: "Password reset successfully",
                      buttonColor: successColor,
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
      showToast(context: context, message: "Passwords do not match");
      return false;
    }
    return true;
  }
}
