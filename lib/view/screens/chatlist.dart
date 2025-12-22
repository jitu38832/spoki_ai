import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spokiai/view/screens/storyDescription.dart';

import '../utils/colors.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import 'chat.dart';

class Chatlist extends StatefulWidget {
  const Chatlist({super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  String? gender;
  String? ageStage;
  String _selectedGender = 'Male';
  String _selectedAge = 'Young';
  File? selectedImage;

  final TextEditingController _storyDescriptionController =
      TextEditingController();

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 6,
          shadowColor: appColor.withOpacity(0.8),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: appColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  CustomNavigator.push(
                      context: context, screen: ChatScreen());
                },
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: textInter(
                    text: "Next",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "Choose Partner",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset("assets/images/iv_cartoon.png", height: 30,width: 30,),
                          SizedBox(
                            width: 30,
                          ),
                          Image.asset("assets/images/iv_cartoon.png",height: 30,width: 30,)
                        ],
                      )),
                ),

                const SizedBox(height: 20),

                // TITLE
                const Text(
                  "Write Your Partner's Name",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                _buildStoryDescriptionInput(),
                const SizedBox(height: 24),

                // GENDER --------------------------------
                const Text(
                  "Gender",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                _buildGenderSelection(),

                const SizedBox(height: 20),

                // AGE STAGE -------------------------------
                const Text(
                  "Age Stage",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _buildAgeSelection(),

                const SizedBox(height: 20),

                // PHOTO SELECT -----------------------------
                const Text(
                  "Add a photo for your Character.",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: const [
                        Icon(Icons.upload, size: 40, color: Colors.blue),
                        Text("Upload"),
                      ],
                    ),
                    const Text(
                      "OR",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        pickImage();
                      },
                      child: Column(
                        children: const [
                          Icon(Icons.photo_library,
                              size: 40, color: Colors.lightBlue),
                          Text("Choose"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.1,
                  child: GridView.builder(
                    itemCount: 3,

                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 20,
                        childAspectRatio: 2,

                        crossAxisCount: 3), itemBuilder: (context, index) {
                    return Image.asset("assets/images/iv_male.jpg", height: 70,width: 70,);
                  },),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.1,
                  child: GridView.builder(
                    itemCount: 3,

                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        mainAxisSpacing: 20,
                        childAspectRatio: 2,

                        crossAxisCount: 3), itemBuilder: (context, index) {
                    return Image.asset("assets/images/iv_girl.jpg", height: 70,width: 70,);
                  },),
                ),

                const SizedBox(height: 20),
                if (selectedImage != null)
                  Image.file(
                    selectedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2, // <-- Increased border width
        ),
        borderRadius: BorderRadius.circular(12),

        // ---- Shadow added ----
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _storyDescriptionController,
        maxLines: 1,
        decoration: InputDecoration(
          hintText: "Enter name",
          hintStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: _buildGenderButton('Male',
                isSelected: _selectedGender == 'Male'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGenderButton('Female',
                isSelected: _selectedGender == 'Female'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildGenderButton('Other',
                isSelected: _selectedGender == 'Other', hasLock: true),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label,
      {required bool isSelected, bool hasLock = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor : appColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            textInter(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeSelection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child:
                _buildAgeButton('Young', isSelected: _selectedAge == 'Young'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                _buildAgeButton('Adult', isSelected: _selectedAge == 'Adult'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAgeButton(
              'Old',
              isSelected: _selectedAge == 'Old',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeButton(String label,
      {required bool isSelected, bool hasLock = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor : appColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            textInter(
              text: label,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sampleImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
      ),
    );
  }
}
