/// Pazar Yeri & Topluluk Ekranı
///
/// İki sekme:
///   • Pazar Yeri — hasat yaklaşan ürünleri sat, taze ilanları keşfet.
///   • Topluluk  — hastalık raporla, soru sor, tavsiye paylaş.
///
/// Veriler Hive box'larında tutulur (çevrimdışı öncelikli).
/// Backend sync yapılabilir; şimdilik local-only + seed verilerle demo çalışır.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/help_panel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GİRİŞ PARAMETRELERİ — Kamera ekranından otomatik doldurma için
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceArgs {
  /// Kameradan gelen hastalık adı — Topluluk post formu önceden doldurulur.
  final String? preFillDiseaseName;
  final String? preFillCropName;

  const MarketplaceArgs({this.preFillDiseaseName, this.preFillCropName});
}

// ─────────────────────────────────────────────────────────────────────────────
// ANA EKRAN
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceScreen extends StatefulWidget {
  final MarketplaceArgs? args;
  const MarketplaceScreen({super.key, this.args});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _listingsBoxName = 'market_listings';
  static const _postsBoxName = 'community_posts';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      // Kameradan hastalık bilgisi geldiyse Topluluk sekmesini aç
      initialIndex: widget.args?.preFillDiseaseName != null ? 1 : 0,
    );
    _ensureBoxesOpen();
  }

  Future<void> _ensureBoxesOpen() async {
    if (!Hive.isBoxOpen(_listingsBoxName)) {
      await Hive.openBox(_listingsBoxName);
    }
    if (!Hive.isBoxOpen(_postsBoxName)) {
      await Hive.openBox(_postsBoxName);
    }
    _seedIfEmpty();
    // Kameradan gelen data varsa post formunu aç
    if (widget.args?.preFillDiseaseName != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreatePostSheet(
          preFillDisease: widget.args!.preFillDiseaseName,
          preFillCrop: widget.args!.preFillCropName,
        );
      });
    }
  }

  void _seedIfEmpty() {
    final lBox = Hive.box(_listingsBoxName);
    final pBox = Hive.box(_postsBoxName);
    if (lBox.isEmpty) _seedListings(lBox);
    if (pBox.isEmpty) _seedPosts(pBox);
  }

  void _seedListings(Box box) {
    final now = DateTime.now();
    final seeds = [
      {
        'id': 'seed_l1',
        'crop_name': 'Buğday',
        'category': 'tahil',
        'quantity_kg': 2500.0,
        'price_per_kg': 8.5,
        'city': 'Konya',
        'contact': '0532 111 22 33',
        'seller_name': 'Ahmet Yılmaz',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'is_mine': false,
        'notes': 'Ekmeklik buğday, sertifikalı. Depodan teslim mümkün.',
      },
      {
        'id': 'seed_l2',
        'crop_name': 'Domates',
        'category': 'sebze',
        'quantity_kg': 800.0,
        'price_per_kg': 12.0,
        'city': 'Antalya',
        'contact': '0555 444 55 66',
        'seller_name': 'Fatma Kaya',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'is_mine': false,
        'notes': 'Salkım domates, tam olgun. Toptan tercih edilir.',
      },
      {
        'id': 'seed_l3',
        'crop_name': 'Mısır',
        'category': 'tahil',
        'quantity_kg': 5000.0,
        'price_per_kg': 6.2,
        'city': 'Çukurova',
        'contact': '0546 333 77 88',
        'seller_name': 'Mehmet Demir',
        'created_at': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'is_mine': false,
        'notes': 'Silajlık mısır. Kamyon ile nakliye mümkün.',
      },
      {
        'id': 'seed_l4',
        'crop_name': 'Ayçiçeği',
        'category': 'yaglitohumlar',
        'quantity_kg': 1200.0,
        'price_per_kg': 22.0,
        'city': 'Edirne',
        'contact': '0507 222 11 99',
        'seller_name': 'İbrahim Arslan',
        'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
        'is_mine': false,
        'notes': null,
      },
    ];
    for (final s in seeds) {
      box.add(s);
    }
  }

  void _seedPosts(Box box) {
    final now = DateTime.now();
    final seeds = [
      {
        'id': 'seed_p1',
        'type': 'disease',
        'title': 'Domateslerimde yaprak kıvırma hastalığı görüldü',
        'body':
            'Seranın doğu bölümündeki domateslerde yapraklar yukarı doğru kıvrılmaya başladı, '
                'rengi sararmış. YZ analizi "Tomato Yellow Leaf Curl Virus" dedi. '
                'Beyazsinekle yayılıyor — herkese dikkat tavsiyesi veriyorum.',
        'crop_name': 'Domates',
        'disease_name': 'Tomato Yellow Leaf Curl Virus (TYLCV)',
        'city': 'Mersin',
        'author_name': 'Hüseyin Bey',
        'created_at':
            now.subtract(const Duration(hours: 3)).toIso8601String(),
        'is_mine': false,
        'likes': 14,
        'comments': [
          {
            'author': 'Ayşe Hanım',
            'text': 'Bizim tarlada da var! İmidakloprid ile beyazsinekleri kontrol altına aldık.',
            'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
          },
          {
            'author': 'Ziraat Uzmanı Ahmet',
            'text':
                'Hastalıklı bitkileri hemen söküp imha edin. Yayılımını erken durdurmak kritik.',
            'created_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
          },
        ],
      },
      {
        'id': 'seed_p2',
        'type': 'question',
        'title': 'Buğdayda kök çürüklüğüne karşı ne yapılır?',
        'body':
            'Tarlanın birkaç yerinde buğday sapları dipten sararıp devrilmeye başladı. '
                'Toprak analizi düzgün ama yağışlar çok yoğundu bu yıl. Deneyimi olan var mı?',
        'crop_name': 'Buğday',
        'disease_name': null,
        'city': 'Konya',
        'author_name': 'Mustafa Abi',
        'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'is_mine': false,
        'likes': 7,
        'comments': [
          {
            'author': 'Tarla Danışmanı Selim',
            'text':
                'Fusarium kök çürüklüğü gibi görünüyor. Trifloxystrobin içeren bir fungisit deneyin. '
                    'Drene probleminiz de varsa sürümü derinleştirin.',
            'created_at': now.subtract(const Duration(hours: 20)).toIso8601String(),
          },
        ],
      },
      {
        'id': 'seed_p3',
        'type': 'info',
        'title': 'Bu yıl Orta Anadolu\'da mısır verimi %15 düştü',
        'body':
            'Temmuz-Ağustos aylarındaki aşırı sıcaklık dalgası bölgemizde mısır verimini olumsuz etkiledi. '
                'Komşu illerde de benzer durum var. Gelecek yıl için erken olgunlaşan çeşitler tercih edilebilir.',
        'crop_name': 'Mısır',
        'disease_name': null,
        'city': 'Ankara',
        'author_name': 'Ziraat Odası',
        'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
        'is_mine': false,
        'likes': 31,
        'comments': [],
      },
    ];
    for (final s in seeds) {
      box.add(s);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Help menu ─────────────────────────────────────────────────────────────

  void _showHelp() {
    HelpPanel.show(context, HelpContent.marketplace);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.bg,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: AppRadius.sm,
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.emeraldDark, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Pazar & Topluluk',
                        style: AppText.h3(context)
                            .copyWith(color: AppColors.textPrimary)),
                    Text('İlan ver · hastalık paylaş · soru sor',
                        style: AppText.sm(context)
                            .copyWith(color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline_rounded,
                    color: AppColors.textTertiary),
                tooltip: 'Yardım',
                onPressed: _showHelp,
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              labelStyle: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle:
                  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              labelColor: AppColors.emeraldDark,
              unselectedLabelColor: AppColors.textTertiary,
              indicatorColor: AppColors.emerald,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.storefront_rounded, size: 20),
                  text: 'Pazar Yeri',
                ),
                Tab(
                  icon: Icon(Icons.people_alt_rounded, size: 20),
                  text: 'Topluluk',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _ListingsTab(boxName: _listingsBoxName, onAdd: _showAddListingSheet),
            _CommunityTab(
              boxName: _postsBoxName,
              onAdd: (disease, crop) =>
                  _showCreatePostSheet(preFillDisease: disease, preFillCrop: crop),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabCtrl,
      builder: (_, __) {
        final isMarket = _tabCtrl.index == 0;
        return FloatingActionButton.extended(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: Icon(isMarket ? Icons.add_box_rounded : Icons.edit_note_rounded),
          label: Text(
            isMarket ? 'İlan Ver' : 'Paylaş',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          onPressed: isMarket
              ? _showAddListingSheet
              : () => _showCreatePostSheet(),
        );
      },
    );
  }

  // ── Listing sheet ─────────────────────────────────────────────────────────

  void _showAddListingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddListingSheet(boxName: _listingsBoxName),
    );
  }

  // ── Community post sheet ──────────────────────────────────────────────────

  void _showCreatePostSheet({String? preFillDisease, String? preFillCrop}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(
        boxName: _postsBoxName,
        preFillDisease: preFillDisease,
        preFillCrop: preFillCrop,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAZAR YERİ SEKMESİ
// ─────────────────────────────────────────────────────────────────────────────

class _ListingsTab extends StatefulWidget {
  final String boxName;
  final VoidCallback onAdd;
  const _ListingsTab({required this.boxName, required this.onAdd});

  @override
  State<_ListingsTab> createState() => _ListingsTabState();
}

class _ListingsTabState extends State<_ListingsTab> {
  String _query = '';
  String _activeCategory = 'tumu';

  static const _categories = [
    ('tumu', 'Tümü', Icons.apps_rounded),
    ('tahil', 'Tahıl', Icons.grass_rounded),
    ('sebze', 'Sebze', Icons.eco_rounded),
    ('meyve', 'Meyve', Icons.apple_rounded),
    ('baklagil', 'Baklagil', Icons.circle_rounded),
    ('yaglitohumlar', 'Yağlı Tohumlar', Icons.spa_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen(widget.boxName)) {
      return const Center(child: CircularProgressIndicator());
    }
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box(widget.boxName).listenable(),
      builder: (_, box, __) {
        final all = List.generate(box.length, (i) {
          final raw = box.getAt(i);
          return raw is Map ? Map<String, dynamic>.from(raw) : null;
        }).whereType<Map<String, dynamic>>().toList().reversed.toList();

        final filtered = all.where((e) {
          final catOk = _activeCategory == 'tumu' ||
              (e['category']?.toString() ?? 'tumu') == _activeCategory;
          final qOk = _query.isEmpty ||
              (e['crop_name']?.toString() ?? '')
                  .toLowerCase()
                  .contains(_query.toLowerCase()) ||
              (e['city']?.toString() ?? '')
                  .toLowerCase()
                  .contains(_query.toLowerCase());
          return catOk && qOk;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildCategoryRow()),
            filtered.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _ListingCard(listing: filtered[i], boxName: widget.boxName),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Ürün veya şehir ara...',
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: AppRadius.md,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.md,
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.md,
            borderSide: const BorderSide(color: AppColors.emerald, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, icon) = _categories[i];
          final isActive = _activeCategory == key;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.emerald : AppColors.surface,
                borderRadius: AppRadius.xl,
                border: Border.all(
                    color: isActive ? AppColors.emerald : AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 15,
                      color: isActive ? Colors.white : AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined,
              size: 64, color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Bu kategoride ilan yok.',
              style: AppText.bodyMd(context)
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Text('İlk ilanı siz verin!',
              style: AppText.sm(context).copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Listing Card ──────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final String boxName;
  const _ListingCard({required this.listing, required this.boxName});

  static Color _catColor(String? c) {
    switch (c) {
      case 'tahil':
        return const Color(0xFFE67E22);
      case 'sebze':
        return AppColors.emerald;
      case 'meyve':
        return const Color(0xFFE91E63);
      case 'baklagil':
        return const Color(0xFF8D6E63);
      case 'yaglitohumlar':
        return const Color(0xFFF9A825);
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor(listing['category']?.toString());
    final isMine = listing['is_mine'] == true;
    final qty = (listing['quantity_kg'] as num?)?.toDouble() ?? 0;
    final price = (listing['price_per_kg'] as num?)?.toDouble() ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(
            color: isMine
                ? AppColors.emerald.withValues(alpha: 0.5)
                : AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Text(
                    listing['crop_name']?.toString() ?? 'Ürün',
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                ),
                const SizedBox(width: 8),
                if (isMine)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Text('Benim İlanım',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldDark)),
                  ),
                const Spacer(),
                Text(
                  _formatDate(listing['created_at']?.toString()),
                  style: AppText.sm(context)
                      .copyWith(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fiyat & Miktar
            Row(
              children: [
                _infoBox(
                  context: context,
                  icon: Icons.scale_rounded,
                  label: 'Miktar',
                  value: '${_formatNum(qty)} kg',
                  color: AppColors.info,
                ),
                const SizedBox(width: 10),
                _infoBox(
                  context: context,
                  icon: Icons.attach_money_rounded,
                  label: 'Fiyat',
                  value: '${price.toStringAsFixed(2)} ₺/kg',
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 10),
                _infoBox(
                  context: context,
                  icon: Icons.location_on_rounded,
                  label: 'Konum',
                  value: listing['city']?.toString() ?? '-',
                  color: AppColors.soil,
                ),
              ],
            ),

            if (listing['notes'] != null &&
                (listing['notes'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                listing['notes'].toString(),
                style: AppText.sm(context).copyWith(height: 1.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(listing['seller_name']?.toString() ?? 'Satıcı',
                    style: AppText.sm(context)),
                const Spacer(),
                // İletişim butonu
                GestureDetector(
                  onTap: () => _copyContact(context, listing['contact']?.toString()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        Text('İletişim',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: AppRadius.sm,
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ]),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  void _copyContact(BuildContext context, String? contact) {
    if (contact == null || contact.isEmpty) return;
    Clipboard.setData(ClipboardData(text: contact));
    AppToast.show(context,
        message: 'Telefon numarası kopyalandı: $contact',
        type: ToastType.success);
  }

  String _formatNum(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)} ton';
    return v.toStringAsFixed(0);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} sa önce';
      return '${diff.inDays} gün önce';
    } catch (_) {
      return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPLULUK SEKMESİ
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityTab extends StatefulWidget {
  final String boxName;
  final void Function(String? disease, String? crop) onAdd;
  const _CommunityTab({required this.boxName, required this.onAdd});

  @override
  State<_CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<_CommunityTab> {
  String _activeFilter = 'tumu';

  static const _filters = [
    ('tumu', 'Tümü'),
    ('disease', 'Hastalık'),
    ('question', 'Soru'),
    ('info', 'Bilgi'),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen(widget.boxName)) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box(widget.boxName).listenable(),
      builder: (_, box, __) {
        final all = List.generate(box.length, (i) {
          final raw = box.getAt(i);
          return raw is Map ? Map<String, dynamic>.from(raw) : null;
        }).whereType<Map<String, dynamic>>().toList().reversed.toList();

        final filtered = _activeFilter == 'tumu'
            ? all
            : all.where((e) => e['type'] == _activeFilter).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildFilterRow()),
            filtered.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _PostCard(
                        post: filtered[i],
                        boxName: widget.boxName,
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: _filters.map((f) {
          final (key, label) = f;
          final isActive = _activeFilter == key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeFilter = key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.emerald : AppColors.surface,
                  borderRadius: AppRadius.xl,
                  border: Border.all(
                      color: isActive ? AppColors.emerald : AppColors.border),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 64, color: AppColors.textTertiary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Henüz gönderi yok.',
              style: AppText.bodyMd(context)
                  .copyWith(color: AppColors.textTertiary)),
          const SizedBox(height: 6),
          Text('İlk paylaşımı siz yapın!',
              style: AppText.sm(context).copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

// ── Post Card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String boxName;
  const _PostCard({required this.post, required this.boxName});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _expanded = false;
  bool _liked = false;

  static _TypeMeta _meta(String? type) {
    switch (type) {
      case 'disease':
        return _TypeMeta(Icons.bug_report_rounded, const Color(0xFFD32F2F),
            const Color(0xFFFFEBEE), 'Hastalık');
      case 'question':
        return _TypeMeta(Icons.help_outline_rounded, const Color(0xFF1976D2),
            const Color(0xFFE3F2FD), 'Soru');
      default:
        return _TypeMeta(Icons.info_outline_rounded, const Color(0xFF7B1FA2),
            const Color(0xFFF3E5F5), 'Bilgi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _meta(widget.post['type']?.toString());
    final likes = (widget.post['likes'] as num?)?.toInt() ?? 0;
    final comments =
        (widget.post['comments'] as List?)?.cast<Map>().toList() ?? [];
    final isMine = widget.post['is_mine'] == true;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(
            color: isMine
                ? AppColors.emerald.withValues(alpha: 0.4)
                : AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: m.bgColor,
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(m.icon, color: m.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: m.bgColor,
                              borderRadius: AppRadius.xs,
                            ),
                            child: Text(m.label,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: m.color)),
                          ),
                          const SizedBox(width: 6),
                          if (widget.post['crop_name'] != null)
                            Text(widget.post['crop_name'].toString(),
                                style: AppText.sm(context)
                                    .copyWith(color: AppColors.emeraldDark)),
                          const Spacer(),
                          Text(
                            _formatDate(
                                widget.post['created_at']?.toString()),
                            style: AppText.sm(context).copyWith(
                                color: AppColors.textTertiary, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.post['title']?.toString() ?? '',
                        style: AppText.bodyMd(context)
                            .copyWith(fontWeight: FontWeight.w700, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body (collapsible) ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Text(
              widget.post['body']?.toString() ?? '',
              maxLines: _expanded ? null : 3,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: AppText.sm(context).copyWith(height: 1.6),
            ),
          ),
          if (!_expanded)
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Text('Devamını gör...',
                    style: AppText.sm(context)
                        .copyWith(color: AppColors.emerald, fontWeight: FontWeight.w700)),
              ),
            ),

          // ── Comments (expandable) ──────────────────────────────────────
          if (_expanded && comments.isNotEmpty) ...[
            const Divider(height: 20, indent: 14, endIndent: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Yorumlar',
                  style: AppText.label(context)
                      .copyWith(color: AppColors.textTertiary)),
            ),
            const SizedBox(height: 6),
            ...comments.map((c) => _CommentRow(comment: c)),
          ],

          // ── Footer ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                Icon(Icons.person_rounded,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(widget.post['author_name']?.toString() ?? 'Anonim',
                    style: AppText.sm(context)),
                const SizedBox(width: 8),
                Icon(Icons.location_on_rounded,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 3),
                Text(widget.post['city']?.toString() ?? '',
                    style: AppText.sm(context)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Row(
                    children: [
                      Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                        color: _liked ? AppColors.error : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${likes + (_liked ? 1 : 0)}',
                        style: AppText.sm(context).copyWith(
                            color: _liked
                                ? AppColors.error
                                : AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    children: [
                      Icon(
                        _expanded
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text('${comments.length}',
                          style: AppText.sm(context)
                              .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} sa önce';
      return '${diff.inDays} gün önce';
    } catch (_) {
      return '';
    }
  }
}

class _CommentRow extends StatelessWidget {
  final Map comment;
  const _CommentRow({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.mint,
            child: Text(
              (comment['author']?.toString() ?? 'A').substring(0, 1),
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldDark),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: AppRadius.sm,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment['author']?.toString() ?? '',
                      style: AppText.sm(context)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(comment['text']?.toString() ?? '',
                      style: AppText.sm(context).copyWith(height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeMeta {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  const _TypeMeta(this.icon, this.color, this.bgColor, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// İLAN VERME SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AddListingSheet extends StatefulWidget {
  final String boxName;
  const _AddListingSheet({required this.boxName});

  @override
  State<_AddListingSheet> createState() => _AddListingSheetState();
}

class _AddListingSheetState extends State<_AddListingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cropCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = 'tahil';
  bool _saving = false;

  static const _cats = [
    ('tahil', 'Tahıl'),
    ('sebze', 'Sebze'),
    ('meyve', 'Meyve'),
    ('baklagil', 'Baklagil'),
    ('yaglitohumlar', 'Yağlı Tohumlar'),
  ];

  @override
  void dispose() {
    for (final c in [
      _cropCtrl,
      _qtyCtrl,
      _priceCtrl,
      _cityCtrl,
      _contactCtrl,
      _nameCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final box = Hive.box(widget.boxName);
    await box.add({
      'id': 'listing_${DateTime.now().millisecondsSinceEpoch}',
      'crop_name': _cropCtrl.text.trim(),
      'category': _category,
      'quantity_kg': double.tryParse(_qtyCtrl.text) ?? 0,
      'price_per_kg': double.tryParse(_priceCtrl.text) ?? 0,
      'city': _cityCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
      'seller_name': _nameCtrl.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
      'is_mine': true,
      'notes': _notesCtrl.text.trim(),
    });
    if (!mounted) return;
    Navigator.pop(context);
    AppToast.show(context,
        message: 'İlanınız yayına alındı!', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, mq.viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: sc,
            children: [
              _SheetHandle(),
              const SizedBox(height: 4),
              _SheetTitle(
                  icon: Icons.add_box_rounded,
                  title: 'Yeni Ürün İlanı',
                  subtitle: 'Hasatınızı alıcılarla buluşturun'),
              const SizedBox(height: 20),

              // Kategori
              Text('Kategori',
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _cats.map((c) {
                  final isActive = _category == c.$1;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c.$1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.emerald : AppColors.surface,
                        borderRadius: AppRadius.xl,
                        border: Border.all(
                            color: isActive
                                ? AppColors.emerald
                                : AppColors.border),
                      ),
                      child: Text(c.$2,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _FormField(ctrl: _cropCtrl, label: 'Ürün Adı', hint: 'örn. Buğday, Domates'),
              _FormField(
                  ctrl: _qtyCtrl,
                  label: 'Miktar (kg)',
                  hint: '2500',
                  keyboardType: TextInputType.number),
              _FormField(
                  ctrl: _priceCtrl,
                  label: 'Birim Fiyat (₺/kg)',
                  hint: '8.50',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true)),
              _FormField(ctrl: _cityCtrl, label: 'İl / İlçe', hint: 'Konya'),
              _FormField(
                  ctrl: _contactCtrl,
                  label: 'İletişim Numarası',
                  hint: '05XX XXX XX XX',
                  keyboardType: TextInputType.phone),
              _FormField(ctrl: _nameCtrl, label: 'Adınız / İşletme Adı', hint: 'Ahmet Bey'),
              _FormField(
                  ctrl: _notesCtrl,
                  label: 'Notlar (isteğe bağlı)',
                  hint: 'Teslimat koşulları, kalite bilgisi...',
                  required: false,
                  maxLines: 3),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Yayımlanıyor...' : 'İlanı Yayımla',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOPLULUK GÖNDERI SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  final String boxName;
  final String? preFillDisease;
  final String? preFillCrop;
  const _CreatePostSheet({
    required this.boxName,
    this.preFillDisease,
    this.preFillCrop,
  });

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _cropCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _type = 'question';
  bool _saving = false;

  static const _types = [
    ('disease', 'Hastalık Bildirimi', Icons.bug_report_rounded, Color(0xFFD32F2F)),
    ('question', 'Soru', Icons.help_outline_rounded, Color(0xFF1976D2)),
    ('info', 'Bilgi Paylaşımı', Icons.info_outline_rounded, Color(0xFF7B1FA2)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preFillDisease != null) {
      _type = 'disease';
      _titleCtrl.text =
          '${widget.preFillDisease} tespit ettim — dikkat!';
      _bodyCtrl.text =
          'Yapay zeka analizinde "${widget.preFillDisease}" tespit edildi. '
          'Belirtileri: ';
    }
    if (widget.preFillCrop != null) {
      _cropCtrl.text = widget.preFillCrop!;
    }
  }

  @override
  void dispose() {
    for (final c in [_titleCtrl, _bodyCtrl, _cropCtrl, _cityCtrl, _nameCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final box = Hive.box(widget.boxName);
    await box.add({
      'id': 'post_${DateTime.now().millisecondsSinceEpoch}',
      'type': _type,
      'title': _titleCtrl.text.trim(),
      'body': _bodyCtrl.text.trim(),
      'crop_name': _cropCtrl.text.trim().isEmpty ? null : _cropCtrl.text.trim(),
      'disease_name': _type == 'disease' ? widget.preFillDisease : null,
      'city': _cityCtrl.text.trim(),
      'author_name': _nameCtrl.text.trim().isEmpty ? 'Anonim' : _nameCtrl.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
      'is_mine': true,
      'likes': 0,
      'comments': <Map>[],
    });
    if (!mounted) return;
    Navigator.pop(context);
    AppToast.show(context,
        message: 'Gönderiniz toplulukla paylaşıldı!', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, mq.viewInsets.bottom + 20),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: sc,
            children: [
              _SheetHandle(),
              const SizedBox(height: 4),
              _SheetTitle(
                  icon: Icons.edit_note_rounded,
                  title: 'Toplulukla Paylaş',
                  subtitle: 'Hastalık bildir, soru sor veya bilgi aktar'),
              const SizedBox(height: 20),

              // Gönderi türü
              Text('Gönderi Türü',
                  style: AppText.bodyMd(context)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...(_types.map((t) {
                final (key, label, icon, color) = t;
                final isActive = _type == key;
                return GestureDetector(
                  onTap: () => setState(() => _type = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.08)
                          : AppColors.surface,
                      borderRadius: AppRadius.md,
                      border: Border.all(
                          color: isActive ? color : AppColors.border,
                          width: isActive ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 10),
                        Text(label,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isActive ? color : AppColors.textSecondary)),
                        const Spacer(),
                        if (isActive)
                          Icon(Icons.check_circle_rounded,
                              color: color, size: 18),
                      ],
                    ),
                  ),
                );
              })),
              const SizedBox(height: 12),

              _FormField(ctrl: _titleCtrl, label: 'Başlık', hint: 'Kısa ve açıklayıcı bir başlık yazın'),
              _FormField(
                  ctrl: _bodyCtrl,
                  label: 'Açıklama',
                  hint: 'Durumu detaylı anlat — diğer çiftçiler sana yardımcı olabilir...',
                  maxLines: 5),
              _FormField(
                  ctrl: _cropCtrl,
                  label: 'Bitki / Ürün (isteğe bağlı)',
                  hint: 'Domates, Buğday...',
                  required: false),
              _FormField(ctrl: _cityCtrl, label: 'İl / İlçe', hint: 'Ankara'),
              _FormField(
                  ctrl: _nameCtrl,
                  label: 'Adınız (isteğe bağlı)',
                  hint: 'Anonim kalabilirsiniz',
                  required: false),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(_saving ? 'Paylaşılıyor...' : 'Paylaş',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORTAK KÜÇÜK WIDGET'LAR
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SheetTitle(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: AppRadius.sm,
            ),
            child: Icon(icon, color: AppColors.emeraldDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3(context)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppText.sm(context)
                        .copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int maxLines;
  final bool required;

  const _FormField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.sm(context)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: required
                ? (v) => (v == null || v.trim().isEmpty) ? '$label boş bırakılamaz' : null
                : null,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide:
                      const BorderSide(color: AppColors.emerald, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: AppRadius.sm,
                  borderSide:
                      const BorderSide(color: AppColors.error, width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

