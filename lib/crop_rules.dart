// lib/crop_rules.dart

class CropRules {
  /// Haftalık hava durumu, anlık sıcaklık ve pH verilerine göre devasa tarım raporu
  static List<Map<String, dynamic>> getRecommendations(
    double currentTemp,
    double ph,
    double avgWeeklyTemp,
    double totalWeeklyRain,
  ) {
    List<Map<String, dynamic>> crops = [];

    // Kural 1: Ilıman, Hafif Asidik ve Yağışlı (Örn: Domates, Salatalık)
    if (avgWeeklyTemp >= 18 && avgWeeklyTemp <= 30 && ph >= 5.5 && ph <= 7.0) {
      crops.add({
        'name': 'Sırık Domates / Salatalık',
        'season': 'İlkbahar - Erken Yaz',
        'info':
            'Önümüzdeki 7 günün sıcaklık ortalaması ($avgWeeklyTemp°C) Solanaceae ailesi için mükemmel bir büyüme penceresi sunuyor.',
        'fertilizer':
            'Taban gübresi olarak dekara 25-30 kg 15-15-15 (Çinko katkılı) kompoze gübre. Çiçeklenme döneminde Potasyum Nitrat takviyesi şart.',
        'weather_impact': totalWeeklyRain > 20
            ? 'Dikkat: Haftalık yağış beklentisi yüksek ($totalWeeklyRain mm). Fungal (mantar) hastalıklara karşı koruyucu bakır sülfat uygulaması gerekebilir.'
            : 'Haftalık yağış düşük ($totalWeeklyRain mm). Damla sulama sistemini haftada en az 3 gün çalıştırmalısınız.',
        'care_details':
            'Fideler dikildikten sonra can suyu mutlaka verilmeli. Boğaz doldurma işlemi 15 gün sonra yapılmalıdır.',
      });
    }

    // Kural 2: Serin İklim, Dayanıklı Ürünler (Örn: Buğday, Arpa, Patates)
    if (avgWeeklyTemp >= 10 && avgWeeklyTemp <= 22 && ph >= 5.0 && ph <= 7.5) {
      crops.add({
        'name': 'Patates / Kök Sebzeler',
        'season': 'Sonbahar - Erken İlkbahar',
        'info':
            'Serin haftalık periyot ($avgWeeklyTemp°C) yumru gelişimi için idealdir. Toprak yapısı köklerin rahat şişmesine uygundur.',
        'fertilizer':
            'Gelişim için dekara 40 kg Amonyum Sülfat (%21 N) veya Üre (%46 N) parçalar halinde verilmelidir.',
        'weather_impact': totalWeeklyRain > 15
            ? 'Toprak nemi yeterli görünüyor. Aşırı sulamadan kaçının, kök çürüklüğü riski var.'
            : 'Yağış yetersiz. Yumru bağlama döneminde toprağı kesinlikle kuru bırakmayın.',
        'care_details':
            'Ekim derinliği 15-20 cm olmalıdır. Yabancı ot kontrolü ilk çıkışta mekanik olarak yapılmalı.',
      });
    }

    // Kural 3: Sıcak ve Kurak (Örn: Mısır, Pamuk, Ayçiçeği)
    if (avgWeeklyTemp >= 25 && avgWeeklyTemp <= 40 && ph >= 6.5 && ph <= 8.0) {
      crops.add({
        'name': 'Ayçiçeği / Yağlık Mısır',
        'season': 'Yaz',
        'info':
            'Önümüzdeki hafta beklenen yüksek sıcaklıklar ($avgWeeklyTemp°C) fotosentez ve yağ sentezi için ideal.',
        'fertilizer':
            'Ekimle beraber dekara 20 kg 20-20-0 kompoze gübre. Boy 40-50 cm olunca Üre takviyesi yapılmalı.',
        'weather_impact': totalWeeklyRain < 10
            ? 'Kritik kuraklık uyarısı! Sıcaklık yüksek, yağış yok. Acilen sulama programı oluşturulmalı.'
            : 'Haftalık yağış mısırın tepe püskülü çıkarma dönemindeki su stresini azaltacaktır.',
        'care_details':
            'Mısırda boğaz doldurma işlemi azotlu gübreleme ile birlikte yapılmalıdır.',
      });
    }

    // Kural 4: Hiçbir kurala uymayan zorlu araziler (Fallback)
    if (crops.isEmpty) {
      crops.add({
        'name': 'Fiğ / Yem Bezelyesi (Örtü Bitkisi)',
        'season': 'Her Mevsim',
        'info':
            'Mevcut pH ($ph) veya beklenen haftalık sıcaklık ($avgWeeklyTemp°C) ticari sebze/meyve için riskli. Toprağı ıslah etmek gerekir.',
        'fertilizer':
            'Toprağa organik madde kazandırmak için dekara 2-3 ton yanmış hayvan gübresi veya leonardit (Hümik asit) uygulanmalı.',
        'weather_impact':
            'Yağış beklentisi: $totalWeeklyRain mm. Bu koşullarda toprak dinlendirilmelidir.',
        'care_details':
            'Toprağın pH değerini dengelemek için tarım kireci (asidikse) veya kükürt (alkaliyse) uygulaması yapılmalıdır.',
      });
    }

    return crops;
  }
}
