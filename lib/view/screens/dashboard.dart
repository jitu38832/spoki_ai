import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spokiai/view/screens/chatlist.dart';
import 'package:spokiai/view/screens/storyhistory.dart';
import 'package:spokiai/view/utils/colors.dart';
import 'home.dart';

class DashboardScreen extends StatefulWidget {
  final int? initialTabIndex;
  const DashboardScreen({super.key, this.initialTabIndex = 0});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
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
      extendBody: true,
      backgroundColor: surfaceBg,
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
              color: const Color(0xFFF4F4F8),
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
}

class _NavItem {
  final IconData selectedIcon;
  final IconData icon;
  final String label;
  _NavItem(this.selectedIcon, this.icon, this.label);
}
