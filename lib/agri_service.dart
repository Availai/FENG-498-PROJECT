import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

        if (plantNetRes.statusCode == 200) {
          final plantData = jsonDecode(
            await plantNetRes.stream.bytesToString(),
          );
          if (plantData['results'] != null && plantData['results'].isNotEmpty) {
            var bestMatch = plantData['results'][0];
            return {
              "type": "plant",
              "data": {
                "title": bestMatch['species']['commonNames']?.isNotEmpty == true
                    ? bestMatch['species']['commonNames'][0]
                    : bestMatch['species']['scientificNameWithoutAuthor'],
                "description": "PlantNet Botanik AI Analizi",
                "plant_details": {
                  "scientific_name":
                      bestMatch['species']['scientificNameWithoutAuthor'],
                  "features":
                      "Familya: ${bestMatch['species']['family']['scientificNameWithoutAuthor']}",
                  "care":
                      "Spesifik bakım bilgisi için bitki bilimsel adını inceleyin.",
                },
              },
            };
          }
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
}
