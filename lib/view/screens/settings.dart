import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/contact_support_screen.dart';
import 'package:spokiai/view/screens/feedback_screen.dart';
import 'package:spokiai/view/screens/login.dart';
import 'package:spokiai/view/screens/privacypolicy.dart';
import 'package:spokiai/view/screens/termscondition.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'package:spokiai/view/utils/preference_manager.dart';
import 'package:spokiai/view/utils/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = ThemeController.isDarkModeEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool compact = screenHeight < 760;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          iconSize: compact ? 17.6 : 19.2,
          color: scheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: GoogleFonts.inter(
            color: scheme.onSurface,
            fontSize: compact ? 17.6 : 19.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding:
                  EdgeInsets.fromLTRB(20, compact ? 6 : 8, 4, compact ? 10 : 10),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    children: [
                      _sectionCard(
                        compact: compact,
                        isDark: isDark,
                        title: "PREFERENCES",
                        children: [
                          _toggleTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.notifications_none_rounded,
                            title: "Notifications",
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                              showToast(
                                context: context,
                                message: value
                                    ? "Notifications enabled"
                                    : "Notifications disabled",
                              );
                            },
                          ),
                          _sectionDivider(isDark: isDark),
                          _toggleTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.dark_mode_outlined,
                            title: "Dark Mode",
                            value: _darkModeEnabled,
                            onChanged: (value) {
                              setState(() => _darkModeEnabled = value);
                              ThemeController.setDarkMode(value);
                              showToast(
                                context: context,
                                message: "Dark mode setting saved",
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _sectionCard(
                        compact: compact,
                        isDark: isDark,
                        title: "PRIVACY",
                        children: [
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.lock_outline_rounded,
                            title: "Privacy Policy",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _sectionCard(
                        compact: compact,
                        isDark: isDark,
                        title: "SUPPORT",
                        children: [
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.headset_mic_rounded,
                            title: "Contact Support",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ContactSupportScreen(),
                                ),
                              );
                            },
                          ),
                          _sectionDivider(isDark: isDark),
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.forum_outlined,
                            title: "Send Feedback",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const FeedbackScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _sectionCard(
                        compact: compact,
                        isDark: isDark,
                        title: "ABOUT",
                        children: [
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.info_outline_rounded,
                            title: "About Spoki AI",
                            onTap: () => showToast(
                              context: context,
                              message: "Spoki AI v1.0.0",
                            ),
                          ),
                          _sectionDivider(isDark: isDark),
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.description_outlined,
                            title: "Terms & Conditions",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TermsConditionScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      _sectionCard(
                        compact: compact,
                        isDark: isDark,
                        title: "DANGER ZONE",
                        titleColor: errorColor,
                        children: [
                          _actionTile(
                            compact: compact,
                            isDark: isDark,
                            icon: Icons.delete_outline_rounded,
                            title: "Delete Account",
                            iconColor: errorColor,
                            titleColor: errorColor,
                            onTap: () => _confirmAccountAction(
                              title: "Confirm Delete",
                              body: "Are you sure you want to delete your account?",
                              confirmLabel: "Yes, Delete",
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, compact ? 50 : 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: appColor.withOpacity(0.45),
                            width: 1.3,
                          ),
                          backgroundColor:
                              isDark ? const Color(0xFF1E1E2A) : Colors.white,
                        ),
                        onPressed: () => _confirmAccountAction(
                          title: "Confirm Logout",
                          body: "Are you sure you want to logout?",
                          confirmLabel: "Yes, Logout",
                        ),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: appColor,
                          size: compact ? 16.8 : 19.2,
                        ),
                        label: Text(
                          "Logout",
                          style: GoogleFonts.inter(
                            fontSize: compact ? 12.8 : 13.6,
                            fontWeight: FontWeight.w700,
                            color: appColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Color? titleColor,
    bool compact = false,
    bool isDark = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, compact ? 5 : 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFE9E3F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: titleColor ?? appColor,
                fontSize: compact ? 9.6 : 10.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool compact = false,
    bool isDark = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 5 : 8),
      child: Row(
        children: [
          _tileIcon(icon: icon, compact: compact),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : textPrimary,
                fontSize: compact ? 13.6 : 14.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: appColor,
            inactiveThumbColor: isDark ? const Color(0xFFCCCCCC) : Colors.white,
            inactiveTrackColor:
                isDark ? const Color(0xFF4A4A60) : const Color(0xFFD3CCEA),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool compact = false,
    bool isDark = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: compact ? 8 : 11),
        child: Row(
          children: [
            _tileIcon(icon: icon, color: iconColor ?? appColor, compact: compact),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: titleColor ?? (isDark ? Colors.white : textPrimary),
                  fontSize: compact ? 13.6 : 14.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: appColor, size: compact ? 17.6 : 20.8),
          ],
        ),
      ),
    );
  }

  Widget _tileIcon({
    required IconData icon,
    Color color = const Color(0xFF6D3BBF),
    bool compact = false,
  }) {
    return Container(
      width: compact ? 38 : 44,
      height: compact ? 38 : 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.95), color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 16 : 18.4),
    );
  }

  Widget _sectionDivider({required bool isDark}) {
    return Divider(
      height: 1,
      color: isDark ? const Color(0xFF2D2D3F) : const Color(0xFFECE7F8),
    );
  }

  Future<void> _confirmAccountAction({
    required String title,
    required String body,
    required String confirmLabel,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                PreferenceManager.clearPreferences();
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(confirmLabel, style: TextStyle(color: errorColor)),
            ),
          ],
        );
      },
    );
  }
}
