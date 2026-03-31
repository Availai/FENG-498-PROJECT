import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'growing_guide_screen.dart';
import 'my_crops_screen.dart';
import 'camera_screen.dart';
import 'plant_database_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Camera (index 2) is FAB — pages at 0,1,3,4 map to nav indices 0,1,2,3
  static const List<Widget> _pages = [
    AgriDashboard(),      // 0 – Özet
    MyCropsScreen(),      // 1 – Tarlalarım
    CameraScreen(),       // 2 – AI Analiz (FAB)
    GrowingGuideScreen(), // 3 – Rehber ← FIXED
    PlantDatabaseScreen(),// 4 – Arşiv
  ];

  // Nav-bar indices: 0=Özet, 1=Tarlalarım, [FAB], 2=Rehber, 3=Arşiv
  // These map to page indices:
  static const List<int> _navToPage = [0, 1, 3, 4];

  int get _navIndex {
    if (_currentIndex == 2) return -1; // FAB active
    return _navToPage.indexOf(_currentIndex);
  }

  void _onNavTap(int navIdx) {
    setState(() => _currentIndex = _navToPage[navIdx]);
  }

  void _onFabTap() {
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildFab() {
    final isActive = _currentIndex == 2;
    return GestureDetector(
      onTap: _onFabTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [const Color(0xFF00C853), const Color(0xFF1B5E20)]
                : [const Color(0xFF43A047), const Color(0xFF1B5E20)],
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFF00C853) : Colors.green)
                  .withValues(alpha: isActive ? 0.6 : 0.4),
              blurRadius: isActive ? 20 : 12,
              spreadRadius: isActive ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedRotation(
          turns: isActive ? 0.125 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            isActive ? Icons.camera_alt : Icons.camera_alt_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10,
      color: Colors.white,
      elevation: 16,
      shadowColor: Colors.black38,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            // Left side: Özet + Tarlalarım
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Özet',
                    isActive: _navIndex == 0,
                    onTap: () => _onNavTap(0),
                  ),
                  _NavButton(
                    icon: Icons.grass_outlined,
                    activeIcon: Icons.grass,
                    label: 'Tarlalarım',
                    isActive: _navIndex == 1,
                    onTap: () => _onNavTap(1),
                  ),
                ],
              ),
            ),
            // FAB gap
            const SizedBox(width: 80),
            // Right side: Rehber + Arşiv
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavButton(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    label: 'Rehber',
                    isActive: _navIndex == 2,
                    onTap: () => _onNavTap(2),
                  ),
                  _NavButton(
                    icon: Icons.library_books_outlined,
                    activeIcon: Icons.library_books,
                    label: 'Arşiv',
                    isActive: _navIndex == 3,
                    onTap: () => _onNavTap(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.shade50
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.green.shade700 : Colors.grey.shade500,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
