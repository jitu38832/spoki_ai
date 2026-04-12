import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spokiai/view/screens/chat.dart';
import '../utils/colors.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';

class Chatlist extends StatefulWidget {
  const Chatlist({super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  String _selectedGender = 'Male';
  String _selectedAge = 'Young';
  String? _selectedImagePath; // Holds path of selected image (asset or file)

  final TextEditingController nameController = TextEditingController();

  // Predefined images (replace with your actual asset paths)
  final List<String> boyImages = [
    "assets/images/boy1.png",
    "assets/images/boy2.png",
    "assets/images/boy3.png",
  ];
  String? _selectedLanguage;

  final List<String> languages = [
    "Chinese",
    "Arabic",
    "French", // corrected spelling
    "German",
    "Indonesian",
    "Italian",
    "Japanese",
    "Korean",
    "Russian",
    "Spanish", // corrected spelling
    "Thai",
    "Turkish",
    "Vietnamese",
    "Persian",
    "Hindi",
    "Telugu",
    "Tamil",
    "Malayalam",
    "Kannada",
    "Bengali",
  ];

  final List<String> girlImages = [
    "assets/images/girl1.png",
    "assets/images/girl2.png",
    "assets/images/girl3.png",
  ];

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path; // Use gallery image
      });
    }
  }

  void selectPredefinedImage(String assetPath) {
    setState(() {
      _selectedImagePath = assetPath;
    });
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
                  if (nameController.text.trim().isEmpty) {
                    showToast(context: context, message: "Please enter name");
                  } else if (_selectedLanguage == null) {
                    showToast(
                        context: context, message: "Please select language");
                  } else {
                    Map<String, dynamic> partnerDetails = {
                      "name": nameController.text.trim(),
                      "gender": _selectedGender,
                      // "age": _selectedAge,
                      "language": _selectedLanguage.toString().toLowerCase(),
                      "photo": _selectedImagePath,
                      // Can be asset path or file path
                    };

                    print("All details");
                    print(partnerDetails);

                    CustomNavigator.push(
                      context: context,
                      screen: ChatScreen(partnerDetails: partnerDetails),
                    );
                  }
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
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
                      Image.asset("assets/images/iv_cartoon.png",
                          height: 30, width: 30),
                      const SizedBox(width: 30),
                      Image.asset("assets/images/iv_cartoon.png",
                          height: 30, width: 30),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Write Your Partner's Name",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),

              _buildStoryDescriptionInput(),
              const SizedBox(height: 24),

              const Text(
                "Gender",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildGenderSelection(),

              const SizedBox(height: 20),

              // const Text(
              //   "Age Stage",
              //   style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 10),
              // _buildAgeSelection(),
              //
              // const SizedBox(height: 20),

              const Text(
                "Language",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage,
                  hint: const Text(
                    "Select a language",
                    style: TextStyle(color: Colors.grey),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  underline: const SizedBox(),
                  // removes default underline
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  },
                  items: languages
                      .map<DropdownMenuItem<String>>((String language) {
                    return DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Choose a photo for your Character",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: pickImageFromGallery,
                    child: Column(
                      children: const [
                        Icon(Icons.upload, size: 40, color: Colors.blue),
                        Text("Upload"),
                      ],
                    ),
                  ),
                  const Text(
                    "OR",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: pickImageFromGallery,
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

              const SizedBox(height: 20),

              // Boy Images
              // const Text("Boys", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: boyImages.length,
                  itemBuilder: (context, index) {
                    String path = boyImages[index];
                    bool isSelected = _selectedImagePath == path;
                    return GestureDetector(
                      onTap: () => selectPredefinedImage(path),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? appColor : Colors.transparent,
                            width: isSelected ? 2 : 0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            path,
                            width: MediaQuery.of(context).size.width * 0.28,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // const SizedBox(height: 20),
              //
              // // Girl Images
              // const Text("Girls", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                width: MediaQuery.of(context).size.width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: girlImages.length,
                  itemBuilder: (context, index) {
                    String path = girlImages[index];
                    bool isSelected = _selectedImagePath == path;
                    return GestureDetector(
                      onTap: () => selectPredefinedImage(path),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? appColor : Colors.transparent,
                            width: isSelected ? 2 : 0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            path,
                            width: MediaQuery.of(context).size.width * 0.28,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Selected Image Preview
              if (_selectedImagePath != null)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImagePath!.startsWith("assets/")
                        ? Image.asset(
                            _selectedImagePath!,
                            height: 100,
                            width: MediaQuery.of(context).size.width * 0.28,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImagePath!),
                            height: 100,
                            width: MediaQuery.of(context).size.width * 0.28,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoryDescriptionInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(12),
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
        controller: nameController,
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
                  isSelected: _selectedGender == 'Male')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildGenderButton('Female',
                  isSelected: _selectedGender == 'Female')),
          // const SizedBox(width: 12),
          // Expanded(
          //   child: _buildGenderButton(
          //     'Other',
          //     isSelected: _selectedGender == 'Other',
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label,
      {required bool isSelected, bool hasLock = false}) {
    return GestureDetector(
      onTap: hasLock
          ? null
          : () {
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
              color: Colors.white,
            ),
            if (hasLock)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.lock, size: 16, color: Colors.white70),
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
              child: _buildAgeButton('Young',
                  isSelected: _selectedAge == 'Young')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildAgeButton('Adult',
                  isSelected: _selectedAge == 'Adult')),
          const SizedBox(width: 12),
          Expanded(
              child: _buildAgeButton('Old', isSelected: _selectedAge == 'Old')),
        ],
      ),
    );
  }

  Widget _buildAgeButton(String label, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAge = label;
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
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
