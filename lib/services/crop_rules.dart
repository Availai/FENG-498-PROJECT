import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CropRules {
  /// Yapay zeka ve API aracılığıyla sağlanan çevresel verilere dayanıklı,
  /// dinamik ürün analiz motoru. Elle yazılmış (hardcoded) tavsiye YOKTUR.
  static Future<List<Map<String, dynamic>>> getDynamicRecommendations(
    double currentTemp,
    double ph,
    double avgWeeklyTemp,
    double totalWeeklyRain, {
    double soilMoisture = 0.0,
    double soilTempC = 0.0,
  }) async {
    List<Map<String, dynamic>> fallback = [
      {
        'name': '⚠️ Bilgi Bulunamadı',
        'season': '-',
        'uygunluk': 0.0,
        'info': 'Yapay Zeka API bağlantısı sağlanamadı. Lütfen internetinizi kontrol edin.',
        'fertilizer': '-',
        'weather_impact': '-',
        'care_details': '-',
      }
    ];

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final prompt = '''
Sen Türkiye şartlarında çalışan uzman bir Ziraat Mühendisisin. "Elle yazdığım verileri sildim, doğrudan senin anlık zeka verilerini kullanıyorum."

Aşağıdaki anlık çevresel koşulları dikkatlice analiz et ve bu koşullara EN UYGUN (en yüksek verim alınabilecek) 5 adet ticari veya hobi bitkisini (sebze, meyve veya tahıl) belirle. 

ÇEVRESEL SENSÖR VERİLERİ (API'dan Gelen Gerçek Verilerdir):
- Haftalık Ort. Sıcaklık: $avgWeeklyTemp°C
- Anlık Sıcaklık: $currentTemp°C
- Toprak pH: ${ph.toStringAsFixed(1)}
- Haftalık Beklenen Yağış: $totalWeeklyRain mm
- Toprak Nem Oranı: %${(soilMoisture * 100).toStringAsFixed(1)}
- Toprak Sıcaklığı (10cm derinlik): ${soilTempC.toStringAsFixed(1)}°C

ÇIKTI KURALLARI:
Mevcut ortam değerlerini METNİN İÇİNE yedirerek ($ph pH yüksek/düşük, $avgWeeklyTemp sıcaklık iyi/kötü gibi) YALNIZCA geçerli bir JSON formatında DÜZ metin olarak yanıt ver. Kesinlikle ````json veya markdown etiketi KULLANMA. Saf array ile başlasın ve bitsin: [ { ... } ]

Toprak pH Kritik Kuralı: 
Eğer pH 5.5'ten küçükse veya 7.5'ten büyükse, "fertilizer" bölümünde "Acil: pH değerini dengelemek için Kireçleme (veya Kükürt) şarttır" gibi son derece net, pratik ve kesin bir düzeltici bilgi VERMELİSİNİZ. Bu bir zorunluluktur.

Beklenen JSON Formatı:
[
  {
    "name": "🍅 Domates (Örnek Bitki Adı + Emoji)",
    "season": "Ekim Mevsimi",
    "uygunluk": 85.0,
    "info": "Mevcut pH $ph koşullarına göre... (2-3 cümle detaylı analiz ve çevresel uyum analizi)",
    "fertilizer": "Dekara 15kg X gübresi kullanılmalı...(pH ve nem koşullarına duyarlı kireçleme veya gübreleme reçetesi. pH sorunluysa kesin ve net talimat ver.)",
    "weather_impact": "$totalWeeklyRain mm yağış mantar riski oluşturur... (Haftalık hava koşullarının bu bitkiye etkisi)",
    "care_details": "40x50 cm dikim mesafesi... vs"
  }
]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text?.trim() ?? '';
      
      // Olası markdown kalıntılarını temizle (Prompt ile yasaklasak bile AI ekleyebilir)
      if (text.startsWith('```json')) text = text.substring(7);
      if (text.startsWith('```')) text = text.substring(3);
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
      text = text.trim();

      final List<dynamic> decoded = jsonDecode(text);
      List<Map<String, dynamic>> results = decoded.map((e) {
        return {
          'name': e['name']?.toString() ?? 'Bilinmiyor',
          'season': e['season']?.toString() ?? '-',
          'uygunluk': (e['uygunluk'] as num?)?.toDouble() ?? 50.0,
          'info': e['info']?.toString() ?? '-',
          'fertilizer': e['fertilizer']?.toString() ?? '-',
          'weather_impact': e['weather_impact']?.toString() ?? '-',
          'care_details': e['care_details']?.toString() ?? '-',
        };
      }).toList();
      
      // Uygunluk skoruna göre azalan sırada sırala (en büyük en üstte)
      results.sort((a, b) => ((b['uygunluk'] as num).toDouble()).compareTo((a['uygunluk'] as num).toDouble()));
      
      return results;
    } catch (e) {
      debugPrint('Dynamic CropRules Error: $e');
      return fallback;
    }
  }
}