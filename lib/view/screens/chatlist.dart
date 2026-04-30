import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/logic/inworld_tts/inworld_tts_cubit.dart';
import 'package:spokiai/view/screens/chat.dart';
import 'package:spokiai/view/screens/dashboard.dart';
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

  static const Color _brandPurple = Color(0xFF5A34D6);
  static const Color _brandPurpleDark = Color(0xFF6D3BBF);

  String? _selectedImagePath;

  final TextEditingController nameController = TextEditingController();

  /// Predefined avatar grid in display order.
  final List<String> _partnerLooks = [
    "assets/images/boy1.png",
    "assets/images/boy2.png",
    "assets/images/boy3.png",
    "assets/images/girl1.png",
    "assets/images/girl2.png",
    "assets/images/girl3.png",
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

  void selectPredefinedImage(String assetPath) {
    setState(() {
      _selectedImagePath = assetPath;
    });
  }

  bool _isMalePredefinedAvatar(String path) {
    final idx = _partnerLooks.indexOf(path);
    return idx >= 0 && idx < 3;
  }

  String _resolveSelectedGender() {
    final selected = _selectedImagePath?.toLowerCase() ?? '';
    if (selected.isEmpty) return 'Male';

    // Built-in avatars: first row male, second row female.
    if (_partnerLooks.contains(_selectedImagePath)) {
      return _isMalePredefinedAvatar(_selectedImagePath!) ? 'Male' : 'Female';
    }

    // Gallery fallback from filename hints.
    if (selected.contains('girl') ||
        selected.contains('female') ||
        selected.contains('woman')) {
      return 'Female';
    }
    if (selected.contains('boy') ||
        selected.contains('male') ||
        selected.contains('man')) {
      return 'Male';
    }

    // Default if no hint is found.
    return 'Male';
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

    final selectedGender = _resolveSelectedGender();
    await context.read<InworldTtsCubit>().setPartnerGender(selectedGender);

    final partnerDetails = <String, dynamic>{
      "name": nameController.text.trim(),
      "gender": selectedGender,
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
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const DashboardScreen(initialTabIndex: 0),
                        ),
                      ),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _brandPurple,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderBanner(),
                    const SizedBox(height: 12),
                    _buildNameCard(),
                    const SizedBox(height: 10),
                    _buildChooseAiCard(),
                  ],
                ),
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                20,
                6,
                20,
                keyboardInset > 0 ? keyboardInset + 8 : 10,
              ),
              child: _buildContinueButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Start a Conversation',
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: _brandPurpleDark,
                    height: 1.0,
                    letterSpacing: -0.8,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: Transform.translate(
                    offset: const Offset(1, -7),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: _brandPurpleDark,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Speak naturally. Improve with every reply.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF85889A),
            height: 1.15,
          ),
        ),
      ],
    );
  }

  Widget _buildNameCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2EEFF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: _brandPurple,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Name Your AI',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF202332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNameField(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Container(
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceMuted, width: 1.2),
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
          hintText: 'e.g. Alex',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: textMuted,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
    );
  }

  static const int _gridCrossAxisCount = 3;
  static const double _partnerLookAspectRatio = 1.0;

  Widget _buildChooseAiCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your AI',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF202332),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return _buildPartnerLookGrid(constraints.maxWidth);
            },
          ),
        ],
      ),
    );
  }

  /// Height derived from [width] so the grid scrolls with the form when the keyboard is open.
  Widget _buildPartnerLookGrid(double width) {
    const crossGap = 10.0;
    const mainGap = 12.0;
    if (width <= 0) {
      return const SizedBox.shrink();
    }
    return GridView.builder(
      shrinkWrap: true,
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? _brandPurple : Colors.transparent,
                    width: isSelected ? 2.2 : 0,
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
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: surfaceSoft,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person,
                        size: 22,
                        color: textMuted,
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
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _brandPurple,
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
                      size: 15,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_brandPurpleDark, _brandPurple],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _brandPurple.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                textInter(
                  text: 'Start Conversation',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
