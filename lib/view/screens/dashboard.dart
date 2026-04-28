import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/chatlist.dart';
import 'package:spokiai/view/screens/editprofile.dart';
import 'package:spokiai/view/screens/settings.dart';
import 'package:spokiai/view/screens/storyhistory.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'package:spokiai/view/utils/custom_widgets.dart';
import 'home.dart';

class DashboardScreen extends StatefulWidget {
  final int? initialTabIndex;
  const DashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _screens => [
        HomeScreen(
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const StoryHistoryScreen(),
        const Chatlist(),
      ];

  final List<_NavItem> _items = [
    _NavItem(Icons.home, Icons.home_outlined, "Home"),
    _NavItem(Icons.access_time_filled, Icons.access_time, "History"),
    _NavItem(Icons.chat, Icons.chat_bubble_outline, "Chat"),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex != null) {
      _selectedIndex = widget.initialTabIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: surfaceBg,
      drawer: _selectedIndex == 0 ? _buildAppDrawer() : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SafeArea(
          top: false,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: appColor.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_items.length, (i) {
                final selected = i == _selectedIndex;
                final item = _items[i];
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedIndex = i),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? item.selectedIcon : item.icon,
                            color:
                                selected ? appColor : textSecondary,
                            size: 27,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                              color: selected ? appColor : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool compact = MediaQuery.of(context).size.height <= 820;
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.97,
      backgroundColor: isDark ? const Color(0xFF14141D) : const Color(0xFFF4EFFB),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(12, compact ? 10 : 14, 12, 14),
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 12 : 14,
                compact ? 10 : 12,
                compact ? 12 : 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD1C4F1), Color(0xFFE1DCF0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _closeDrawer,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: compact ? 28 : 30,
                        height: compact ? 28 : 30,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.16)
                              : Colors.white.withOpacity(0.82),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white : const Color(0xFF36206E),
                          size: compact ? 16 : 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Opacity(
                      opacity: 0.45,
                      child: SizedBox(
                        width: compact ? 130 : 170,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List.generate(
                            36,
                            (index) => Container(
                              width: 3.2,
                              height: 3.2,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: compact ? 98 : 112,
                        height: compact ? 98 : 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFF2F2F3F) : Colors.white,
                            width: 5,
                          ),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC8B9FA), Color(0xFFB9A5F4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: compact ? 58 : 66,
                        ),
                      ),
                      SizedBox(width: compact ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mohd Salim",
                              style: GoogleFonts.inter(
                                fontSize: compact ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF141246),
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: compact ? 4 : 6),
                            Text(
                              "Learning English Daily",
                              style: GoogleFonts.inter(
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withOpacity(0.88)
                                    : const Color(0xFF4F4B77),
                              ),
                            ),
                            SizedBox(height: compact ? 6 : 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _drawerChip(
                                    icon: Icons.circle,
                                    iconColor: const Color(0xFF8ED06F),
                                    text: "Active Learner",
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 1,
                                  height: compact ? 20 : 22,
                                  color: const Color(0xFFB4A8DB),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _drawerChip(
                                    icon: Icons.local_fire_department_rounded,
                                    iconColor: const Color(0xFFFF7A33),
                                    text: "3 Day Streak",
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 8 : 12),
            _drawerSectionCard(
              compact: compact,
              children: [
                _drawerRowItem(
                  icon: Icons.person_rounded,
                  title: "My Profile",
                  subtitle: "View & edit your details",
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Editprofile(),
                      ),
                    );
                  },
                  compact: compact,
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFECE7F8),
                ),
                _drawerRowItem(
                  icon: Icons.star_rounded,
                  title: "Upgrade to Pro",
                  subtitle: "Unlock AI Chat & Unlimited Stories",
                  onTap: () => _closeDrawerAndToast("Coming soon"),
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                _drawerUpgradeButton(compact: compact),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            _drawerSectionCard(
              compact: compact,
              children: [
                _drawerRowItem(
                  icon: Icons.group_rounded,
                  title: "Invite Friends",
                  subtitle: "Earn rewards & grow together",
                  onTap: () => _closeDrawerAndToast("Coming soon"),
                  compact: compact,
                ),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFECE7F8),
                ),
                _drawerRowItem(
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  subtitle: "Manage app preferences",
                  onTap: () {
                    _closeDrawer();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            _drawerPromoCard(
              title: "Learn Daily on WhatsApp",
              subtitle: "Get tips & updates daily",
              buttonText: "Join Now",
              icon: Icons.call,
              onTap: () => _closeDrawerAndToast("Coming soon"),
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 10),
            _drawerPromoCard(
              title: "Practice on Telegram",
              subtitle: "Free discussions & speaking",
              buttonText: "Join Now",
              icon: Icons.send_rounded,
              onTap: () => _closeDrawerAndToast("Coming soon"),
              compact: compact,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  void _closeDrawerAndToast(String message) {
    _closeDrawer();
    showToast(context: context, message: message);
  }

  Widget _drawerChip({
    required IconData icon,
    required Color iconColor,
    required String text,
    bool compact = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252535).withOpacity(0.9)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF3B3B50) : const Color(0xFFD6CFFA)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 10 : 12, color: iconColor),
            SizedBox(width: compact ? 5 : 6),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: compact ? 10.5 : 12.5,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSectionCard({
    required List<Widget> children,
    bool compact = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF2F2F3F) : const Color(0xFFEAE5F7)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : const Color(0xFF2D1769).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _drawerRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool compact = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color tint = iconColor ?? appColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
        child: Row(
          children: [
            Container(
              width: compact ? 42 : 48,
              height: compact ? 42 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tint.withOpacity(0.95), tint.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: compact ? 21 : 24),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: compact ? 1 : 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 12.6 : 14.3,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFFB69CFF) : const Color(0xFF7540E5),
              size: compact ? 24 : 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerUpgradeButton({bool compact = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _closeDrawerAndToast("Coming soon"),
      child: Container(
        height: compact ? 46 : 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: compact ? 6 : 8),
              Text(
                "Upgrade Now",
                style: GoogleFonts.inter(
                  fontSize: compact ? 15.5 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerPromoCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required VoidCallback onTap,
    bool compact = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 14,
        compact ? 12 : 16,
        compact ? 12 : 14,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF262638), Color(0xFF1E1E2D)]
              : const [Color(0xFFF4F0FE), Color(0xFFE4DAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: isDark ? const Color(0xFF34344A) : Colors.white),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 14.8 : 17,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: compact ? 1 : 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: compact ? 12.4 : 14.3,
                    fontWeight: FontWeight.w500,
                      color: textSecondary,
                  ),
                ),
                SizedBox(height: compact ? 7 : 10),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: compact ? 14 : 18, vertical: compact ? 5 : 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.inter(
                        fontSize: compact ? 13.5 : 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Container(
            width: compact ? 68 : 84,
            height: compact ? 68 : 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF5A35E5), Color(0xFF7E48F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: appColor.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 33 : 42),
          ),
        ],
      ),
    );
  }

}

class _NavItem {
  final IconData selectedIcon;
  final IconData icon;
  final String label;
  _NavItem(this.selectedIcon, this.icon, this.label);
}
