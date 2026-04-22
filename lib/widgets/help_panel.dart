import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const HelpItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });
}

class HelpContent {
  final String screenTitle;
  final String screenSubtitle;
  final IconData headerIcon;
  final Color headerColor;
  final List<HelpItem> items;

  const HelpContent({
    required this.screenTitle,
    required this.screenSubtitle,
    required this.headerIcon,
    required this.headerColor,
    required this.items,
  });

  // ── Pre-built content for each main screen ─────────────────────────────────

  static const HelpContent dashboard = HelpContent(
    screenTitle: 'Özet Ekranı',
    screenSubtitle: 'Ana kontrol paneliniz — günlük tarım durumunuz burada.',
    headerIcon: Icons.dashboard_rounded,
    headerColor: Color(0xFF1B5E20),
    items: [
      HelpItem(
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Hava Durumu Kartı',
        description:
            'Bulunduğunuz konumun anlık sıcaklığı, nem oranı ve rüzgar hızını gösterir. '
            'Veriler 10 dakikada bir otomatik güncellenir. İnternet yoksa son kaydedilen değerler görünür.',
      ),
      HelpItem(
        icon: Icons.sensors_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Sensör Verileri',
        description:
            'Toprağınıza yerleştirilen sensörlerden gelen pH ve nem değerlerini gösterir. '
            '"Sensör Detayı" düğmesine basarak geçmiş verileri inceleyebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.map_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Tarla Kartları',
        description:
            'Kayıtlı tarım alanlarınızın kısa özetini gösterir. '
            'Karta tıklayarak o tarlaya ait detaylar, ekim bilgisi ve sulama planına geçebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.refresh_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Yenile Düğmesi (↻)',
        description:
            'Sağ üstteki yenile simgesine basarak hava durumu ve sensör verilerini manuel olarak güncelleyebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.book_rounded,
        iconColor: Color(0xFF8D6E63),
        title: 'Tarla Günlüğü',
        description:
            'Tarlanızdaki sulama, gübreleme gibi faaliyetleri not alabilirsiniz. '
            'Ana ekrandaki kısa yoldan veya tarla detay sayfasından ulaşabilirsiniz.',
      ),
    ],
  );

  static const HelpContent myCrops = HelpContent(
    screenTitle: 'Tarım Alanlarım',
    screenSubtitle: 'Tarlarınızı buradan kaydedin, takip edin ve yönetin.',
    headerIcon: Icons.grass_rounded,
    headerColor: Color(0xFF2E7D32),
    items: [
      HelpItem(
        icon: Icons.satellite_alt_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Yeni Alan Çiz',
        description:
            'Sağ alttaki "YENİ ALAN ÇİZ" düğmesine basın. '
            'Harita üzerinde tarlanızın köşelerini işaretleyerek alanı kaydedin. '
            'Konum izni gereklidir.',
      ),
      HelpItem(
        icon: Icons.grid_view_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Alan Kartları',
        description:
            'Her kart bir tarım alanını temsil eder. '
            'Karta tıklayarak o alanın detaylarını, ürün bilgisini ve sulama planını görebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.eco_rounded,
        iconColor: Color(0xFF8BAE8F),
        title: 'Ürün Atama',
        description:
            'Tarla detay sayfasından o alana hangi bitkiyi ekeceğinizi seçebilirsiniz. '
            '292 Türk tarım bitkisi arasından arama yapabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.view_in_ar_rounded,
        iconColor: Color(0xFF6B7280),
        title: '3D Alan Planlayıcı',
        description:
            'Tarla detayında "3D Planla" seçeneğiyle bitkilerinizi sanal olarak düzenleyebilirsiniz. '
            'Her bölgeye farklı ürün atayarak verim hesabı yapılır.',
      ),
      HelpItem(
        icon: Icons.delete_outline_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Alan Silme',
        description:
            'Tarla kartını sola kaydırarak veya detay sayfasından alanı silebilirsiniz. '
            'Bu işlem geri alınamaz; dikkatli olun.',
      ),
    ],
  );

