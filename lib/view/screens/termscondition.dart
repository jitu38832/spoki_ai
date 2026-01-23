import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/privacypolicy.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';
import 'package:spokiai/viewmodel/cubit/appcubit.dart';

class TermsConditionScreen extends StatefulWidget {
  const TermsConditionScreen({super.key});

  @override
  State<TermsConditionScreen> createState() => _TermsConditionScreenState();
}

class _TermsConditionScreenState extends State<TermsConditionScreen> {
  String policyContent = '';

  @override
  void initState() {
    BlocProvider.of<AppCubit>(context).privacyPolicy("terms-and-conditions");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Terms & Condition",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        // Centers the title
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Icon & text color
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.privacyPolicySuccess) {
            PrivacyPolicyResponse policyResponse =
                state.responseData?.response as PrivacyPolicyResponse;

            policyContent = policyResponse.data?.content.toString() ?? "";

            print("Policy Content");
            print(policyContent);
            print(policyResponse.data?.content.toString());
            setState(() {

            });
          }

          if (state.status == AppStatus.privacyPolicyError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.privacyPolicyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (policyContent.isEmpty) {
            return const Center(child: Text("No content available"));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              policyContent,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          );
        },
      )
    );
  }
}
