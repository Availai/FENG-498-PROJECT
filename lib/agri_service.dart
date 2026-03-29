import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'crop_rules.dart';

class AgriService {
  static String get _plantNetKey => dotenv.env['PLANTNET_API_KEY'] ?? '';
  static String get _imaggaKey => dotenv.env['IMAGGA_API_KEY'] ?? '';
  static String get _imaggaSecret => dotenv.env['IMAGGA_API_SECRET'] ?? '';

  static Future<Map<String, dynamic>> analyzeImage(
    File imageFile,
    double latitude,
    double longitude,
  ) async {
    try {
      if (!await imageFile.exists()) {
        return {
          'type': 'error',
          'data': {'message': 'Fotoğraf dosyası bulunamadı.'},
        };
      }

      // --- AŞAMA 1: GATEKEEPER (IMAGGA) ---
      String credentials = '$_imaggaKey:$_imaggaSecret';
      String encodedCredentials = base64Encode(utf8.encode(credentials));

      var imaggaRequest = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imagga.com/v2/tags'),
      );
      imaggaRequest.headers.addAll({
        'Authorization': 'Basic $encodedCredentials',
      });
      imaggaRequest.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final imaggaResponse = await imaggaRequest.send();
      if (imaggaResponse.statusCode != 200) {
        return {
          'type': 'error',
          'data': {'message': 'Görsel analiz servisi yanıt vermedi.'},
        };
      }

      final imaggaBody = await imaggaResponse.stream.bytesToString();
      final imaggaData = jsonDecode(imaggaBody);

      List<dynamic> tags = imaggaData['result']['tags'];
      List<String> tagNames = tags
          .take(15)
          .map((t) => t['tag']['en'].toString().toLowerCase())
          .toList();

      List<String> plantKeywords = [
        'plant',
        'flower',
        'leaf',
        'tree',
        'botany',
        'houseplant',
      ];
      List<String> fieldKeywords = [
        'field',
        'farm',
        'agriculture',
        'soil',
        'land',
        'crop',
        'dirt',
        'ground',
      ];

      bool isPlant = tagNames.any((tag) => plantKeywords.contains(tag));
      bool isField = tagNames.any((tag) => fieldKeywords.contains(tag));

      if (!isPlant && !isField) {
        return {
          "type": "error",
          "data": {
            "message":
                "Geçersiz içerik. Lütfen sadece tarımsal arazi veya bitki fotoğrafı yükleyin.",
          },
        };
      }

      // --- AŞAMA 2: ÇEVRE VE 7 GÜNLÜK HAVA DURUMU (OPEN-METEO + SOILGRIDS) ---
      double numericTemp = 20.0;
      double numericPh = 6.5;
      double avgWeeklyTemp = 20.0;
      double totalWeeklyRain = 0.0;

      try {
        final weatherKey = dotenv.env['WEATHER_API_KEY'] ?? '';
        final results = await Future.wait([
          // Anlık hava durumu (Mevcut)
          http.get(
            Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherKey&units=metric',
            ),
          ),
          // pH Verisi (Mevcut)
          http.get(
            Uri.parse(
              'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
            ),
          ),
          // YENİ: Open-Meteo 7 Günlük Tahmin (Ücretsiz, Key İstemez)
          http.get(
            Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto',
            ),
          ),
        ]);

        if (results[0].statusCode == 200) {
          numericTemp = (jsonDecode(results[0].body)['main']['temp'] as num)
              .toDouble();
        }
        if (results[1].statusCode == 200) {
          final val = jsonDecode(
            results[1].body,
          )['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
          if (val != null) numericPh = val / 10.0;
        }
        if (results[2].statusCode == 200) {
          final forecastData = jsonDecode(results[2].body)['daily'];
          List maxTemps = forecastData['temperature_2m_max'];
          List minTemps = forecastData['temperature_2m_min'];
          List rainSums = forecastData['precipitation_sum'];

          // 7 günün ortalamalarını hesapla
          double sumTemp = 0;
          for (int i = 0; i < 7; i++) {
            sumTemp += ((maxTemps[i] + minTemps[i]) / 2);
            totalWeeklyRain += rainSums[i];
          }
          avgWeeklyTemp = double.parse((sumTemp / 7).toStringAsFixed(1));
          totalWeeklyRain = double.parse(totalWeeklyRain.toStringAsFixed(1));
        }
      } catch (e) {
        return {
          'type': 'error',
          'data': {
            'message':
                'Çevresel sensörlere (Hava/Toprak) ulaşılamadı. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
          },
        };
      }

      // --- AŞAMA 3: YÖNLENDİRME ---
      // --- AŞAMA 3: YÖNLENDİRME (ROUTING) ---