  static const HelpContent calendar = HelpContent(
    screenTitle: 'Tarım Takvimi',
    screenSubtitle: 'Ekim, hasat ve sulama tarihlerinizi tek ekranda görün.',
    headerIcon: Icons.calendar_month_rounded,
    headerColor: Color(0xFF0288D1),
    items: [
      HelpItem(
        icon: Icons.circle,
        iconColor: Color(0xFF43A047),
        title: '🟢 Yeşil — Ekim Tarihi',
        description:
            'Tarlanıza kaydettiğiniz bitkinin ekim tarihi yeşil renkte gösterilir. '
            'O güne tıklayarak hangi tarlada ne ektiğinizi görebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.circle,
        iconColor: Color(0xFFE67E22),
        title: '🟠 Turuncu — Tahmini Hasat',
        description:
            'Bitkinin büyüme süresi baz alınarak hesaplanan tahmini hasat tarihi. '
            'Hava koşullarına göre değişebilir.',
      ),
      HelpItem(
        icon: Icons.circle,
        iconColor: Color(0xFF1976D2),
        title: '🔵 Mavi — Sulama Hatırlatıcısı',
        description:
            'Haftalık otomatik sulama hatırlatma tarihleri. '
            'Sulama planı ekranından sıklığı değiştirebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.circle,
        iconColor: Color(0xFF9C27B0),
        title: '🟣 Mor — Tarla Kayıt Tarihi',
        description:
            'O alanı sisteme ilk eklediğiniz tarih. '
            'Geçmiş faaliyetlerinizi takip etmek için kullanışlıdır.',
      ),
      HelpItem(
        icon: Icons.touch_app_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Tarihe Tıklama',
        description:
            'Takvimde herhangi bir güne tıkladığınızda o güne ait olayların listesi altta görünür. '
            'Her olayın hangi tarlaya ait olduğu belirtilmiştir.',
      ),
    ],
  );

  static const HelpContent guide = HelpContent(
    screenTitle: 'Akıllı Tarım Rehberi',
    screenSubtitle: 'Herhangi bir bitki için yetiştiriclik rehberi alın.',
    headerIcon: Icons.menu_book_rounded,
    headerColor: Color(0xFF8D6E63),
    items: [
      HelpItem(
        icon: Icons.search_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Bitki Arama',
        description:
            'Üstteki arama kutusuna bitki adını Türkçe yazın (örn. "domates", "buğday"). '
            'Ardından "Rehber Al" düğmesine basın.',
      ),
      HelpItem(
        icon: Icons.tune_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Üretim Ölçeği',
        description:
            'Hobi bahçesi, küçük aile işletmesi veya ticari üretim seçeneklerinden birini seçin. '
            'Rehber içeriği bu seçime göre uyarlanır.',
      ),
      HelpItem(
        icon: Icons.grass_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Rehber İçeriği',
        description:
            'Sonuç; ekiş zamanı, toprak hazırlığı, sulama sıklığı, haşere koruması ve '
            'hasat bilgilerini içerir. Çevrimdışı kullanım için önbelleğe alınır.',
      ),
      HelpItem(
        icon: Icons.water_drop_rounded,
        iconColor: Color(0xFF0288D1),
        title: 'Haftalık Su Çizelgesi',
        description:
            'Sayfanın altında 7 günlük hava tahmini ve önerilen sulama miktarları gösterilir. '
            'Bu veriler gerçek zamanlı meteoroloji verilerine dayanır.',
      ),
      HelpItem(
        icon: Icons.offline_bolt_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Çevrimdışı Kullanım',
        description:
            'Daha önce aranan bitkiler internet kesilse bile gösterilebilir. '
            'İlk aramayı bağlantılıyken yapmanız yeterlidir.',
      ),
    ],
  );

