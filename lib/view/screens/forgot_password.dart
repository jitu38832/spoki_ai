import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: const Text("Forgot Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
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
                      Icons.key_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  "Forgot your password?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "No worries — enter your email and we'll send\nyou a 4-digit code to reset it.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextFieldWidget(
                  title: "Email",
                  controller: _emailController,
                  textFieldBorderColor: textFieldBorderColor,
                  textInputType: TextInputType.emailAddress,
                  textColor: textPrimary,
                  hint: 'Enter your email',
                  maxLines: 1,
                  hintColor: textMuted,
                  context: context,
                  prefixIcon:
                      Icon(Icons.mail_outline_rounded, color: appColor),
                ),
                const SizedBox(height: 32),
                button(
                  width: MediaQuery.of(context).size.width,
                  title: 'Send OTP',
                  fontSize: 16,
                  isLoading: false,
                  fontWeight: FontWeight.w600,
                  context: context,
                  icon: Icons.send_rounded,
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