      if (isPlant) {
        var plantNetReq = http.MultipartRequest(
          'POST',
          Uri.parse(
            'https://my-api.plantnet.org/v2/identify/all?api-key=$_plantNetKey',
          ),
        );
        plantNetReq.files.add(
          await http.MultipartFile.fromPath('images', imageFile.path),
        );

        final plantNetRes = await plantNetReq.send();
        final plantData = jsonDecode(await plantNetRes.stream.bytesToString());

        if (plantNetRes.statusCode == 200 &&
            plantData['results'] != null &&
            plantData['results'].isNotEmpty) {
          var bestMatch = plantData['results'][0];
          String scientificName =
              bestMatch['species']['scientificNameWithoutAuthor'];
          String familyName =
              bestMatch['species']['family']['scientificNameWithoutAuthor'];
          String commonTitle =
              bestMatch['species']['commonNames']?.isNotEmpty == true
              ? bestMatch['species']['commonNames'][0]
              : scientificName;

          // 🌟 YENİ VE HATASIZ GEMINI ENTEGRASYONU (SADECE METİN) 🌟
          String basariSansi = "% Bekleniyor";
          String konumYorumu = "Çevre verisi analiz ediliyor...";
          String nasilYetistirilir = "Bilgi getiriliyor...";
          String bakimPufNoktasi = "Bilgi getiriliyor...";
          String halkDilindekiAdi = "Bilinmiyor";
          String hastalikRiskleri = "Bilgi getiriliyor...";
          String sulamaTakvimi = "Bilgi getiriliyor...";
          String gubreOnerisi = "Bilgi getiriliyor...";
          String hasatZamani = "Bilgi getiriliyor...";
          String depolamaSaklama = "Bilgi getiriliyor...";

          try {
            // Güncel ve stabil modeli kullanıyoruz
            final model = GenerativeModel(
              model: 'gemini-2.5-flash',
              apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
            );

            // Ziraat Mühendisi Promptu (Detaylı 10 alan)
            final prompt =
                '''
Sen 20 yıllık deneyime sahip uzman bir ziraat mühendisisin.
İncelenen Bitki: $scientificName (Yaygın adı: $commonTitle, Familya: $familyName).
Anlık Konum Verileri: Haftalık Sıcaklık Ortalaması $avgWeeklyTemp°C, Anlık Sıcaklık ${numericTemp.toStringAsFixed(1)}°C, Toprak pH'ı ${numericPh.toStringAsFixed(1)}, Haftalık Toplam Yağış $totalWeeklyRain mm.

Bu verilere göre bana sadece ve sadece aşağıdaki JSON formatında cevap ver. Her alanı en az 2-3 cümleyle ayrıntılı doldur. Başka hiçbir açıklama yazma.
{
  "halk_dilindeki_adi": "Bu bitkinin Türkiye'de halk arasındaki yöresel adları nelerdir? Birden fazla varsa virgülle ayır. Yoksa 'Bilinmiyor' yaz.",
  "basari_sansi": "Mevcut sıcaklık, pH ve yağış verilerine göre bu bitkinin yüzde kaç yaşama/verim şansı var? Neden bu oranı verdin, kısaca açıkla. (Örn: %85 - Sıcaklık ideal ama pH biraz yüksek)",
  "konum_yorumu": "Mevcut sıcaklık ($avgWeeklyTemp°C) ve pH (${numericPh.toStringAsFixed(1)}) bu bitki için uygun mu? İdeal aralıkları belirt. Ne gibi spesifik riskler var? Detaylı açıkla.",
  "nasil_yetistirilir": "Bu bitkinin tohum/fide hazırlığından hasata kadar tüm yetiştirme adımlarını sırayla açıkla. Ekim derinliği, sıra arası mesafe, ışık ihtiyacı gibi detayları ver.",
  "bakim_puf_noktasi": "Sulama, gübreleme, budama ve zararlı kontrolü için en kritik püf noktaları nelerdir? Profesyonel çiftçilerin bildiği ama amatörlerin atladığı ipuçları ver.",
  "hastalik_riskleri": "Bu bölgedeki iklim koşullarına ($avgWeeklyTemp°C, $totalWeeklyRain mm yağış) göre bu bitkide görülebilecek en yaygın 3-4 hastalık ve zararlı türünü yaz. Her biri için belirtiler ve mücadele yöntemini açıkla.",
  "sulama_takvimi": "Mevcut yağış verisine ($totalWeeklyRain mm/hafta) göre ek sulama gerekli mi? Hangi sulama yöntemi (damla, yağmurlama, karık) en uygun? Günde/haftada kaç litre/dekar su verilmeli?",
  "gubre_onerisi": "Toprak pH'ı (${numericPh.toStringAsFixed(1)}) dikkate alınarak hangi gübre türleri (NPK oranı, organik/kimyasal) kullanılmalı? Dekara kaç kg dozajda ve hangi dönemlerde uygulanmalı?",
  "hasat_zamani": "Bu bitkinin ekimden hasata kadar kaç gün/hafta sürer? Olgunluk belirtileri nelerdir? En uygun hasat zamanı (sabah/akşam, hava durumu) ne zamandır?",
  "depolama_saklama": "Hasat edilen ürün nasıl saklanmalı? İdeal sıcaklık, nem oranı ve raf ömrü nedir? Dikkat edilmesi gereken depolama hataları nelerdir?"
}
''';
            final response = await model.generateContent([
              Content.text(prompt),
            ]);
            final text = response.text ?? '';

            // Dönen JSON'ı parse etme (Markdown temizliği dahil)
            String cleanJson = text
                .replaceAll(RegExp(r'```json?|```', multiLine: true), '')
                .trim();
            final aiData = jsonDecode(cleanJson);

            halkDilindekiAdi = aiData['halk_dilindeki_adi'] ?? halkDilindekiAdi;
            basariSansi = aiData['basari_sansi'] ?? basariSansi;
            konumYorumu = aiData['konum_yorumu'] ?? konumYorumu;
            nasilYetistirilir = aiData['nasil_yetistirilir'] ?? nasilYetistirilir;
            bakimPufNoktasi = aiData['bakim_puf_noktasi'] ?? bakimPufNoktasi;
            hastalikRiskleri = aiData['hastalik_riskleri'] ?? hastalikRiskleri;
            sulamaTakvimi = aiData['sulama_takvimi'] ?? sulamaTakvimi;
            gubreOnerisi = aiData['gubre_onerisi'] ?? gubreOnerisi;
            hasatZamani = aiData['hasat_zamani'] ?? hasatZamani;
            depolamaSaklama = aiData['depolama_saklama'] ?? depolamaSaklama;
          } catch (e) {
            konumYorumu =
                "Yapay zeka analizi şu an yapılamadı, ancak PlantNet teşhisi başarılı.";
          }

          return {
            "type": "plant",
            "data": {
              "title": commonTitle,
              "scientific_name": scientificName,
              "description": "Botanik Teşhis ve AI Ziraat Analizi",
              "plant_details": {
                "family": familyName,
                "halk_dilindeki_adi": halkDilindekiAdi,
                "basari_sansi": basariSansi,
                "konum_yorumu": konumYorumu,
                "nasil_yetistirilir": nasilYetistirilir,
                "bakim_puf_noktasi": bakimPufNoktasi,
                "hastalik_riskleri": hastalikRiskleri,
                "sulama_takvimi": sulamaTakvimi,
                "gubre_onerisi": gubreOnerisi,
                "hasat_zamani": hasatZamani,
                "depolama_saklama": depolamaSaklama,
              },
            },
          };
        }
      }