  static const HelpContent camera = HelpContent(
    screenTitle: 'Akıllı Asistan Kamerası',
    screenSubtitle: 'Bitkinizdeki hastalığı yapay zeka ile saniyeler içinde teşhis edin.',
    headerIcon: Icons.camera_alt_rounded,
    headerColor: Color(0xFF37474F),
    items: [
      HelpItem(
        icon: Icons.camera_alt_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Fotoğraf Çekme',
        description:
            '"Kamera Çekimi" düğmesine basarak bitkinin hasta görünen yaprağını veya gövdesini '
            'fotoğraflayın. Yakın ve net bir çekim daha iyi sonuç verir.',
      ),
      HelpItem(
        icon: Icons.photo_library_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Galeriden Seçme',
        description:
            '"Galeriden Seç" düğmesiyle telefonunuzdaki mevcut bir fotoğrafı kullanabilirsiniz. '
            'Daha önce çektiğiniz görselleri analiz etmek için uygundur.',
      ),
      HelpItem(
        icon: Icons.psychology_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Yapay Zeka Analizi',
        description:
            'Fotoğraf yüklendikten sonra "ANALİZ ET" düğmesine basın. '
            'Sistem görüntüyü birden fazla YZ modeline gönderir ve olası hastalıkları listeler.',
      ),
      HelpItem(
        icon: Icons.receipt_long_rounded,
        iconColor: Color(0xFF8D6E63),
        title: 'Analiz Sonuçları',
        description:
            'Sonuç sayfasında hastalık adı, güven oranı, tedavi önerileri ve '
            'ilaç tavsiyeleri gösterilir. Sonuçlar geçmiş analizler sekmesine kaydedilir.',
      ),
      HelpItem(
        icon: Icons.history_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Geçmiş Analizler',
        description:
            'Sayfanın alt sekmesinde önceki tüm analizlerinizi görebilirsiniz. '
            'Her analizin tarihine ve sonucuna tıklayarak detayları inceleyebilirsiniz.',
      ),
    ],
  );

