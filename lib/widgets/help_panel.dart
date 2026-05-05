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
        description: 'Kayıtlı tarım alanlarınızın kısa özetini gösterir. '
            'Karta tıklayarak o tarlaya ait detaylar, ekim bilgisi ve günlük rehbere ulaşabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.assistant_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Rehbere Git Bağlantısı',
        description:
            'Her tarla kartında uyarı sayısını gösteren "Rehber" düğmesi bulunur. '
            'Düğmeye basarak o tarlaya ait "Bugünün Rehberi" ekranına doğrudan atlarsınız.',
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
        title: 'Hızlı Aktivite Kaydı',
        description:
            'Tarla kartındaki kayıt kısa yolundan sulama, gübreleme, ilaçlama ve hasat gibi '
            'faaliyetleri anında not alın. Kaydettiğiniz her aktivite büyüme motorunu canlı olarak etkiler.',
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
        description: 'Sağ alttaki "Yeni Tarla Çiz" düğmesine basın. '
            'Harita üzerinde tarlanızın köşelerini işaretleyerek alanı kaydedin. '
            'Konum izni gereklidir.',
      ),
      HelpItem(
        icon: Icons.grid_view_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Alan Kartları',
        description: 'Her kart bir tarım alanını temsil eder. '
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
        description: 'Haftalık otomatik sulama hatırlatma tarihleri. '
            'Sulama planı ekranından sıklığı değiştirebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.circle,
        iconColor: Color(0xFF9C27B0),
        title: '🟣 Mor — Tarla Kayıt Tarihi',
        description: 'O alanı sisteme ilk eklediğiniz tarih. '
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

  static const HelpContent camera = HelpContent(
    screenTitle: 'Akıllı Asistan Kamerası',
    screenSubtitle:
        'Bitkinizdeki hastalığı yapay zeka ile saniyeler içinde teşhis edin.',
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
        description: 'Fotoğraf yüklendikten sonra "ANALİZ ET" düğmesine basın. '
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
    screenSubtitle:
        'Tarlanızı harita üzerinde yönetin, ürün ekleyin ve takip edin.',
    headerIcon: Icons.map_rounded,
    headerColor: Color(0xFF0D3B1A),
    items: [
      HelpItem(
        icon: Icons.radar_rounded,
        iconColor: Color(0xFF00E676),
        title: 'Ekle — Toplu Ekim',
        description:
            'Alt bardaki "Ekle" düğmesine dokununca bitki seçip bölge çizerek toplu ekim yaparsınız. '
            '292 Türk bitkisi arasından seçim yapabilirsiniz; her bitki için toprak ve '
            'iklim uygunluk skoru hesaplanır. Seçtiğiniz bitki tarlaya bölge olarak eklenir.',
      ),
      HelpItem(
        icon: Icons.add_location_alt_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Bölge veya Tekil Bitki',
        description:
            '"Ekle" düğmesine basılı tutunca "Bölge Çiz" ve "Tekil Bitki Ekle" seçenekleri açılır. '
            'Tekil bitkide haritada herhangi bir noktaya dokunarak 292 bitki arasından seçip o noktaya '
            'bağımsız bir bitki markeri ekleyebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.healing_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Bitki Sağlık Durumu',
        description:
            'Haritadaki herhangi bir bitki markerine dokunun. Açılan menüden "Sağlık durumunu düzenle" '
            'seçeneğiyle o bitkiyi Sağlıklı, Hasta veya Ölü olarak işaretleyebilirsiniz. '
            'Hasta bitkiler üzerinde turuncu uyarı rozeti görünür.',
      ),
      HelpItem(
        icon: Icons.playlist_add_check_rounded,
        iconColor: Color(0xFF00BCD4),
        title: 'Çoklu Bitki Seçimi',
        description:
            'Herhangi bir bitki markerine uzun basarak çoklu seçim moduna girin — ya da '
            'tek bitki menüsünden "Çoklu seçim başlat" seçin. Ardından diğer bitkilere '
            'tek tek dokunarak seçime ekleyin. Üstte beliren HUD çubuğundaki '
            '"Sağlık" düğmesiyle seçili tüm bitkilere aynı sağlık durumunu toplu atayabilir, '
            '"Sil" düğmesiyle ise hepsini birden silebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.assistant_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Günlük Rehber',
        description:
            'Üst bardaki "Rehber" düğmesi "Bugünün Rehberi" ekranını açar. '
            'Bu ekranda tarlaya özel bugünün görevleri, ekili bitkilerin gün gün planı, hava uyarıları, '
            'bitki sağlığı durumu ve uygulamalı tarım önerileri bir arada sunulur.',
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
        title: 'Kayıt — Aktivite Girişi',
        description:
            'Alt bardaki "Kayıt" düğmesiyle sulama, gübreleme, ilaçlama ve hasat gibi faaliyetleri kayıt altına alın. '
            'Her kayıt büyüme motorunu canlı olarak günceller: "Suladım" dediğinizde '
            'su açığı göstergesi ve rehber önerisi anında değişir.',
      ),
      HelpItem(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: Color(0xFF9C27B0),
        title: 'Diğer — Cüzdan ve Günlük',
        description:
            '"Diğer" menüsünden tarla günlüğüne ve bu tarlaya özel masraf defterine ulaşabilirsiniz. Tohum, gübre, yakıt, işçilik gibi '
            'harcamaları girdikçe toplam masraf otomatik güncellenir. '
            'Tahmini Sezon Sonu Kârı masraf defteri ekranında hesaplanır.',
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

  // 3D Tarla Planlayıcı — yeni alan çizme ekranı
  static const HelpContent fieldPlanner = HelpContent(
    screenTitle: '3D Tarla Yerleşimi',
    screenSubtitle: 'Yeni tarla çizin ve haritayı kontrol edin.',
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
        icon: Icons.save_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Tarlayı Kaydet',
        description:
            'En az 3 köşe noktası işaretledikten sonra "Kaydet" düğmesiyle tarlayı sisteme ekleyin. '
            'Kaydedilen tarla otomatik olarak takviminize işlenir ve tarla detay ekranından '
            'yönetilmeye hazır hale gelir.',
      ),
      HelpItem(
        icon: Icons.receipt_long_rounded,
        iconColor: Color(0xFF9C27B0),
        title: 'Tahmini Kâr Nerede Görünür?',
        description:
            'Kâr tahmini artık bu ekranda değil — Tarla Detay ekranından Cüzdan (masraf defteri) '
            'bölümüne girdiğinizde hesaplanır. '
            'Toplam masraf girişine göre Net Kâr = Rekolte Geliri − Toplam Masraf formülüyle gösterilir.',
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
    screenSubtitle:
        'Ürünlerinizi satın, hastalık bildirin, sorularınızı paylaşın.',
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

  // Bugünün Rehberi ekranı — GuideEngine çıktısı
  static const HelpContent dailyGuide = HelpContent(
    screenTitle: 'Bugünün Rehberi',
    screenSubtitle:
        'Tarlaya özel günlük görevler, uyarılar ve anlık durum göstergesi.',
    headerIcon: Icons.assistant_rounded,
    headerColor: Color(0xFF1A3D2B),
    items: [
      HelpItem(
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Uyarı Bannerları',
        description:
            'Ekranın üstünde kritik çevre uyarıları gösterilir: don riski, aşırı sıcak, '
            'yağmur beklentisi, aşırı sulama ve ilaç bekleme süresi (REI). '
            'Don ve aşırı yağmur kritik (kırmızı), diğerleri uyarı (sarı) ya da bilgi (mavi) olarak işaretlenir.',
      ),
      HelpItem(
        icon: Icons.today_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'BUGÜN — Acil Görevler',
        description:
            'En fazla 3 acil görev kart olarak gösterilir: sulama, gübreleme, ilaçlama veya hasat. '
            '"Yapıldı" düğmesine bastığınızda aktivite kaydedilir ve kart anında kaybolur. '
            'Yağmur beklentisi ≥8mm ise sulama görevi otomatik "ertele" uyarısına dönüşür.',
      ),
      HelpItem(
        icon: Icons.date_range_rounded,
        iconColor: Color(0xFF0288D1),
        title: 'GÜN GÜN REHBER',
        description:
            'Ekili her bitki için bugünden geriye 3, ileriye 10 günlük pencere gösterilir. '
            'Kartta bugünün evresi, açık işler, su açığı ve yağış etkisi görünür; '
            '"Tam Günlük Rehber" bağlantısı bitki detayına götürür.',
      ),
      HelpItem(
        icon: Icons.monitor_heart_rounded,
        iconColor: Color(0xFF7B1FA2),
        title: 'DURUM Göstergesi',
        description:
            'Bitkinin anlık sağlığını tek bakışta görmek için dört gösterge: '
            'Su açığı (mm), Azot stresi (%), Potasyum stresi (%) ve Hastalık baskısı. '
            'Altında Verim Çarpanı yer alır — 1.0 = tam verim, düşükse eksik faktör var demektir.',
      ),
      HelpItem(
        icon: Icons.lightbulb_rounded,
        iconColor: Color(0xFFF9A825),
        title: 'BİLMENİZ GEREKENLER — Öneriler',
        description:
            'Bitki türü, büyüme evresi ve hava koşullarına göre otomatik oluşturulan '
            'pratik bilgiler: örneğin "Domates 28°C üstünde pollen ölümü yaşar" veya '
            '"Çiçeklenme evresinde su açığı meyve dökülmesine neden olur." '
            'Kapatılan öneri 7 gün boyunca tekrar gösterilmez.',
      ),
      HelpItem(
        icon: Icons.refresh_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Canlı Güncelleme',
        description:
            '"Yapıldı" düğmesine bastıktan sonra rehber 1-2 saniye içinde yeniden hesaplanır — '
            'manuel yenileme gerekmez. Hava tahmini de 10 dakikada bir otomatik güncellenir.',
      ),
      HelpItem(
        icon: Icons.agriculture_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Pestisit Bekleme Süresi (REI)',
        description:
            'İlaçlama kaydettikten sonra kullandığınız ilaca göre tarlaya yeniden giriş süresi '
            '(REI) banner olarak gösterilir. Süre dolmadan tarlaya girmeyin; '
            'banner süresi saatlik olarak geri sayar.',
      ),
      HelpItem(
        icon: Icons.coronavirus_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'HASTALIK REHBERİ Bölümü',
        description:
            'Tarladaki bir bitkide hastalık işaretlediğinizde bu bölüm açılır. '
            'Hastalık adı, aciliyet düzeyi ve TAGEM, Tarım Bakanlığı ile '
            'bku.tarim.gov.tr kaynaklı önerilen kimyasal mücadele listesi gösterilir. '
            'Aynı hastalıktan birden çok bitki etkilendiyse "X bitki" rozeti görünür.',
      ),
      HelpItem(
        icon: Icons.verified_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Sorun Çözüldü Bildirimi',
        description:
            'Bir hastalık için "İlaçladım" aktivitesi kaydedildiğinde sistem '
            'kullandığınız ilacın etken maddesini önerilen tedavi listesiyle eşleştirir. '
            'Doğru ilaç son 14 gün içinde uygulandıysa kart yeşile döner ve '
            '"Sorun çözüldü" rozeti belirir. Yanlış ilaç ise kart aktif kalır.',
      ),
    ],
  );

  // ── Tarla Durumu ──────────────────────────────────────────────────────────
  static const HelpContent fieldStatus = HelpContent(
    screenTitle: 'Tarla Durumu',
    screenSubtitle:
        'Tüm tarlalarınızın anlık çalışma durumunu tek ekranda görün.',
    headerIcon: Icons.crop_square_rounded,
    headerColor: Color(0xFF1565C0),
    items: [
      HelpItem(
        icon: Icons.list_alt_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Tarla Kartları',
        description:
            'Her tarla için o günkü sulama, gübreleme ve ilaçlama durumu gösterilir. '
            'Bir sonraki işleme kaç gün kaldığı ve tahmini miktar da listelenir.',
      ),
      HelpItem(
        icon: Icons.assistant_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Bugünün Rehberi\'ne Git',
        description:
            'Her tarla kartındaki "Rehber" düğmesine basarak o tarlaya özel '
            '"Bugünün Rehberi" ekranına geçin. Detaylı görevler ve hava uyarıları orada görünür.',
      ),
      HelpItem(
        icon: Icons.book_rounded,
        iconColor: Color(0xFF8D6E63),
        title: 'Günlüğe Git',
        description:
            '"Günlük" bağlantısına basarak ilgili tarlanın tüm aktivite geçmişine '
            'kronolojik sırayla ulaşabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.refresh_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Canlı Güncelleme',
        description:
            'Herhangi bir tarlaya aktivite kaydedildiğinde bu liste otomatik olarak tazelenir. '
            'Manuel yenileme gerekmez.',
      ),
    ],
  );

  // ── ÇKS Maliyet Defteri ───────────────────────────────────────────────────
  static const HelpContent costLedger = HelpContent(
    screenTitle: 'ÇKS Cüzdan — Maliyet Defteri',
    screenSubtitle: 'Tarla masraflarınızı kaydedin, kâr/zarar hesabı yapın.',
    headerIcon: Icons.account_balance_wallet_rounded,
    headerColor: Color(0xFF6A1B9A),
    items: [
      HelpItem(
        icon: Icons.add_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Masraf Ekle',
        description:
            'Sağ alttaki "+" düğmesine basın. Kategori olarak tohum, gübre, '
            'mazot, ilaç veya diğer masraflardan birini seçin; '
            'miktarı ve tutarı girin. Her kayıt hangi tarlaya ait olduğuyla birlikte saklanır.',
      ),
      HelpItem(
        icon: Icons.local_gas_station_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Güncel Mazot Fiyatı',
        description:
            'EPDK veritabanından çekilen güncel mazot fiyatı otomatik olarak görünür. '
            'Litre bazında masraf girildiğinde toplam TL otomatik hesaplanır.',
      ),
      HelpItem(
        icon: Icons.trending_up_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Kâr / Zarar Tahmini',
        description:
            'Ekranın üstündeki özet alanda toplam masraf, tahmini rekolte geliri '
            've Net Kâr = Gelir − Masraf formülüyle hesaplanan sonuç gösterilir.',
      ),
      HelpItem(
        icon: Icons.picture_as_pdf_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'PDF Raporu',
        description:
            'Sağ üstteki indirme simgesine basarak sezon sonu masraf raporunuzu '
            'PDF olarak dışa aktarabilirsiniz. ÇKS başvurularında kullanabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.delete_outline_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Masraf Silme',
        description: 'Bir masraf satırına uzun basın ya da sola kaydırın. '
            'Silinen kayıt geri alınamaz; dikkatli olun.',
      ),
    ],
  );

  // ── Tarlam Günlüğü ────────────────────────────────────────────────────────
  static const HelpContent farmJournal = HelpContent(
    screenTitle: 'Tarlam Günlüğü',
    screenSubtitle: 'Tüm tarlaların kronolojik aktivite akışını görüntüleyin.',
    headerIcon: Icons.menu_book_rounded,
    headerColor: Color(0xFF4E342E),
    items: [
      HelpItem(
        icon: Icons.history_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Aktivite Akışı',
        description: 'Sulama, gübreleme, ilaçlama ve hasat gibi tüm kayıtlar '
            'Bugün / Dün / Bu Hafta / Bu Ay / Daha Eski gruplarıyla listelenir.',
      ),
      HelpItem(
        icon: Icons.filter_list_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Tarla & Tür Filtresi',
        description:
            'Üstteki filtre çubuğundan belirli bir tarlayı veya aktivite türünü seçerek '
            'listeyi daraltabilirsiniz. Birden fazla filtre aynı anda uygulanabilir.',
      ),
      HelpItem(
        icon: Icons.water_drop_rounded,
        iconColor: Color(0xFF0288D1),
        title: 'Kayıt Detayı',
        description:
            'Herhangi bir aktivite satırına dokunarak miktar, birim, not '
            've hangi ürüne ait olduğu gibi detayları görebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.delete_outline_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Kayıt Silme',
        description: 'Bir kaydı sola kaydırarak silebilirsiniz. '
            'Silme işlemi büyüme motorunu geriye dönük etkiler; emin olmadan silmeyin.',
      ),
    ],
  );

  // ── Hasat Oracle ──────────────────────────────────────────────────────────
  static const HelpContent harvestOracle = HelpContent(
    screenTitle: 'Hasat Oracle',
    screenSubtitle: 'Hava tahminine göre optimal hasat penceresi hesaplanır.',
    headerIcon: Icons.grain_rounded,
    headerColor: Color(0xFFE65100),
    items: [
      HelpItem(
        icon: Icons.wb_sunny_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Hasat Penceresi',
        description:
            'Önümüzdeki 7 günün hava tahminine göre yağmursuz ve uygun sıcaklıktaki '
            'günler otomatik belirlenir. Yeşil kutular ideal hasat günlerini gösterir.',
      ),
      HelpItem(
        icon: Icons.warning_amber_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Hava Uyarıları',
        description:
            'Şiddetli yağmur, aşırı sıcak veya rüzgar gibi hasadı olumsuz etkileyen '
            'durumlar kırmızı uyarı olarak listelenir. Bu günlerde hasatı ertelemeniz önerilir.',
      ),
      HelpItem(
        icon: Icons.eco_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Çeşit Seçimi',
        description: 'Ekranın üstünden ürün çeşidi seçin. '
            'Seçilen çeşidin nem ve sıcaklık toleransına göre hasat skoru hesaplanır.',
      ),
      HelpItem(
        icon: Icons.refresh_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Yenile',
        description:
            'Sağ üstteki yenile simgesine basarak hava tahminini güncelleyebilirsiniz. '
            'İnternet yoksa son kaydedilen tahmin gösterilir.',
      ),
    ],
  );

  // ── Toprak Analizi ────────────────────────────────────────────────────────
  static const HelpContent soilAnalysis = HelpContent(
    screenTitle: 'Toprak Analizi',
    screenSubtitle: 'Tarlanızın toprak yapısını ve NPK ihtiyacını öğrenin.',
    headerIcon: Icons.landscape_rounded,
    headerColor: Color(0xFF1B5E20),
    items: [
      HelpItem(
        icon: Icons.science_rounded,
        iconColor: Color(0xFF43A047),
        title: 'NPK & pH Değerleri',
        description:
            'SoilGrids uydu verilerinden hesaplanan Azot (N), Fosfor (P), Potasyum (K) '
            've toprak pH\'ı gösterilir. Değerler 0-30 cm derinliği temsil eder.',
      ),
      HelpItem(
        icon: Icons.tune_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Hedef pH Ayarı',
        description: 'Kaydırıcı ile hedef pH değerini girin. '
            'Kireçleme veya kükürt miktarı otomatik hesaplanarak ekranda gösterilir.',
      ),
      HelpItem(
        icon: Icons.calendar_today_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Dönemsel Gübreleme Takvimi',
        description:
            'Seçilen bitki için ekim öncesi, gelişme dönemi ve hasat öncesi olmak üzere '
            'üç dönemlik gübreleme miktarları ve zamanları listelenir.',
      ),
      HelpItem(
        icon: Icons.offline_bolt_rounded,
        iconColor: Color(0xFF8D6E63),
        title: 'Çevrimdışı Fallback',
        description:
            'İnternet yoksa bölgesel istatistiklerden türetilen tahmini değerler gösterilir. '
            'Ekranın üstünde "tahmini veri" uyarısı görünür.',
      ),
    ],
  );

  // ── Anadolu Tohum DB ──────────────────────────────────────────────────────
  static const HelpContent seedSelector = HelpContent(
    screenTitle: 'Anadolu Tohum Veritabanı',
    screenSubtitle: 'Bölgenize uygun çeşidi seçin, büyüme simülasyonu yapın.',
    headerIcon: Icons.spa_rounded,
    headerColor: Color(0xFF33691E),
    items: [
      HelpItem(
        icon: Icons.search_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Çeşit Tarama',
        description: 'Ürün adını seçin, ardından bölgenizi belirtin. '
            'O bölgede onaylı tescilli çeşitler verim ve olgunlaşma süresine göre listelenir.',
      ),
      HelpItem(
        icon: Icons.bar_chart_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Büyüme Simülasyonu',
        description:
            '"Simülasyon" sekmesine geçin. Bölge iklimi ve seçili çeşidin parametrelerine göre '
            'tahmini büyüme eğrisi, kritik tarihler ve rekolte tahmini hesaplanır.',
      ),
      HelpItem(
        icon: Icons.compare_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Çeşit Karşılaştırma',
        description:
            'İki farklı çeşidi seçerek yan yana karşılaştırabilirsiniz. '
            'Verim, hastalık direnci ve olgunlaşma süresi fark tablosuyla gösterilir.',
      ),
      HelpItem(
        icon: Icons.agriculture_rounded,
        iconColor: Color(0xFF2E7D32),
        title: 'Hasat Oracle\'a Git',
        description: 'Çeşit seçildikten sonra "Hasat Penceresi" düğmesiyle '
            'Hasat Oracle ekranına geçebilirsiniz — optimal hasat günleri orada hesaplanır.',
      ),
    ],
  );

  // ── Harita Merkezi ────────────────────────────────────────────────────────
  static const HelpContent mapHub = HelpContent(
    screenTitle: 'Harita Merkezi',
    screenSubtitle: 'Kayıtlı tüm tarlalarınızı harita üzerinde görün.',
    headerIcon: Icons.map_rounded,
    headerColor: Color(0xFF1565C0),
    items: [
      HelpItem(
        icon: Icons.crop_free_rounded,
        iconColor: Color(0xFF43A047),
        title: 'Tarla Poligonları',
        description:
            'Her kayıtlı tarla, çizdiğiniz sınır noktalarına göre haritada renkli '
            'alan olarak gösterilir. Poligona dokunarak tarla adını ve alanını görebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.info_outline_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'İstatistik Çubuğu',
        description:
            'Ekranın üstündeki çubuk toplam kayıtlı tarla sayısını ve haritada '
            'görüntülenebilen (koordinatlı) tarla sayısını gösterir.',
      ),
      HelpItem(
        icon: Icons.zoom_in_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Yakınlaştırma',
        description:
            'Haritada iki parmakla yakınlaştırıp uzaklaştırabilirsiniz. '
            'Harita çevrimiçiyken daha yüksek çözünürlükte yüklenip, çevrimdışıyken '
            'önbellekten gösterilir.',
      ),
      HelpItem(
        icon: Icons.add_location_alt_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Yeni Tarla Ekle',
        description:
            'Tarla kaydı buradan değil, "Tarım Alanlarım" sekmesindeki '
            '"YENİ ALAN ÇİZ" düğmesiyle yapılır. Bu ekran yalnızca görüntüleme amaçlıdır.',
      ),
    ],
  );

  // ── Uydu & Hava ───────────────────────────────────────────────────────────
  static const HelpContent satelliteWeather = HelpContent(
    screenTitle: 'Uydu & Hava Durumu',
    screenSubtitle: 'Tarlaya özgü uydu verisi ve detaylı hava analizi.',
    headerIcon: Icons.satellite_alt_rounded,
    headerColor: Color(0xFF0D1321),
    items: [
      HelpItem(
        icon: Icons.thermostat_rounded,
        iconColor: Color(0xFFE67E22),
        title: 'Sıcaklık & Nem',
        description:
            'Tarla konumuna özel anlık sıcaklık, nem oranı, hissedilen sıcaklık '
            've çiğlenme noktası gösterilir. Veriler meteoroloji API\'sinden alınır.',
      ),
      HelpItem(
        icon: Icons.water_drop_rounded,
        iconColor: Color(0xFF0288D1),
        title: 'Yağış Tahmini',
        description:
            'Önümüzdeki günler için yağış miktarı ve olasılığı gösterilir. '
            'Bu bilgiyi sulama planlamanızda kullanabilirsiniz.',
      ),
      HelpItem(
        icon: Icons.satellite_alt_rounded,
        iconColor: Color(0xFF4FC3F7),
        title: 'Uydu Görüntüsü',
        description:
            'Tarlanızın NDVI (bitki örtüsü indeksi) veya gerçek renk uydu görüntüsü '
            'mevcut olduğunda gösterilir. Renk skalası ekranın altında açıklanmıştır.',
      ),
      HelpItem(
        icon: Icons.refresh_rounded,
        iconColor: Color(0xFF6B7280),
        title: 'Güncelleme',
        description:
            'Sağ üstteki yenile simgesine basarak verileri yenileyebilirsiniz. '
            'Eski veriler "güncelleme tarihi" bilgisiyle birlikte gösterilir.',
      ),
    ],
  );

  // ── Kayıtlı Verilerim ─────────────────────────────────────────────────────
  static const HelpContent plantDatabase = HelpContent(
    screenTitle: 'Kayıtlı Verilerim',
    screenSubtitle: 'YZ analiz geçmişiniz ve hızlı çevre ölçümleriniz burada.',
    headerIcon: Icons.storage_rounded,
    headerColor: Color(0xFF37474F),
    items: [
      HelpItem(
        icon: Icons.psychology_rounded,
        iconColor: Color(0xFF43A047),
        title: 'AI Görüntü Analizleri',
        description:
            'Kamera ekranından yaptığınız tüm hastalık teşhisleri bu sekmede listelenir. '
            'Her analiz için tarih, bitki adı, teşhis ve güven oranı kaydedilmiştir. '
            'Bir analize dokunarak detayları tekrar görebilirsiniz.',
      ),
      HelpItem(
        icon: Icons.history_rounded,
        iconColor: Color(0xFF1976D2),
        title: 'Hızlı Çevre Geçmişi',
        description:
            '"Hızlı Çevre Geçmişi" sekmesinde anlık sıcaklık, nem ve toprak '
            'ölçümlerinizin kronolojik kaydı tutulur.',
      ),
      HelpItem(
        icon: Icons.delete_outline_rounded,
        iconColor: Color(0xFFD32F2F),
        title: 'Kayıt Silme',
        description: 'Listeden bir analizi sola kaydırarak silebilirsiniz. '
            'Silinen analiz bir daha gösterilmez.',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      content.headerColor,
                      content.headerColor.withValues(alpha: 0.75)
                    ],
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
                      child: Icon(content.headerIcon,
                          color: Colors.white, size: 28),
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
                            style: AppText.bodyDark(context)
                                .copyWith(fontSize: 13),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  padding:
                      EdgeInsets.fromLTRB(16, 0, 16, mq.padding.bottom + 24),
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
                    style: AppText.sm(context).copyWith(
                        color: AppColors.textSecondary, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
