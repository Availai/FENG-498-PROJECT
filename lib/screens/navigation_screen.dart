import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import 'dashboard_screen.dart';
import 'growing_guide_screen.dart';
import 'my_crops_screen.dart';
import 'camera_screen.dart';
import 'plant_database_screen.dart';
import 'crop_calendar_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  // Page order — camera (index 2) is exposed as FAB
  static const List<Widget> _pages = [
    AgriDashboard(),       // 0 – Özet
    MyCropsScreen(),       // 1 – Tarlalarım
    CameraScreen(),        // 2 – AI Analiz (FAB)
    CropCalendarScreen(),  // 3 – Takvim
    GrowingGuideScreen(),  // 4 – Rehber
    PlantDatabaseScreen(), // 5 – Arşiv
  ];

  // Bottom nav slots: 0=Özet, 1=Tarlalarım, [FAB gap], 2=Takvim, 3=Rehber
  // Arşiv accessible via long-press or profile menu
  static const List<int> _navToPage = [0, 1, 3, 4];

  int get _navIndex {
    if (_currentIndex == 2) return -1;
    final idx = _navToPage.indexOf(_currentIndex);
    return idx; // -1 if page 5 (Arşiv) is active
  }

  void _onNavTap(int navIdx) =>
      setState(() => _currentIndex = _navToPage[navIdx]);

  void _onFabTap() => setState(() => _currentIndex = 2);

  // ── Profile / Logout bottom sheet ────────────────────────────────────────

  void _showProfileSheet() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  user?.isAnonymous == true
                      ? Icons.person_outline
                      : Icons.person,
                  size: 36,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.isAnonymous == true
                    ? 'Misafir Kullanıcı'
                    : (user?.displayName ?? user?.email ?? 'Kullanıcı'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700),
              ),
              if (user?.email != null && user?.isAnonymous == false)
                Text(user!.email!,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 24),
              // Archive button
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.library_books_rounded,
                      color: Colors.purple.shade700, size: 20),
                ),
                title: const Text('Ortak Arşiv'),
                subtitle: const Text('Analiz geçmişi ve kayıtlar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 5);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.logout_rounded,
                      color: Colors.red.shade700, size: 20),
                ),
                title: Text(
                  user?.isAnonymous == true ? 'Çıkış / Hesap Oluştur' : 'Çıkış Yap',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildFab() {
    final isActive = _currentIndex == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: GestureDetector(
        onTap: _onFabTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isActive ? AppGradients.emeraldCard : AppGradients.forestHero,
            boxShadow: isActive ? AppShadows.emeraldGlow : AppShadows.md,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: AnimatedRotation(
            turns: isActive ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              isActive ? Icons.document_scanner : Icons.document_scanner_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), // Float above the very bottom
      child: GlassPanel(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              // Left: Özet + Tarlalarım
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
                      label: 'Tarlalar',
                      isActive: _navIndex == 1,
                      onTap: () => _onNavTap(1),
                    ),
                  ],
                ),
              ),
              // FAB gap
              const SizedBox(width: 56),
              // Right: Takvim + Rehber + Profil
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavButton(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month,
                      label: 'Takvim',
                      isActive: _navIndex == 2,
                      onTap: () => _onNavTap(2),
                    ),
                    _NavButton(
                      icon: Icons.menu_book_outlined,
                      activeIcon: Icons.menu_book,
                      label: 'Rehber',
                      isActive: _navIndex == 3,
                      onTap: () => _onNavTap(3),
                    ),
                    _NavButton(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profil',
                      isActive: false,
                      onTap: _showProfileSheet,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable nav button ────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.emerald.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.emerald : AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.emerald : AppColors.textTertiary,
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