  static const HelpContent fieldDetail = HelpContent(
    screenTitle: 'Tarla Detay Ekranı',
    screenSubtitle: 'Tarlanızı harita üzerinde yönetin, ürün ekleyin ve takip edin.',
    headerIcon: Icons.map_rounded,
    headerColor: Color(0xFF0D3B1A),
    items: [
      HelpItem(
        icon: Icons.radar_rounded,
        iconColor: Color(0xFF00E676),
        title: 'Tarlayı Tara',
        description:
            'Alt bardaki "Tarlayı Tara" düğmesi bitki seçiciyi açar. '
            '292 Türk bitkisi arasından seçim yapabilirsiniz; her bitki için toprak ve '
            'iklim uygunluk skoru hesaplanır. Seçtiğiniz bitki tarlaya bölge olarak eklenir.',
      ),
      HelpItem(
        icon: Icons.touch_app_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Bölgeye Tıklama',
        description:
            'Haritada daha önce eklediğiniz renkli bölgelere tıklayarak '
            'o bölgeye ait bitki adı, ekim tarihi, olgunlaşma yüzdesi gibi bilgileri görebilirsiniz. '
            'Açılan pencereden bölgeyi silebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.add_location_alt_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Bölge Çizme',
        description:
            '"Tarlayı Tara" ile bitki seçtikten sonra haritaya dokunarak köşe noktaları '
            'işaretleyebilirsiniz. En az 3 nokta işaretleyip "Tamamla" ya basın. '
            '"Geri Al" ile son noktayı silebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.stacked_line_chart_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Trendler',
        description:
            'Tarlanıza ve seçtiğiniz bitkilere göre uygunluk raporunu ve '
            'toprak-iklim analizini görüntüler. Veriler sensör ve hava durumu API\'lerine dayanır.',
      ),
      HelpItem(
        icon: Icons.event_note_rounded,
        iconColor: Color(0xFF8D6E63),
        title: 'Günlük',
        description:
            'Bu tarlaya ait sulama, gübreleme, ilaçlama gibi faaliyetleri kayıt altına alın. '
            'Geçmiş aktiviteler zaman sırasıyla listelenir.',
      ),
      HelpItem(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF9C27B0),
        title: 'Cüzdan — Masraf Takibi',
        description:
            'Bu tarlaya özel gelir ve masraf defteri. Tohum, gübre, yakıt, işçilik gibi '
            'harcamaları girdikçe toplam masraf otomatik güncellenir. '
            'Girdiğiniz her masraf, Tahmini Sezon Sonu Kârı hesabından anında düşülür — '
            'yani kârınız gerçek harcamalarınıza göre anlık hesaplanır.',
      ),
      HelpItem(
        icon: Icons.touch_app_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Bölge Silme (Dokun-Sil)',
        description:
            'Haritada birden fazla ekim bölgeniz varsa, silmek istediğiniz bölgenin üzerine '
            'doğrudan dokunun — sadece o bölge seçilir ve silme penceresi açılır. '
            'Yanlışlıkla başka bölgeyi silmezsiniz.',
      ),
      HelpItem(
        icon: Icons.checklist_rtl_rounded,
        iconColor: Color(0xFF0288D1),
        title: 'Görevler',
        description:
            'Tarla için yapılacaklar listesini ve sulama planını görüntüleyin. '
            'Yaklaşan görevler ve hatırlatıcılar burada listelenir.',
      ),
      HelpItem(
        icon: Icons.zoom_in_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Harita Kontrolleri',
        description:
            'Sol taraftaki (+) ve (−) düğmeleriyle haritayı yakınlaştırıp uzaklaştırabilirsiniz. '
            'Odak simgesine basarak haritanın tarla poligonuna otomatik sığmasını sağlayın.',
      ),
    ],
  );

  // 3D Tarla Planlayıcı — yeni alan çizme + kâr tahmini ekranı
  static const HelpContent fieldPlanner = HelpContent(
    screenTitle: '3D Tarla Yerleşimi',
    screenSubtitle: 'Yeni tarla çizin, haritayı kontrol edin ve kâr tahmininizi anlık görün.',
    headerIcon: Icons.view_in_ar_rounded,
    headerColor: Color(0xFF1B5E20),
    items: [
      HelpItem(
        icon: Icons.add_location_alt_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Köşe Noktası Ekleme',
        description:
            'Haritaya dokunarak tarlanızın köşelerini sırayla işaretleyin. '
            'En az 3 nokta gereklidir; daha fazla köşe girerek gerçek şekli daha iyi yakalayabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.undo_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Geri Al ve Temizle',
        description:
            'Sağ üstteki geri-al düğmesiyle yanlış koyduğunuz son noktayı silebilirsiniz. '
            'Süpürge simgesi ise tüm çizimi sıfırlar.',
      ),
      HelpItem(
        icon: Icons.zoom_in_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Yakınlaştır / Uzaklaştır',
        description:
            'Sağ kenardaki (+) ve (−) düğmeleriyle haritayı büyütüp küçültebilirsiniz. '
            'Yaşlı gözler için pinch-zoom yerine tek parmakla çalışan güvenli bir yol.',
      ),
      HelpItem(
        icon: Icons.center_focus_strong_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Çizime Odaklan',
        description:
            'Haritayı kaydırarak çiziminizi kaybettiyseniz, odak simgesine basarak '
            'haritayı işaretlediğiniz noktalara otomatik sığdırabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.trending_up_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Tahmini Sezon Sonu Kârı',
        description:
            'Tarla kaydedildikten sonra ekranda görünen kâr kartı, şu formülü kullanır: '
            '(Tahmini Rekolte × Birim Fiyat) − Toplam Masraf = Net Kâr. '
            'Yeşil renk kâr, kırmızı renk zarar anlamına gelir.',
      ),
      HelpItem(
        icon: Icons.receipt_long_rounded,
        iconColor: Color(0xFF9C27B0),
        title: 'Masraflar Nereden Geliyor?',
        description:
            'Toplam masraf artık sabit 1000 ₺ değil — Cüzdan (masraf defteri) ekranından '
            'bu tarla için girdiğiniz tüm harcamaların toplamıdır. '
            'Yeni bir masraf eklediğinizde kâr kartı anında güncellenir.',
      ),
      HelpItem(
        icon: Icons.science_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Rekolte Tahmini Nasıl Yapılır?',
        description:
            'Tahmini rekolte; bitki türü, dekar, haftalık su, sıcaklık stresi ve gübreleme durumu '
            'baz alınarak kural tabanlı (makine öğrenmesi içermeyen) formülle hesaplanır. '
            'Her eksiklik için belirli oranda kayıp uygulanır.',
      ),
    ],
  );

  // Pazar Yeri & Topluluk ekranı
  static const HelpContent marketplace = HelpContent(
    screenTitle: 'Pazar & Topluluk',
    screenSubtitle: 'Ürünlerinizi satın, hastalık bildirin, sorularınızı paylaşın.',
    headerIcon: Icons.storefront_rounded,
    headerColor: Color(0xFF2E7D32),
    items: [
      HelpItem(
        icon: Icons.storefront_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Pazar Yeri',
        description:
            'Hasatınıza yaklaştığınızda ürünlerinizi buradan listeleyebilirsiniz. '
            '"İlan Ver" düğmesine basarak ürün adı, miktar, fiyat ve iletişim bilgilerinizi girin. '
            'İlanınız anında yayınlanır.',
      ),
      HelpItem(
        icon: Icons.phone_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Alıcıyla İletişim',
        description:
            'Bir ürün ilanında "İletişim" düğmesine bastığınızda satıcının telefon numarası '
            'kopyalanır. Pano\'dan yapıştırarak arama yapabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.filter_list_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Kategori & Arama',
        description:
            'Üstteki kategori seçeneklerine tıklayarak tahıl, sebze, meyve vb. '
            'filtreleyebilirsiniz. Arama kutusuna ürün adı veya şehir yazarak da süzebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.bug_report_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Hastalık Bildirimi',
        description:
            'Yapay Zeka Kamerası ile tespit ettiğiniz bir hastalığı doğrudan buraya '
            'aktarabilirsiniz — kamera ekranındaki "Toplulukla Paylaş" düğmesine basın. '
            'Başlık ve açıklama otomatik doldurulur.',
      ),
      HelpItem(
        icon: Icons.help_outline_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Soru & Tavsiye',
        description:
            '"Paylaş" düğmesiyle soru gönderin. Diğer çiftçiler ve uzmanlar yorum yapabilir. '
            'Yorumları görmek için karta tıklayın ve "Devamını gör" seçeneğini kullanın.',
      ),
      HelpItem(
        icon: Icons.people_alt_rounded,
        iconColor: Color(0xFF7B1FA2),
        title: 'Topluluk Gönderileri',
        description:
            'Gönderi türünü seçin: Hastalık Bildirimi, Soru veya Bilgi Paylaşımı. '
            'Anonim paylaşım da mümkündür — adınızı boş bırakın.',
      ),
    ],
  );

  // Bölge Çizme (tarlaya bitki ekleme) — ikinci harita ekranı
  static const HelpContent plantZoneDrawing = HelpContent(
    screenTitle: 'Bitki Bölgesi Çiz',
    screenSubtitle: 'Seçtiğiniz bitki için tarla içinde ekim bölgesi çizin.',
    headerIcon: Icons.eco_rounded,
    headerColor: Color(0xFF2E7D32),
    items: [
      HelpItem(
        icon: Icons.touch_app_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Noktaları İşaretleme',
        description:
            'Haritada bitkiyi ekmek istediğiniz alanın köşelerini sırayla işaretleyin. '
            'En az 3 köşe gereklidir; noktalar otomatik olarak birleştirilir.',
      ),
      HelpItem(
        icon: Icons.zoom_in_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Yakınlaştırma Kontrolleri',
        description:
            'Sağ kenardaki (+) ve (−) düğmeleriyle haritayı yakınlaştırıp uzaklaştırabilirsiniz. '
            'Küçük bölgeler için yakın zoom daha hassas çizim sağlar.',
      ),
      HelpItem(
        icon: Icons.center_focus_strong_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Tarlaya Sığdır',
        description:
            'Odak simgesine basarak haritayı doğrudan tarla sınırlarınıza göre ortalayabilirsiniz. '
            'Yolunuzu kaybettiğinizde hızlıca geri dönmek için kullanışlıdır.',
      ),
      HelpItem(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Tamamla',
        description:
            'En az 3 nokta işaretledikten sonra "Tamamla" düğmesiyle bölgeyi kaydedin. '
            'Seçilen bitki o renge boyanarak tarlaya eklenir.',
      ),
    ],
  );
}

/// Static helper — call `HelpPanel.show(context, HelpContent.dashboard)` etc.
class HelpPanel {
  HelpPanel._();

  static void show(BuildContext context, HelpContent content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HelpSheet(content: content),
    );
  }
}

class _HelpSheet extends StatelessWidget {
  final HelpContent content;

  const _HelpSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // ── Header gradient ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [content.headerColor, content.headerColor.withValues(alpha: 0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lg,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Icon(content.headerIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            content.screenTitle,
                            style: AppText.h3Dark(context),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            content.screenSubtitle,
                            style: AppText.bodyDark(context).copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Section label ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text('NASIL KULLANILIR?',
                        style: AppText.label(context)
                            .copyWith(color: AppColors.textTertiary)),
                  ],
                ),
              ),

              // ── Scrollable items ─────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, mq.padding.bottom + 24),
                  itemCount: content.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _HelpItemCard(item: content.items[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HelpItemCard extends StatelessWidget {
  final HelpItem item;

  const _HelpItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(item.icon, color: item.iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: AppText.bodyMd(context)
                        .copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 5),
                Text(item.description,
                    style: AppText.sm(context)
                        .copyWith(color: AppColors.textSecondary, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
