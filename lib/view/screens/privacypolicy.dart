import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/model/privacypolicy.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String policyContent = '';

  @override
  void initState() {
    BlocProvider.of<AppCubit>(context).privacyPolicy("privacy-policy");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Privacy Policy"),
        backgroundColor: surfaceBg,
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.privacyPolicySuccess) {
            PrivacyPolicyResponse policyResponse =
                state.responseData?.response as PrivacyPolicyResponse;
            policyContent = policyResponse.data?.content.toString() ?? "";
            setState(() {});
          }

          if (state.status == AppStatus.privacyPolicyError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.privacyPolicyLoading) {
            return Center(child: CircularProgressIndicator(color: appColor));
          }

          if (policyContent.isEmpty) {
            return Center(
              child: Text(
                "No content available",
                style: GoogleFonts.inter(
                    color: textSecondary, fontWeight: FontWeight.w500),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SectionCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                policyContent,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
