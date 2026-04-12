import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/view/screens/chat.dart';
import '../utils/colors.dart';
import '../utils/custom_navigator.dart';
import '../utils/custom_widgets.dart';
import '../utils/preference_manager.dart';

class Chatlist extends StatefulWidget {
  const Chatlist({super.key});

  @override
  State<Chatlist> createState() => _ChatlistState();
}

class _ChatlistState extends State<Chatlist> {
  static const String _kProfileSpokenLanguage = 'profile_spoken_language';

  // Mockup gradients
  static const Color _headerPink = Color(0xFFD8449E);
  static const Color _headerBlue = Color(0xFF4E54C8);
  static const Color _greenStart = Color(0xFF6CB663);
  static const Color _greenEnd = Color(0xFF8BC34A);
  static const Color _ctaBlue = Color(0xFF4E54C8);
  static const Color _ctaPurple = Color(0xFF7B61FF);

  String _selectedGender = 'Female';
  String? _selectedImagePath;

  final TextEditingController nameController = TextEditingController();

  /// Female avatars first (row 1), then male (row 2) — 3×2 grid.
  final List<String> _partnerLooks = [
    "assets/images/girl1.png",
    "assets/images/girl2.png",
    "assets/images/girl3.png",
    "assets/images/boy1.png",
    "assets/images/boy2.png",
    "assets/images/boy3.png",
  ];

  @override
  void initState() {
    super.initState();
    if (_partnerLooks.isNotEmpty) {
      _selectedImagePath = _partnerLooks.first;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  void selectPredefinedImage(String assetPath) {
    setState(() {
      _selectedImagePath = assetPath;
    });
  }

  String _languageFromProfile() {
    final raw = PreferenceManager.getStringValue(key: _kProfileSpokenLanguage)
            ?.trim() ??
        '';
    if (raw.isEmpty) return 'english';
    return raw.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _onContinue() async {
    if (nameController.text.trim().isEmpty) {
      showToast(context: context, message: "Please enter name");
      return;
    }
    if (_selectedImagePath == null) {
      showToast(context: context, message: "Please select or upload a photo");
      return;
    }

    await context.read<InworldTtsCubit>().setPartnerGender(_selectedGender);

    final partnerDetails = <String, dynamic>{
      "name": nameController.text.trim(),
      "gender": _selectedGender,
      "language": _languageFromProfile(),
      "photo": _selectedImagePath,
    };

    CustomNavigator.push(
      context: context,
      screen: ChatScreen(partnerDetails: partnerDetails),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F0FF),
              Color(0xFFEDE7F6),
              Color(0xFFE8E0F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.grey.shade800,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewportConstraints) {
                    const horizontalPadding = 20.0;
                    final contentWidth =
                        viewportConstraints.maxWidth - horizontalPadding * 2;
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderBanner(),
                          const SizedBox(height: 8),
                          _buildSectionLabel('Partner Name'),
                          const SizedBox(height: 4),
                          _buildNameField(),
                          const SizedBox(height: 8),
                          _buildSectionLabel('Gender'),
                          const SizedBox(height: 6),
                          _buildGenderRow(),
                          const SizedBox(height: 6),
                          _buildSectionLabel('Select a Partner Look'),
                          const SizedBox(height: 4),
                          if (contentWidth > 0)
                            _buildPartnerLookGrid(contentWidth),
                          const SizedBox(height: 6),
                          _buildOrDivider(),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'Add Your Partner Photo',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildGalleryButton(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
                child: _buildContinueButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [_headerPink, _headerBlue],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _headerBlue.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'Start Talking with Spoki AI',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: nameController,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'Enter name (e.g. Alex)',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGenderRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderChip(
            label: 'Male',
            isMale: true,
            isSelected: _selectedGender == 'Male',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGenderChip(
            label: 'Female',
            isMale: false,
            isSelected: _selectedGender == 'Female',
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip({
    required String label,
    required bool isMale,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedGender = label),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [_greenStart, _greenEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Colors.grey.shade300,
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _greenStart.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: _greenStart,
                  ),
                )
              else
                Icon(
                  isMale ? Icons.male_rounded : Icons.female_rounded,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const int _gridCrossAxisCount = 3;
  static const int _gridRowCount = 2;
  /// Wider than tall cells so the grid uses less vertical space (no scroll until keyboard).
  static const double _partnerLookAspectRatio = 1.3;

  /// Height derived from [width] so the grid scrolls with the form when the keyboard is open.
  Widget _buildPartnerLookGrid(double width) {
    const crossGap = 10.0;
    const mainGap = 5.0;
    if (width <= 0) {
      return const SizedBox.shrink();
    }
    final cellW =
        (width - crossGap * (_gridCrossAxisCount - 1)) / _gridCrossAxisCount;
    final cellH = cellW / _partnerLookAspectRatio;
    final gridHeight =
        cellH * _gridRowCount + mainGap * (_gridRowCount - 1);

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          crossAxisSpacing: crossGap,
          mainAxisSpacing: mainGap,
          childAspectRatio: _partnerLookAspectRatio,
        ),
        itemCount: _partnerLooks.length,
        itemBuilder: (context, index) {
          final path = _partnerLooks[index];
          final isSelected = _selectedImagePath == path;
          return GestureDetector(
            onTap: () => selectPredefinedImage(path),
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _greenStart : Colors.transparent,
                      width: isSelected ? 3 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.person,
                          size: 22,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: _greenStart,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }

  Widget _buildGalleryButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: pickImageFromGallery,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [_ctaBlue, _ctaPurple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _ctaPurple.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Choose from Gallery',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onContinue,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [appColor, appColor.withValues(alpha: 0.85)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: appColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: textInter(
                text: 'Start Talking',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