      // Bitki değilse Tarla raporu oluştur (YENİ PARAMETRELERLE)
      List<Map<String, dynamic>> recommendations = CropRules.getRecommendations(
        numericTemp,
        numericPh,
        avgWeeklyTemp,
        totalWeeklyRain,
      );

      return {
        "type": "field",
        "data": {
          "title": "Ayrıntılı Ziraat Raporu",
          "description":
              "pH: ${numericPh.toStringAsFixed(1)} | Haftalık Ort. Sıcaklık: $avgWeeklyTemp°C | Beklenen Yağış: $totalWeeklyRain mm",
          "crops": recommendations,
        },
      };
    } catch (e) {
      return {
        'type': 'error',
        'data': {
          'message': 'Bağlantı Hatası: Lütfen internetinizi kontrol edin.',
        },
      };
    }
  }

  // --- Tarlaya Özel Ekim Planı Üretici ---
  static Future<String> generateFieldPlan(
    String plantName,
    String fieldName,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final prompt =
          '''
Sen profesyonel bir ziraat mühendisisin. 
Kullanıcı "$plantName" bitkisini, kayıtlı olan "$fieldName" isimli tarlasına ekecek. 
Lütfen bu tarlaya özel, adım adım bir yetiştirme takvimi çıkar. 
Şu başlıkları içersin:
1. Toprak Hazırlığı
2. Ekim/Dikim Süreci
3. Sulama ve Gübreleme Takvimi
4. Hasat Beklentisi
Cevabın şık, cesaretlendirici ve akıcı bir Türkçe metin olsun. JSON KULLANMA.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Plan oluşturulamadı.';
    } catch (e) {
      return 'Bağlantı hatası: Plan şu an oluşturulamıyor.';
    }
  }

  // --- Tarla Detay Analizi (Hava + Toprak + 7 Gün + AI Yorum) ---
  static Future<Map<String, dynamic>> getFieldAnalysis(
    double latitude,
    double longitude,
    String fieldName,
    double areaDekar,
  ) async {
    double numericTemp = 0;
    double numericHumidity = 0;
    double numericWind = 0;
    double numericPh = 6.5;
    String weatherDesc = '';
    double avgWeeklyTemp = 0;
    double totalWeeklyRain = 0;
    List<Map<String, dynamic>> dailyForecast = [];

    try {
      final weatherKey = dotenv.env['WEATHER_API_KEY'] ?? '';
      final results = await Future.wait([
        http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherKey&units=metric&lang=tr',
        )),
        http.get(Uri.parse(
          'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
        )),
        http.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto',
        )),
      ]);

      // Anlık hava durumu
      if (results[0].statusCode == 200) {
        final wd = jsonDecode(results[0].body);
        numericTemp = (wd['main']['temp'] as num).toDouble();
        numericHumidity = (wd['main']['humidity'] as num).toDouble();
        numericWind = (wd['wind']?['speed'] as num?)?.toDouble() ?? 0;
        weatherDesc = wd['weather']?[0]?['description'] ?? '';
      }

      // Toprak pH
      if (results[1].statusCode == 200) {
        final val = jsonDecode(results[1].body)
            ['properties']?['layers']?[0]?['depths']?[0]?['values']?['mean'];
        if (val != null) numericPh = (val as num).toDouble() / 10.0;
      }

      // 7 günlük tahmin
      if (results[2].statusCode == 200) {
        final fd = jsonDecode(results[2].body)['daily'];
        List maxT = fd['temperature_2m_max'];
        List minT = fd['temperature_2m_min'];
        List rain = fd['precipitation_sum'];
        List dates = fd['time'];
        double sumTemp = 0;
        for (int i = 0; i < 7; i++) {
          double dayMax = (maxT[i] as num).toDouble();
          double dayMin = (minT[i] as num).toDouble();
          double dayRain = (rain[i] as num).toDouble();
          sumTemp += (dayMax + dayMin) / 2;
          totalWeeklyRain += dayRain;
          dailyForecast.add({
            'date': dates[i],
            'max': dayMax,
            'min': dayMin,
            'rain': dayRain,
          });
        }
        avgWeeklyTemp = double.parse((sumTemp / 7).toStringAsFixed(1));
        totalWeeklyRain = double.parse(totalWeeklyRain.toStringAsFixed(1));
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Çevresel verilere ulaşılamadı. İnternet bağlantınızı kontrol edin.',
      };
    }

    // Ürün önerileri
    List<Map<String, dynamic>> crops = CropRules.getRecommendations(
      numericTemp, numericPh, avgWeeklyTemp, totalWeeklyRain,
    );

    // Gemini AI haftalık yorum
    String aiWeeklyComment = '';
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );
      final prompt = '''
Sen 20 yıllık deneyime sahip uzman bir ziraat mühendisisin.
Tarla: "$fieldName" (${areaDekar.toStringAsFixed(1)} Dekar)
Konum: $latitude, $longitude
Anlık Hava: ${numericTemp.toStringAsFixed(1)}°C, $weatherDesc, Nem %${numericHumidity.toStringAsFixed(0)}, Rüzgar ${numericWind.toStringAsFixed(1)} m/s
Toprak pH: ${numericPh.toStringAsFixed(1)}
Haftalık Ort. Sıcaklık: $avgWeeklyTemp°C, Toplam Yağış: $totalWeeklyRain mm

Bu verileri kullanarak çiftçiye/hobi bahçecisine yönelik 4-5 paragraf detaylı Türkçe haftalık yorum yaz.
Şu başlıkları kullan:
🌤️ Haftalık Hava Değerlendirmesi
🌱 Bu Hafta Yapılması Gerekenler
⚠️ Dikkat Edilmesi Gereken Riskler
💡 Hobi Bahçecilerine Özel İpuçları

Cevabını düz metin olarak ver. JSON kullanma. Emoji kullanarak başlıkları renklendir.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      aiWeeklyComment = response.text ?? 'AI yorumu oluşturulamadı.';
    } catch (e) {
      aiWeeklyComment = 'AI yorumu şu an yüklenemedi. Lütfen daha sonra tekrar deneyin.';
    }

    return {
      'success': true,
      'temp': numericTemp,
      'humidity': numericHumidity,
      'wind': numericWind,
      'weather_desc': weatherDesc,
      'ph': numericPh,
      'avg_weekly_temp': avgWeeklyTemp,
      'total_weekly_rain': totalWeeklyRain,
      'daily_forecast': dailyForecast,
      'crops': crops,
      'ai_weekly_comment': aiWeeklyComment,
    };
  }
}
