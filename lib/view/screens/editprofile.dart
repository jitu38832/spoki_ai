import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spokiai/model/getprofile.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/viewmodel/cubit/app_state.dart';

import '../../viewmodel/cubit/appcubit.dart';
import '../utils/colors.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  String token = "";

  GetProfileResponse getProfileResponse = GetProfileResponse();

  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    token = PreferenceManager.getStringValue(key: "token") ?? "";

    BlocProvider.of<AppCubit>(context).getProfile(token);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<AppCubit, AppStates>(
        listener: (context, state) {
          if (state.status == AppStatus.getProfileSuccess) {
            getProfileResponse =
                state.responseData?.response as GetProfileResponse;

            emailController.text =
                getProfileResponse.data?.email.toString() ?? "";
            nameController.text =
                getProfileResponse.data?.name.toString() ?? "";
          }

          if (state.status == AppStatus.getProfileError) {
            showToast(
                context: context,
                message: state.errorData?.message.toString() ?? "");
          }
        },
        builder: (context, state) {
          if (state.status == AppStatus.getProfileLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: appColor,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextFieldWidget(
                  title: 'Name',
                  controller: nameController,
                  textFieldBorderColor: textFieldBorderColor,
                  textInputType: TextInputType.emailAddress,
                  textColor: Colors.black,
                  hint: 'Enter name',
                  maxLines: 1,
                  hintColor: Theme.of(context).colorScheme.secondary,
                  context: context,
                ),
                SizedBox(
                  height: 20,
                ),
                TextFieldWidget(
                  title: 'Email Id',
                  controller: emailController,
                  textFieldBorderColor: textFieldBorderColor,
                  textInputType: TextInputType.emailAddress,
                  textColor: Colors.black,
                  hint: 'Enter Email Id',
                  maxLines: 1,
                  hintColor: Theme.of(context).colorScheme.secondary,
                  context: context,
                ),
                SizedBox(
                  height: 40,
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                  },
                  child: Card(
                    elevation: 6,
                    shadowColor: appColor.withOpacity(0.8),
                    child: Container(
                      decoration: BoxDecoration(
                          color: appColor,
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            textInter(
                                text: "Update Profile",
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w400)
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
