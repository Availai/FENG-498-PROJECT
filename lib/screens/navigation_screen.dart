import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_providers.dart';
import '../services/haptic_service.dart';
import '../widgets/glass_panel.dart';
import 'dashboard_screen.dart';
import 'growing_guide_screen.dart';
import 'my_crops_screen.dart';
import 'camera_screen.dart';
import 'plant_database_screen.dart';
import 'crop_calendar_screen.dart';
import 'map_hub_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Foreground sync'i sadece bir kez tetikle — build içinde watch etmek
    // her tab değişiminde gereksiz rebuild'e yol açıyordu.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(foregroundSyncProvider);
    });
  }

  // Ana sekmeler sade tutulur; ikincil araçlar "Daha Fazla" menüsünden açılır.
  static const List<Widget> _pages = [
    AgriDashboard(), // 0 – Özet
    MyCropsScreen(), // 1 – Tarlalar
    GrowingGuideScreen(), // 2 – Rehber
    CropCalendarScreen(), // 3 – Takvim
  ];

  void _onNavTap(int navIdx) {
    HapticService.instance.selection();
    setState(() => _currentIndex = navIdx);
  }

  // ── Daha Fazla / Hesap bottom sheet ──────────────────────────────────────

  void _showMoreSheet() {
    final user = ref.read(authRepositoryProvider).currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.mint,
                    child: Icon(
                      user?.isAnonymous == true
                          ? Icons.person_outline
                          : Icons.person,
                      color: AppColors.emeraldDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daha Fazla',
                          style: AppText.h3(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.isAnonymous == true
                              ? 'Misafir kullanıcı'
                              : (user?.displayName ??
                                  user?.email ??
                                  'Kullanıcı'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.xs(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.document_scanner_rounded,
                      color: Colors.teal.shade700, size: 20),
                ),
                title: const Text('Görüntü Analizi'),
                subtitle:
                    const Text('Bitki fotoğrafından hastalık ve tür teşhisi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.map_rounded,
                      color: Colors.green.shade700, size: 20),
                ),
                title: const Text('Harita Merkezi'),
                subtitle: const Text('Tarla poligonlarını haritada görüntüle'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MapHubScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.library_books_rounded,
                      color: Colors.purple.shade700, size: 20),
                ),
                title: const Text('Kayıtlı Veriler'),
                subtitle: const Text('Analiz geçmişi ve kayıtlar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlantDatabaseScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.logout_rounded,
                      color: Colors.red.shade700, size: 20),
                ),
                title: Text(
                  user?.isAnonymous == true
                      ? 'Çıkış / Hesap Oluştur'
                      : 'Çıkış Yap',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authRepositoryProvider).signOut();
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
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBottomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
      child: GlassPanel(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Özet',
                  isActive: _currentIndex == 0,
                  onTap: () => _onNavTap(0),
                ),
              ),
              Expanded(
                child: _NavButton(
                  icon: Icons.grass_outlined,
                  activeIcon: Icons.grass,
                  label: 'Tarlalar',
                  isActive: _currentIndex == 1,
                  onTap: () => _onNavTap(1),
                ),
              ),
              Expanded(
                child: _NavButton(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book_rounded,
                  label: 'Rehber',
                  isActive: _currentIndex == 2,
                  onTap: () => _onNavTap(2),
                ),
              ),
              Expanded(
                child: _NavButton(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month,
                  label: 'Takvim',
                  isActive: _currentIndex == 3,
                  onTap: () => _onNavTap(3),
                ),
              ),
              Expanded(
                child: _NavButton(
                  icon: Icons.more_horiz_rounded,
                  activeIcon: Icons.more_horiz_rounded,
                  label: 'Daha',
                  isActive: false,
                  onTap: _showMoreSheet,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.emerald.withValues(alpha: 0.1)
              : Colors.transparent,
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
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppColors.emerald : AppColors.textTertiary,
                letterSpacing: 0.1,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1),
              ),
            ),
            // Aktif öğe altında spring-animated gösterge noktası
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.elasticOut,
              margin: const EdgeInsets.only(top: 3),
              height: 3,
              width: isActive ? 16 : 0,
              decoration: BoxDecoration(
                color: AppColors.emerald,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
