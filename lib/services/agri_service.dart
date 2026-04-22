import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'crop_rules.dart';
import 'rule_engine.dart';
import 'offline_encyclopedia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plant_cache_service.dart';
import '../utils/image_compressor.dart';

class _PlantNetResult {
  final bool ok;
  final Map<String, dynamic>? data;
  final String errorLabel;

  const _PlantNetResult._(this.ok, this.data, this.errorLabel);

  factory _PlantNetResult.ok(Map<String, dynamic> data) =>
      _PlantNetResult._(true, data, '');

  factory _PlantNetResult.fail(String label) =>
      _PlantNetResult._(false, null, label);
}

class _DiseaseResult {
  /// `true` => Gemini görüntüyü başarıyla değerlendirdi (hasta veya sağlıklı).
  /// `false` => API çağrısı veya parse başarısız; sonuç güvenilir değil.
  final bool analyzed;
  final bool present;
  final String name;
  final int confidence;
  final String severity;
  final String symptoms;
  final String treatment;
  final String failureReason;

  const _DiseaseResult({
    required this.analyzed,
    required this.present,
    this.name = '',
    this.confidence = 0,
    this.severity = '',
    this.symptoms = '',
    this.treatment = '',
    this.failureReason = '',
  });

  factory _DiseaseResult.unknown(String reason) =>
      _DiseaseResult(analyzed: false, present: false, failureReason: reason);
}

class AgriService {
  static String get _plantNetKey => dotenv.env['PLANTNET_API_KEY'] ?? '';
  static String get _imaggaKey => dotenv.env['IMAGGA_API_KEY'] ?? '';
  static String get _imaggaSecret => dotenv.env['IMAGGA_API_SECRET'] ?? '';
  static String get _perenualKey => dotenv.env['PERENUAL_API_KEY'] ?? '';
  static String get _agroKey => dotenv.env['AGROMONITORING_API_KEY'] ?? '';
  static String get _geminiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ═══════════════════════════════════════════════════
  // ANA ANALİZ FONKSİYONU
  // ═══════════════════════════════════════════════════
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

      List<String> tagNames = [];
      bool isPlant = false;
      bool isField = false;

      if (imaggaResponse.statusCode == 200) {
        final imaggaBody = await imaggaResponse.stream.bytesToString();
        final imaggaData = jsonDecode(imaggaBody);

        List<dynamic> tags = imaggaData['result']['tags'];
        tagNames = tags
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
          'vegetation',
          'garden',
          'herb',
          'seedling',
          'fruit',
          'vegetable',
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
          'rural',
          'pasture',
          'meadow',
          'countryside',
          'terrain',
          'earth',
        ];

        isPlant = tagNames.any((tag) => plantKeywords.contains(tag));
        isField = tagNames.any((tag) => fieldKeywords.contains(tag));
      }

      bool isUnrelated = !isPlant && !isField;

      // --- AŞAMA 2: ÇEVRE VERİLERİ (her API ayrı ayrı — biri patlasa diğerleri çalışır) ---
      double numericTemp = 20.0;
      double numericPh = 6.5;
      double avgWeeklyTemp = 20.0;
      double totalWeeklyRain = 0.0;
      double numericHumidity = 50.0;
      double soilMoisture = 0.0;
      double soilTempC = 15.0;

      // Çevre verileri paralel olarak çekiliyor (toplam süre max(8,10,8,agro) sn)
      await Future.wait([
        // 1) Anlık Hava (Open-Meteo — ücretsiz, key gerektirmez)
        () async {
          try {
            final wRes = await http
                .get(Uri.parse(
                  'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m&timezone=auto',
                ))
                .timeout(const Duration(seconds: 8));
            if (wRes.statusCode == 200) {
              final cur = jsonDecode(wRes.body)['current'];
              numericTemp = (cur['temperature_2m'] as num?)?.toDouble() ?? numericTemp;
              numericHumidity = (cur['relative_humidity_2m'] as num?)?.toDouble() ?? numericHumidity;
            }
          } catch (_) {}
        }(),
        // 2) Toprak pH (SoilGrids — yavaş olabilir, 10sn timeout)
        () async {
          try {
            final phRes = await http
                .get(Uri.parse(
                  'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
                ))
                .timeout(const Duration(seconds: 10));
            if (phRes.statusCode == 200) {
              final val = jsonDecode(phRes.body)['properties']?['layers']?[0]
                  ?['depths']?[0]?['values']?['mean'];
              if (val != null) numericPh = (val as num).toDouble() / 10.0;
            }
          } catch (_) {}
        }(),
        // 3) 7 Günlük Tahmin (Open-Meteo — ücretsiz, hızlı)
        () async {
          try {
            final fRes = await http
                .get(Uri.parse(
                  'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto',
                ))
                .timeout(const Duration(seconds: 8));
            if (fRes.statusCode == 200) {
              final fd = jsonDecode(fRes.body)['daily'];
              List maxT = fd['temperature_2m_max'];
              List minT = fd['temperature_2m_min'];
              List rain = fd['precipitation_sum'];
              double sumT = 0;
              for (int i = 0; i < 7; i++) {
                sumT += ((maxT[i] as num) + (minT[i] as num)) / 2;
                totalWeeklyRain += (rain[i] as num).toDouble();
              }
              avgWeeklyTemp = double.parse((sumT / 7).toStringAsFixed(1));
              totalWeeklyRain =
                  double.parse(totalWeeklyRain.toStringAsFixed(1));
            }
          } catch (_) {}
        }(),
        // 4) Agromonitoring toprak nem/sıcaklık (isteğe bağlı, başarısız olabilir)
        () async {
          try {
            final agroData = await _getAgroSoilData(latitude, longitude);
            if (agroData != null) {
              soilMoisture = agroData['moisture'] ?? 0.0;
              soilTempC = agroData['soil_temp_c'] ?? 15.0;
            }
          } catch (_) {}
        }(),
      ]);

      // --- AŞAMA 3: YÖNLENDİRME ---

      if (isUnrelated) {
        // ═══ SENARYO C: İLGİSİZ FOTOĞRAF — Rule Engine Bölgesel Rapor ═══
        final report = RuleEngine.generateEnvironmentalReport(
          temp: numericTemp,
          humidity: numericHumidity,
          weeklyRain: totalWeeklyRain,
          ph: numericPh,
          soilMoisture: soilMoisture,
          soilTempC: soilTempC,
          month: DateTime.now().month,
        );
        return {
          "type": "plant",
          "data": {
            "title": "Bölgesel Çevre Raporu",
            "description":
                "Fotoğraf tarımsal bir içerik değil gibi görünüyor (Etiketler: ${tagNames.take(3).join(', ')}). $report",
          }
        };
      } else if (isPlant) {
        // ═══ SENARYO A: BİTKİ ═══
        //
        // Mimari: PlantNet (tür tespiti) + Gemini (görsel hastalık tespiti)
        // AYNI ANDA başlatılır. Gemini, PlantNet'in başarısına bağlı DEĞİLDİR.
        // Hasta bitki PlantNet'i yanıltsa bile hastalık tespiti çalışır.

        // 3A-0: PlantNet WebP kabul etmiyor — JPEG'e çevir.
        final jpegFile = await ImageCompressor.compressToJpeg(imageFile);

        // 3A-1: PlantNet + Gemini hastalık tespiti PARALEL başlat.
        //   Gemini ilk turda sadece görsel analiz yapar (tür adı olmadan).
        //   PlantNet başarılı olursa tür adıyla ikinci tur gerekmiyor çünkü
        //   görsel belirtiler zaten tespit edildi.
        final firstRound = await Future.wait([
          _callPlantNet(jpegFile),
          _callGeminiDiseaseCheck(jpegFile, '', ''),
        ]);
        final plantNetResult = firstRound[0] as _PlantNetResult;
        _DiseaseResult disease = firstRound[1] as _DiseaseResult;

        // 3A-2: PlantNet başarılı mı?
        final bool plantIdentified = plantNetResult.ok &&
            plantNetResult.data?['results'] != null &&
            (plantNetResult.data!['results'] as List).isNotEmpty;

        if (plantIdentified) {
          final plantData = plantNetResult.data!;
          final bestMatch = plantData['results'][0];
          final String scientificName =
              bestMatch['species']['scientificNameWithoutAuthor'];
          final String familyName =
              bestMatch['species']['family']['scientificNameWithoutAuthor'];
          final String commonTitle =
              bestMatch['species']['commonNames']?.isNotEmpty == true
                  ? bestMatch['species']['commonNames'][0]
                  : scientificName;
          final double confidence =
              ((bestMatch['score'] ?? 0) * 100).toDouble();

          // 3A-3: Perenual API'si çekilirken, Gemini başarısız olduysa
          //        tür adıyla ikinci tur dene (paralel).
          final bool detailsFromCache =
              await PlantCacheService.get(scientificName) != null;
          final secondRound = await Future.wait([
            _fetchPerenualDetails(scientificName, commonTitle),
            disease.analyzed
                ? Future.value(disease) // ilk tur OK — tekrar çağırma
                : _callGeminiDiseaseCheck(
                    jpegFile, scientificName, commonTitle),
          ]);
          final perenualDetails =
              secondRound[0] as Map<String, dynamic>;
          disease = secondRound[1] as _DiseaseResult;

          // 3A-4: Deterministik tarımsal hesaplamalar
          final String basariSansi = _calculateSuccessRate(
            avgWeeklyTemp, numericPh, totalWeeklyRain,
            numericHumidity, perenualDetails,
          );
          final String konumYorumu = _generateLocationComment(
            avgWeeklyTemp, numericPh, totalWeeklyRain,
            numericHumidity, soilMoisture, soilTempC, perenualDetails,
          );
          final String sulamaTakvimi = _generateWateringSchedule(
            totalWeeklyRain, numericHumidity, perenualDetails,
          );
          final String gubreOnerisi =
              _generateFertilizerAdvice(numericPh, perenualDetails);

          return {
            "type": "plant",
            "data": {
              "title": (disease.analyzed && disease.present)
                  ? "$commonTitle — ${disease.name}"
                  : commonTitle,
              "scientific_name": scientificName,
              "description":
                  "Botanik Teşhis (%${confidence.toStringAsFixed(0)} güvenilirlik)"
                  " — ${detailsFromCache ? 'Önbellekten' : 'API Tabanlı'} Analiz",
              "from_cache": detailsFromCache,
              "disease_analyzed": disease.analyzed,
              "disease_present": disease.present,
              "disease_name": disease.name,
              "disease_confidence": disease.confidence,
              "severity": disease.severity,
              "symptoms": disease.symptoms,
              "treatment": disease.treatment,
              "disease_failure_reason": disease.failureReason,
              "plant_details": {
                "family": familyName,
                "halk_dilindeki_adi":
                    perenualDetails['other_names'] ?? commonTitle,
                "basari_sansi": basariSansi,
                "konum_yorumu": konumYorumu,
                "nasil_yetistirilir": perenualDetails['care_description'] ??
                    _buildGrowGuide(perenualDetails),
                "bakim_puf_noktasi": _buildCareGuide(perenualDetails),
                "hastalik_riskleri":
                    perenualDetails['pest_susceptibility'] ??
                    perenualDetails['pest_info'] ??
                    'Zararlı bilgisi bulunamadı.',
                "sulama_takvimi": sulamaTakvimi,
                "gubre_onerisi": gubreOnerisi,
                "hasat_zamani": _buildHarvestInfo(perenualDetails),
                "depolama_saklama": _buildStorageInfo(perenualDetails),
              },
            },
          };
        } else {
          // PlantNet başarısız — bölgesel rapor + mevcut Gemini sonucunu ekle.
          final report = RuleEngine.generateEnvironmentalReport(
            temp: numericTemp,
            humidity: numericHumidity,
            weeklyRain: totalWeeklyRain,
            ph: numericPh,
            soilMoisture: soilMoisture,
            soilTempC: soilTempC,
            month: DateTime.now().month,
          );
          final String reasonSuffix = plantNetResult.ok
              ? 'Kesin tür tespiti yapılamadı'
              : 'Tür tespit servisine ulaşılamadı (${plantNetResult.errorLabel})';
          return {
            "type": "plant",
            "data": {
              "title": (disease.analyzed && disease.present)
                  ? "Hasta Bitki — ${disease.name}"
                  : "Bölgesel Bitki Raporu",
              "description":
                  "$reasonSuffix. Etiketler: ${tagNames.take(3).join(', ')}. $report",
              "from_cache": false,
              "disease_analyzed": disease.analyzed,
              "disease_present": disease.present,
              "disease_name": disease.name,
              "disease_confidence": disease.confidence,
              "severity": disease.severity,
              "symptoms": disease.symptoms,
              "treatment": disease.treatment,
              "disease_failure_reason": disease.failureReason,
            }
          };
        }
      }

      // ═══ SENARYO B: TARLA — API + Yapay Zeka (Dinamik) ═══
      List<Map<String, dynamic>> recommendations =
          await CropRules.getDynamicRecommendations(
        numericTemp,
        numericPh,
        avgWeeklyTemp,
        totalWeeklyRain,
        soilMoisture: soilMoisture,
        soilTempC: soilTempC,
      );

      return {
        "type": "field",
        "data": {
          "title": "Ayrıntılı Ziraat Raporu",
          "description":
              "pH: ${numericPh.toStringAsFixed(1)} | Ort. Sıcaklık: $avgWeeklyTemp°C | Yağış: $totalWeeklyRain mm | Nem: %${numericHumidity.toStringAsFixed(0)} | Toprak Nem: ${(soilMoisture * 100).toStringAsFixed(1)}%",
          "crops": recommendations,
        },
      };
    } on SocketException catch (e) {
      return {
        'type': 'error',
        'data': {
          'message':
              'İnternet bağlantısı kesildi veya sunucuya ulaşılamadı. Lütfen Wi-Fi/mobil veriyi kontrol edip tekrar deneyin. (${e.osError?.message ?? e.message})',
        },
      };
    } on TimeoutException {
      return {
        'type': 'error',
        'data': {
          'message':
              'Sunucu yanıt vermedi (zaman aşımı). Bağlantınız yavaş olabilir, lütfen tekrar deneyin.',
        },
      };
    } catch (e) {
      return {
        'type': 'error',
        'data': {
          'message': 'Analiz başarısız oldu: $e',
        },
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // PLANTNET API — timeout + 1 retry + hata sınıflandırma
  // ═══════════════════════════════════════════════════
  static Future<_PlantNetResult> _callPlantNet(File jpegFile) async {
    final uri = Uri.parse(
      'https://my-api.plantnet.org/v2/identify/all?api-key=$_plantNetKey',
    );

    Future<_PlantNetResult> attempt() async {
      final req = http.MultipartRequest('POST', uri);
      req.files.add(
        await http.MultipartFile.fromPath('images', jpegFile.path),
      );
      req.fields['organs'] = 'auto';

      final streamed =
          await req.send().timeout(const Duration(seconds: 25));
      final raw = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        try {
          return _PlantNetResult.ok(
              jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {
          return _PlantNetResult.fail('geçersiz yanıt');
        }
      }
      if (streamed.statusCode == 429) {
        return _PlantNetResult.fail('günlük kota dolu');
      }
      if (streamed.statusCode == 401 || streamed.statusCode == 403) {
        return _PlantNetResult.fail('API anahtarı reddedildi');
      }
      return _PlantNetResult.fail('HTTP ${streamed.statusCode}');
    }

    for (var i = 0; i < 2; i++) {
      try {
        return await attempt();
      } on SocketException catch (e) {
        debugPrint('[PlantNet] SocketException (deneme ${i + 1}): $e');
        if (i == 1) return _PlantNetResult.fail('bağlantı sıfırlandı');
        await Future.delayed(const Duration(seconds: 2));
      } on TimeoutException {
        debugPrint('[PlantNet] Timeout (deneme ${i + 1})');
        if (i == 1) return _PlantNetResult.fail('zaman aşımı');
        await Future.delayed(const Duration(seconds: 2));
      } on HttpException catch (e) {
        debugPrint('[PlantNet] HttpException: $e');
        return _PlantNetResult.fail('HTTP hatası');
      } catch (e) {
        debugPrint('[PlantNet] Beklenmedik hata: $e');
        return _PlantNetResult.fail('bilinmeyen hata');
      }
    }
    return _PlantNetResult.fail('bağlantı kurulamadı');
  }

  // ═══════════════════════════════════════════════════
  // GEMİNİ VİZYON — Görüntüden Hastalık Tespiti (v2.5-flash)
  // ═══════════════════════════════════════════════════
  //
  // Not: gemini-1.5-flash Eylül 2025'te retired edildi. 2.5-flash multimodal
  // + structured output destekliyor. Fallback olarak 2.0-flash de denenir.
  // gemini-2.5-flash April 2026 preview — bazı keylerde çalışmıyor.
  // gemini-2.0-flash kesinlikle stable. gemini-2.0-flash-001 versioned pin.
  static const List<String> _geminiModels = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-001',
  ];

  static Future<_DiseaseResult> _callGeminiDiseaseCheck(
    File jpegFile,
    String scientificName,
    String commonName,
  ) async {
    if (_geminiKey.isEmpty) {
      debugPrint('[GeminiDisease] GEMINI_API_KEY yok — atlanıyor.');
      return _DiseaseResult.unknown('API anahtarı tanımlı değil');
    }

    // Gemini için hafif sıkıştırma — hız + kararlılık. Zaten JPEG ise sadece
    // boyutu küçültür; WebP'den geldiyse JPEG'e çevirir.
    File analysisFile;
    try {
      analysisFile = await ImageCompressor.compressToJpeg(
        jpegFile,
        maxDimension: 960,
        quality: 80,
      );
    } catch (e) {
      debugPrint('[GeminiDisease] Ön sıkıştırma hatası: $e');
      analysisFile = jpegFile;
    }

    final Uint8List bytes = await analysisFile.readAsBytes();
    final String b64 = base64Encode(bytes);
    debugPrint(
        '[GeminiDisease] Payload: ${(bytes.length / 1024).toStringAsFixed(0)} KB JPEG');

    final String speciesContext =
        (scientificName.isNotEmpty || commonName.isNotEmpty)
            ? 'Tür: ${commonName.isNotEmpty ? commonName : scientificName}'
                '${scientificName.isNotEmpty ? " ($scientificName)" : ""}.'
            : 'Tür henüz tespit edilmedi — görsel belirtilere göre değerlendir.';

    final String prompt = '''
Sen uzman bir bitki hastalıkları ve zararlıları tanı uzmanısın. $speciesContext

Bu bitkinin fotoğrafını DETAYLI incele:
• Yaprak lekeleri: kara leke, kahverengi/halkalı leke, antrakhoz
• Külleme (beyaz pudra), mildiyö (gri/beyaz tüylü yüzey)
• Pas hastalığı (turuncu/kahve toz benzeri spor)
• Sararma: kloroz (damar arası), mozaik deseni, nekroz
• Yanıklık: ateş yanıklığı, bakteriyel yanıklık (siyah/kahve kenar)
• Böcek hasarı: delik, galeri, beyazsinekler, kırmızıörümcek, yaprakbiti
• Besin eksikliği: N (alt yaprak sararlığı), Fe (damar arası kloroz)
• Su emmiş görünüm, kıvrılma, cücelik, solgunluk

KARAR KURALLARI:
1. Görünür bir belirti VARSA → disease_present=true, hastalığı Türkçe adıyla yaz.
2. Şüpheli durumlarda da belirt — belirtileri görmezden gelme.
3. Gerçekten HİÇBİR belirti yoksa → disease_present=false.
4. disease_confidence: 80+=açık belirti, 50-79=orta, 30-49=şüpheli.
5. Tüm metin Türkçe. Boş alan gerekirse "".
6. Yoktan hastalık uydurma. Ama gördüğünü çekinmeden söyle.
''';

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': b64,
              }
            },
            {'text': prompt},
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.35,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'disease_present': {'type': 'BOOLEAN'},
            'disease_name': {'type': 'STRING'},
            'disease_confidence': {'type': 'INTEGER'},
            'severity': {
              'type': 'STRING',
              'enum': ['', 'hafif', 'orta', 'şiddetli'],
            },
            'symptoms': {'type': 'STRING'},
            'treatment': {'type': 'STRING'},
          },
          'required': [
            'disease_present',
            'disease_name',
            'disease_confidence',
            'severity',
            'symptoms',
            'treatment',
          ],
        },
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    };

    final String bodyJson = jsonEncode(requestBody);

    for (final model in _geminiModels) {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiKey',
      );

      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final res = await http
              .post(uri,
                  headers: {'Content-Type': 'application/json'},
                  body: bodyJson)
              .timeout(const Duration(seconds: 35));

          if (res.statusCode == 200) {
            final parsed = _parseGeminiResponse(res.body);
            if (parsed != null) {
              debugPrint(
                  '[GeminiDisease] ✓ $model (deneme $attempt): present=${parsed.present} name="${parsed.name}"');
              return parsed;
            }
            debugPrint(
                '[GeminiDisease] $model 200 döndü ama yanıt geçersiz: ${_truncate(res.body, 500)}');
            // Yanıt parse edilemedi — aynı modelle bir kez daha deneme
            if (attempt < 2) {
              await Future.delayed(const Duration(seconds: 1));
              continue;
            }
            break; // sonraki modele geç
          }

          // 404: model yok/retired. Doğrudan sonraki modele düş.
          if (res.statusCode == 404) {
            debugPrint('[GeminiDisease] $model 404 — sonraki modele geçiliyor');
            break;
          }
          // 401/403: key sorunu — model değiştirmenin faydası yok.
          if (res.statusCode == 401 || res.statusCode == 403) {
            debugPrint(
                '[GeminiDisease] $model ${res.statusCode}: ${_truncate(res.body, 300)}');
            return _DiseaseResult.unknown('API anahtarı reddedildi');
          }
          // 5xx veya 429: retry
          if (res.statusCode >= 500 || res.statusCode == 429) {
            debugPrint(
                '[GeminiDisease] $model ${res.statusCode} (deneme $attempt)');
            if (attempt < 2) {
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            break;
          }

          debugPrint(
              '[GeminiDisease] $model HTTP ${res.statusCode}: ${_truncate(res.body, 300)}');
          break;
        } on TimeoutException {
          debugPrint('[GeminiDisease] $model timeout (deneme $attempt)');
          if (attempt < 2) continue;
        } on SocketException catch (e) {
          debugPrint('[GeminiDisease] $model socket: $e (deneme $attempt)');
          if (attempt < 2) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } catch (e, st) {
          debugPrint('[GeminiDisease] $model beklenmedik: $e\n$st');
          break;
        }
      }
    }

    return _DiseaseResult.unknown('servis yanıt vermedi');
  }

  /// Gemini yanıtını güvenli parse eder — safety block, finishReason,
  /// eksik alan, bozuk JSON hepsini yakalar.
  static _DiseaseResult? _parseGeminiResponse(String rawBody) {
    try {
      final outer = jsonDecode(rawBody) as Map<String, dynamic>;

      // Prompt-level blok (tüm istek reddedildi)
      final blockReason = outer['promptFeedback']?['blockReason'];
      if (blockReason != null) {
        debugPrint('[GeminiDisease] Prompt bloklandı: $blockReason');
        return null;
      }

      final candidates = outer['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        debugPrint('[GeminiDisease] Candidates boş');
        return null;
      }

      final cand = candidates.first as Map<String, dynamic>;
      final finishReason = cand['finishReason'];
      // STOP + MAX_TOKENS kabul edilebilir; SAFETY/RECITATION/OTHER reddet.
      if (finishReason != null &&
          finishReason != 'STOP' &&
          finishReason != 'MAX_TOKENS') {
        debugPrint('[GeminiDisease] finishReason: $finishReason — reddedildi');
        return null;
      }

      final parts = cand['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        debugPrint('[GeminiDisease] parts boş');
        return null;
      }

      final text = parts.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        debugPrint('[GeminiDisease] text boş');
        return null;
      }

      // Gemini bazen code fence içinde döndürüyor — temizle
      String cleaned = text.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*'), '');
        cleaned = cleaned.replaceAll(RegExp(r'\s*```\s*$'), '');
      }

      final parsedJson = jsonDecode(cleaned);
      if (parsedJson is! Map<String, dynamic>) {
        debugPrint('[GeminiDisease] JSON obje değil: $parsedJson');
        return null;
      }

      final bool present = parsedJson['disease_present'] == true;
      final int rawConf =
          (parsedJson['disease_confidence'] as num?)?.toInt() ?? 0;
      return _DiseaseResult(
        analyzed: true,
        present: present,
        name: (parsedJson['disease_name'] ?? '').toString().trim(),
        confidence: rawConf.clamp(0, 100),
        severity: (parsedJson['severity'] ?? '').toString().trim(),
        symptoms: (parsedJson['symptoms'] ?? '').toString().trim(),
        treatment: (parsedJson['treatment'] ?? '').toString().trim(),
      );
    } catch (e) {
      debugPrint('[GeminiDisease] Parse hatası: $e');
      return null;
    }
  }

  static String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n)}…';

  // ═══════════════════════════════════════════════════
  // PERENUAL API — Bitki Detaylarını Çek
  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> _fetchPerenualDetails(
    String scientificName,
    String commonName,
  ) async {
    // ── CACHE HIT: local Hive first, then Firestore community DB ──
    final cached = await PlantCacheService.get(scientificName);
    if (cached != null && cached.isNotEmpty) return cached;

    Map<String, dynamic> result = {};
    try {
      // 1. İsimle ara → ID bul
      final searchQuery = Uri.encodeComponent(commonName);
      final searchRes = await http.get(Uri.parse(
        'https://perenual.com/api/v2/species-list?key=$_perenualKey&q=$searchQuery',
      ));

      if (searchRes.statusCode == 200) {
        final searchData = jsonDecode(searchRes.body);
        final List dataList = searchData['data'] ?? [];
        if (dataList.isEmpty) return result;

        // En iyi eşleşmeyi bul (bilimsel isim öncelikli)
        int speciesId = dataList[0]['id'];
        for (var item in dataList) {
          final List sciNames = item['scientific_name'] ?? [];
          if (sciNames.any((n) => n
              .toString()
              .toLowerCase()
              .contains(scientificName.toLowerCase().split(' ').first))) {
            speciesId = item['id'];
            break;
          }
        }

        // 2. ID ile detayları çek
        final detailRes = await http.get(Uri.parse(
          'https://perenual.com/api/v2/species/details/$speciesId?key=$_perenualKey',
        ));

        if (detailRes.statusCode == 200) {
          final d = jsonDecode(detailRes.body);

          result['common_name'] = d['common_name'] ?? commonName;
          result['other_names'] =
              (d['other_name'] as List?)?.join(', ') ?? commonName;
          result['type'] = d['type'] ?? 'Bilinmiyor';
          result['cycle'] =
              d['cycle'] ?? 'Bilinmiyor'; // Perennial, Annual, etc.
          result['watering'] =
              d['watering'] ?? 'Bilinmiyor'; // Frequent, Average, etc.
          result['watering_benchmark'] =
              d['watering_general_benchmark']; // {value: "5-7", unit: "days"}
          result['sunlight'] =
              (d['sunlight'] as List?)?.join(', ') ?? 'Tam güneş';
          result['soil'] = (d['soil'] as List?)?.join(', ') ?? 'Bilinmiyor';
          result['growth_rate'] = d['growth_rate'] ?? 'Bilinmiyor';
          result['maintenance'] = d['maintenance'] ?? 'Bilinmiyor';
          result['care_level'] = d['care_level'] ?? 'Bilinmiyor';
          result['description'] = d['description'] ?? '';
          result['indoor'] = d['indoor'] ?? false;
          result['flowers'] = d['flowers'] ?? false;
          result['flowering_season'] = d['flowering_season'];
          result['fruiting_season'] = d['fruiting_season'];
          result['harvest_season'] = d['harvest_season'];
          result['harvest_method'] = d['harvest_method'];
          result['edible_fruit'] = d['edible_fruit'] ?? false;
          result['edible_leaf'] = d['edible_leaf'] ?? false;
          result['medicinal'] = d['medicinal'] ?? false;
          result['poisonous_to_humans'] = d['poisonous_to_humans'] ?? false;
          result['poisonous_to_pets'] = d['poisonous_to_pets'] ?? false;
          result['drought_tolerant'] = d['drought_tolerant'] ?? false;
          result['salt_tolerant'] = d['salt_tolerant'] ?? false;
          result['invasive'] = d['invasive'] ?? false;
          result['tropical'] = d['tropical'] ?? false;
          result['pest_susceptibility'] =
              (d['pest_susceptibility'] as List?)?.join(', ');
          result['pruning_month'] = (d['pruning_month'] as List?)?.join(', ');
          result['hardiness_min'] = d['hardiness']?['min'];
          result['hardiness_max'] = d['hardiness']?['max'];
          result['origin'] = (d['origin'] as List?)?.join(', ');
          result['dimensions'] = d['dimensions'];
          result['propagation'] = (d['propagation'] as List?)?.join(', ');

          // Bakım rehberi ayrı çek
          try {
            final careRes = await http.get(Uri.parse(
              'https://perenual.com/api/species-care-guide-list?species_id=$speciesId&key=$_perenualKey',
            ));
            if (careRes.statusCode == 200) {
              final careData = jsonDecode(careRes.body);
              final List careList = careData['data'] ?? [];
              if (careList.isNotEmpty) {
                final List sections = careList[0]['section'] ?? [];
                StringBuffer careDesc = StringBuffer();
                for (var sec in sections) {
                  String type = (sec['type'] ?? '').toString();
                  String desc = (sec['description'] ?? '').toString();
                  if (desc.isNotEmpty) {
                    String turkishType = _translateCareType(type);
                    careDesc.writeln('$turkishType: $desc');
                    careDesc.writeln('');
                  }
                }
                result['care_description'] = careDesc.toString().trim();
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Perenual returned data → save to cache before returning
    if (result.isNotEmpty) {
      PlantCacheService.save(scientificName, result);
      return result;
    }

    // Perenual boş döndüyse: OfflineEncyclopedia'ya bak, yoksa cache'e dön
    final enc = OfflineEncyclopedia.getByName(commonName);
    if (enc != null && enc.isNotEmpty) {
      PlantCacheService.save(scientificName, enc);
      return enc;
    }
    try {
      final cached = await PlantCacheService.get(scientificName);
      if (cached != null && cached.isNotEmpty) return cached;
    } catch (_) {}
    return {};
  }

  static String _translateCareType(String type) {
    switch (type.toLowerCase()) {
      case 'watering':
        return '💧 Sulama';
      case 'sunlight':
        return '☀️ Güneş İhtiyacı';
      case 'pruning':
        return '✂️ Budama';
      case 'fertilization':
        return '🧪 Gübreleme';
      default:
        return '📋 $type';
    }
  }

  // ═══════════════════════════════════════════════════
  // AGROMONITORING API — Toprak Verisi
  // ═══════════════════════════════════════════════════
  static Future<Map<String, double>?> _getAgroSoilData(
    double lat,
    double lng,
  ) async {
    // Agromonitoring ücretli bir servistir. Key yoksa sessizce atla —
    // kullanıcıdan asla key isteme (proje kuralı: sadece ücretsiz servisler).
    if (_agroKey.isEmpty) return null;
    try {
      // Basit bir polygon oluştur (nokta etrafında ~100mx100m kare)
      final double offset = 0.0005;
      final polygon = {
        "name": "temp_field",
        "geo_json": {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Polygon",
            "coordinates": [
              [
                [lng - offset, lat - offset],
                [lng + offset, lat - offset],
                [lng + offset, lat + offset],
                [lng - offset, lat + offset],
                [lng - offset, lat - offset],
              ]
            ]
          }
        }
      };

      // Polygon oluştur
      final createRes = await http.post(
        Uri.parse(
            'https://api.agromonitoring.com/agro/1.0/polygons?appid=$_agroKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(polygon),
      );

      if (createRes.statusCode == 201 || createRes.statusCode == 200) {
        final polyData = jsonDecode(createRes.body);
        final polyId = polyData['id'];

        // Toprak verisi çek
        final soilRes = await http.get(Uri.parse(
          'https://api.agromonitoring.com/agro/1.0/soil?polyid=$polyId&appid=$_agroKey',
        ));

        // Polygon'u temizle (free tier sınırı)
        http.delete(Uri.parse(
          'https://api.agromonitoring.com/agro/1.0/polygons/$polyId?appid=$_agroKey',
        ));

        if (soilRes.statusCode == 200) {
          final soilData = jsonDecode(soilRes.body);
          double t10Kelvin = (soilData['t10'] as num?)?.toDouble() ?? 288.15;
          double moisture = (soilData['moisture'] as num?)?.toDouble() ?? 0.0;
          return {
            'soil_temp_c': t10Kelvin - 273.15,
            'moisture': moisture,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // ═══════════════════════════════════════════════════
  // DETERMİNİSTİK HESAPLAMA FONKSİYONLARI
  // ═══════════════════════════════════════════════════

  /// Başarı şansı hesaplama — tamamen formül bazlı
  static String _calculateSuccessRate(
    double avgTemp,
    double ph,
    double weeklyRain,
    double humidity,
    Map<String, dynamic> p,
  ) {
    double score = 70; // Baz skor
    List<String> reasons = [];

    // Sulama ihtiyacına göre yağış uyumu
    String watering = (p['watering'] ?? '').toString().toLowerCase();
    if (watering == 'frequent' && weeklyRain < 10) {
      score -= 15;
      reasons.add(
          'Bu bitki sık sulama ister ama beklenen yağış düşük (${weeklyRain}mm)');
    } else if (watering == 'minimum' && weeklyRain > 30) {
      score -= 10;
      reasons.add('Bu bitki az su ister ama aşırı yağış bekleniyor');
    } else if (watering == 'average' && weeklyRain >= 10 && weeklyRain <= 30) {
      score += 10;
      reasons.add('Yağış miktarı bu bitkinin su ihtiyacıyla uyumlu');
    }

    // Güneş ışığı ihtiyacı
    String sunlight = (p['sunlight'] ?? '').toString().toLowerCase();
    if (sunlight.contains('full sun') && avgTemp >= 15 && avgTemp <= 30) {
      score += 10;
      reasons.add('Tam güneş seviyor ve sıcaklık ($avgTemp°C) uygun');
    }

    // pH kontrolü
    if (ph >= 5.5 && ph <= 7.5) {
      score += 5;
      reasons.add(
          'Toprak pH (${ph.toStringAsFixed(1)}) çoğu bitki için ideal aralıkta');
    } else if (ph < 5.0) {
      score -= 15;
      reasons.add(
          'Toprak çok asidik (pH ${ph.toStringAsFixed(1)}), kireçleme gerekli');
    } else if (ph > 8.0) {
      score -= 15;
      reasons.add(
          'Toprak çok bazik (pH ${ph.toStringAsFixed(1)}), uyumsuzluk riski');
    }

    // Kuraklık toleransı
    if (p['drought_tolerant'] == true && weeklyRain < 5) {
      score += 10;
      reasons.add('Kuraklığa dayanıklı bitki — kuru koşullar sorun değil');
    }

    // Tropik bitki sıcaklık kontrolü
    if (p['tropical'] == true && avgTemp < 15) {
      score -= 20;
      reasons.add('Tropik bitki ama sıcaklık ($avgTemp°C) düşük — don riski!');
    }

    // Hardiness zone kontrolü
    if (p['hardiness_min'] != null) {
      try {
        int minZone = int.parse(p['hardiness_min'].toString());
        if (minZone > 8 && avgTemp < 10) {
          score -= 10;
          reasons.add('Sertlik zonu (min: $minZone) bu iklim için riskli');
        }
      } catch (_) {}
    }

    // Nem kontrolü
    if (humidity > 80 && watering == 'minimum') {
      score -= 5;
      reasons.add(
          'Yüksek nem (%${humidity.toStringAsFixed(0)}) mantar riski oluşturabilir');
    }

    score = score.clamp(15, 98);

    return '%${score.toStringAsFixed(0)} — ${reasons.join('. ')}${reasons.isEmpty ? 'Koşullar genel olarak uygun.' : '.'}';
  }

  /// Konum yorumu — deterministik
  static String _generateLocationComment(
    double avgTemp,
    double ph,
    double weeklyRain,
    double humidity,
    double soilMoisture,
    double soilTempC,
    Map<String, dynamic> p,
  ) {
    StringBuffer sb = StringBuffer();

    // Sıcaklık değerlendirmesi
    String sunlight = (p['sunlight'] ?? '').toString();
    sb.writeln('🌡️ Haftalık ort. sıcaklık: $avgTemp°C');
    if (avgTemp >= 20 && avgTemp <= 30) {
      sb.writeln('Sıcaklık çoğu bitki için ideal büyüme penceresinde.');
    } else if (avgTemp < 10) {
      sb.writeln('Sıcaklık düşük — soğuğa hassas bitkiler için don riski var.');
    } else if (avgTemp > 35) {
      sb.writeln('Aşırı sıcak — yaprak yanığı ve su stresi riski yüksek.');
    }

    // pH değerlendirmesi
    sb.writeln('\n🌿 Toprak pH: ${ph.toStringAsFixed(1)}');
    if (ph >= 6.0 && ph <= 7.0) {
      sb.writeln('İdeal tarım toprağı. Çoğu sebze ve meyve için mükemmel.');
    } else if (ph < 5.5) {
      sb.writeln('Çok asidik — kireçleme uygulaması önerilir.');
    } else if (ph > 7.5) {
      sb.writeln('Bazik toprak — demir ve çinko eksikliği riski var.');
    }

    // Toprak nem ve sıcaklık (Agromonitoring)
    if (soilMoisture > 0) {
      sb.writeln(
          '\n💧 Toprak Nem Oranı: %${(soilMoisture * 100).toStringAsFixed(1)}');
      if (soilMoisture > 0.4) {
        sb.writeln('Toprak çok nemli — kök çürüklüğü riski. Sulama azaltın.');
      } else if (soilMoisture < 0.15) {
        sb.writeln('Toprak kuruyor — düzenli sulama şart.');
      } else {
        sb.writeln('Toprak nem seviyesi kabul edilebilir aralıkta.');
      }
    }

    if (soilTempC > 0) {
      sb.writeln(
          '🌡️ Toprak Sıcaklığı (10cm): ${soilTempC.toStringAsFixed(1)}°C');
      if (soilTempC < 10) {
        sb.writeln('Toprak henüz ısınmamış — erken ekim riskli olabilir.');
      } else if (soilTempC >= 15 && soilTempC <= 25) {
        sb.writeln('Toprak sıcaklığı çimlenme ve kök gelişimi için ideal.');
      }
    }

    // Güneş ihtiyacı
    sb.writeln('\n☀️ Güneş İhtiyacı: $sunlight');

    // Haftalık yağış
    sb.writeln('\n🌧️ Beklenen Yağış: $weeklyRain mm/hafta');
    if (weeklyRain > 25) {
      sb.writeln('Yüksek yağış — drenaj ve mantar kontrolüne dikkat.');
    } else if (weeklyRain < 5) {
      sb.writeln('Çok az yağış — ek sulama kesinlikle gerekli.');
    }

    return sb.toString().trim();
  }

  /// Sulama takvimi — deterministik
  static String _generateWateringSchedule(
    double weeklyRain,
    double humidity,
    Map<String, dynamic> p,
  ) {
    StringBuffer sb = StringBuffer();
    String watering = (p['watering'] ?? 'Average').toString();
    var benchmark = p['watering_benchmark'];

    sb.writeln('Sulama İhtiyacı: $watering');
    if (benchmark != null) {
      sb.writeln(
          'Önerilen Sıklık: Her ${benchmark['value']} ${benchmark['unit'] == 'days' ? 'günde bir' : benchmark['unit']}');
    }

    sb.writeln('');
    if (weeklyRain > 20) {
      sb.writeln(
          '📊 Bu hafta $weeklyRain mm yağış bekleniyor — ek sulama gerekmeyebilir.');
      sb.writeln('Toprak üst yüzeyini parmak testiyle kontrol edin.');
    } else if (weeklyRain > 10) {
      sb.writeln('📊 Haftalık $weeklyRain mm yağış kısmi yeterli.');
      if (watering.toLowerCase() == 'frequent') {
        sb.writeln(
            'Haftada 2-3 kez ek sulama yapın, sabah 06:00-08:00 arası ideal.');
      } else {
        sb.writeln('Haftada 1-2 kez ek sulama yeterli olabilir.');
      }
    } else {
      sb.writeln('📊 Yağış çok az ($weeklyRain mm). Düzenli sulama şart!');
      if (watering.toLowerCase() == 'frequent') {
        sb.writeln('Günlük sulama önerilir. Damla sulama en verimli yöntem.');
      } else if (watering.toLowerCase() == 'minimum') {
        sb.writeln(
            'Haftada 1 kez derin sulama yeterli — bu bitki az su ister.');
      } else {
        sb.writeln('Haftada 2-3 kez sulama yapın.');
      }
    }

    sb.writeln('');
    if (p['drought_tolerant'] == true) {
      sb.writeln('💡 Not: Bu bitki kuraklığa dayanıklı, sulamayı abartmayın.');
    }

    return sb.toString().trim();
  }

  /// Gübre önerisi — deterministik
  static String _generateFertilizerAdvice(double ph, Map<String, dynamic> p) {
    StringBuffer sb = StringBuffer();
    String care = (p['care_level'] ?? 'Medium').toString();
    String maintenance = (p['maintenance'] ?? '').toString();
    String cycle = (p['cycle'] ?? '').toString();

    sb.writeln('Toprak pH: ${ph.toStringAsFixed(1)}');
    sb.writeln('');

    if (ph < 5.5) {
      sb.writeln('⚠️ Toprak çok asidik:');
      sb.writeln('• Dekara 200-300 kg tarım kireci uygulayın');
      sb.writeln('• Kireçleme sonbahar/kış aylarında yapılmalı');
      sb.writeln('• 6 ay sonra pH kontrolü yapın');
    } else if (ph > 7.5) {
      sb.writeln('⚠️ Toprak bazik:');
      sb.writeln('• Dekara 20-30 kg elementel kükürt uygulayın');
      sb.writeln('• Asidik gübreler tercih edin (Amonyum Sülfat)');
    } else {
      sb.writeln('✅ pH uygun aralıkta.');
    }

    sb.writeln('');
    if (cycle.toLowerCase().contains('annual')) {
      sb.writeln(
          'Yıllık bitki — taban gübresi + gelişim dönemi takviyesi önerilir:');
      sb.writeln('• Ekim öncesi: Dekara 20 kg 15-15-15 kompoze');
      sb.writeln('• Gelişim dönemi: Dekara 10 kg Amonyum Nitrat');
    } else if (cycle.toLowerCase().contains('perennial')) {
      sb.writeln('Çok yıllık bitki — yılda 2 kez gübreleme:');
      sb.writeln('• İlkbahar: Dengeli NPK gübresi');
      sb.writeln('• Sonbahar: Fosfor ağırlıklı taban gübresi');
    }

    if (maintenance.toLowerCase() == 'high' || care.toLowerCase() == 'high') {
      sb.writeln(
          '\n💡 Bu bitki yüksek bakım ister — yaprak gübresi ve mikro element takviyesi düşünün.');
    }

    return sb.toString().trim();
  }

  /// Yetiştirme rehberi oluştur — deterministik
  static String _buildGrowGuide(Map<String, dynamic> p) {
    StringBuffer sb = StringBuffer();
    sb.writeln('🌱 Yetiştirme Rehberi (API Verisi)');
    sb.writeln('');
    sb.writeln('Tür: ${p['type'] ?? 'Bilinmiyor'}');
    sb.writeln('Yaşam Döngüsü: ${p['cycle'] ?? 'Bilinmiyor'}');
    sb.writeln('Güneş: ${p['sunlight'] ?? 'Bilinmiyor'}');
    sb.writeln('Toprak Tercihi: ${p['soil'] ?? 'Bilinmiyor'}');
    sb.writeln('Büyüme Hızı: ${p['growth_rate'] ?? 'Bilinmiyor'}');
    sb.writeln('İç Mekan Uygunluğu: ${p['indoor'] == true ? 'Evet' : 'Hayır'}');

    if (p['propagation'] != null) {
      sb.writeln('Çoğaltma Yöntemleri: ${p['propagation']}');
    }
    if (p['origin'] != null) {
      sb.writeln('Köken: ${p['origin']}');
    }
    if (p['dimensions'] != null) {
      final dim = p['dimensions'];
      if (dim is Map) {
        sb.writeln(
            'Boyut: ${dim['min_value']}-${dim['max_value']} ${dim['unit']}');
      }
    }

    return sb.toString().trim();
  }

  /// Bakım rehberi oluştur — deterministik
  static String _buildCareGuide(Map<String, dynamic> p) {
    StringBuffer sb = StringBuffer();
    sb.writeln('Bakım Seviyesi: ${p['care_level'] ?? 'Orta'}');
    sb.writeln('Bakım Yoğunluğu: ${p['maintenance'] ?? 'Bilinmiyor'}');
    sb.writeln('');

    if (p['pruning_month'] != null &&
        p['pruning_month'].toString().isNotEmpty) {
      sb.writeln('✂️ Budama Ayları: ${p['pruning_month']}');
    }

    if (p['drought_tolerant'] == true) {
      sb.writeln('🏜️ Kuraklığa dayanıklı — fazla sulamadan kaçının');
    }
    if (p['salt_tolerant'] == true) {
      sb.writeln('🧂 Tuza dayanıklı — kıyı bölgelerde yetişebilir');
    }
    if (p['poisonous_to_humans'] == true) {
      sb.writeln('⚠️ DİKKAT: İnsanlar için zehirli!');
    }
    if (p['poisonous_to_pets'] == true) {
      sb.writeln('🐾 DİKKAT: Evcil hayvanlar için zehirli!');
    }
    if (p['medicinal'] == true) {
      sb.writeln('💊 Tıbbi kullanım alanı var');
    }
    if (p['invasive'] == true) {
      sb.writeln('⚠️ İstilacı tür — yayılmasını kontrol altında tutun');
    }

    if (p['pest_susceptibility'] != null) {
      sb.writeln('\n🐛 Hassas Olduğu Zararlılar: ${p['pest_susceptibility']}');
    }

    return sb.toString().trim();
  }

  /// Hasat bilgisi — deterministik
  static String _buildHarvestInfo(Map<String, dynamic> p) {
    StringBuffer sb = StringBuffer();
    if (p['harvest_season'] != null) {
      sb.writeln('Hasat Mevsimi: ${p['harvest_season']}');
    }
    if (p['harvest_method'] != null) {
      sb.writeln('Hasat Yöntemi: ${p['harvest_method']}');
    }
    if (p['fruiting_season'] != null) {
      sb.writeln('Meyve Mevsimi: ${p['fruiting_season']}');
    }
    if (p['flowering_season'] != null) {
      sb.writeln('Çiçeklenme: ${p['flowering_season']}');
    }
    if (p['edible_fruit'] == true) {
      sb.writeln('✅ Meyvesi yenilebilir');
    }
    if (p['edible_leaf'] == true) {
      sb.writeln('✅ Yaprağı yenilebilir');
    }
    if (sb.isEmpty) {
      sb.writeln('Hasat bilgisi API\'den alınamadı.');
    }
    return sb.toString().trim();
  }

  /// Depolama bilgisi — deterministik
  static String _buildStorageInfo(Map<String, dynamic> p) {
    StringBuffer sb = StringBuffer();
    String type = (p['type'] ?? '').toString().toLowerCase();
    bool edible = p['edible_fruit'] == true || p['edible_leaf'] == true;

    if (edible) {
      if (type.contains('vegetable') || type.contains('herb')) {
        sb.writeln('🥬 Sebze/Ot Depolama:');
        sb.writeln('• Sıcaklık: 2-4°C');
        sb.writeln('• Nem: %90-95');
        sb.writeln('• Raf ömrü: 5-14 gün (türe göre değişir)');
        sb.writeln('• Etilen gazı üreten meyvelerden uzak tutun');
      } else if (type.contains('fruit')) {
        sb.writeln('🍎 Meyve Depolama:');
        sb.writeln('• Sıcaklık: 0-4°C');
        sb.writeln('• Nem: %85-90');
        sb.writeln('• Olgunlaştıktan sonra buzdolabında saklayın');
        sb.writeln('• Dondurmayın — hücre yapısı bozulur');
      } else {
        sb.writeln('📦 Genel Depolama:');
        sb.writeln('• Serin, kuru ve karanlık ortamda saklayın');
        sb.writeln('• Doğrudan güneş ışığından koruyun');
      }
    } else {
      sb.writeln('Bu bitki süs/ağaç türü olarak değerlendirilmektedir.');
      sb.writeln('Hasat sonrası depolama bilgisi uygulanabilir değil.');
    }

    return sb.toString().trim();
  }

  // ═══════════════════════════════════════════════════
  // TARLAYA ÖZEL EKİM PLANI (Rule Engine — deterministik)
  // ═══════════════════════════════════════════════════
  static Future<String> generateFieldPlan(
    String plantName,
    String fieldName, {
    double? latitude,
    double? longitude,
    double? ph,
    double? avgTemp,
    double? totalRain,
    double? areaDekar,
  }) async {
    final plantDetails = OfflineEncyclopedia.getByName(plantName) ?? {};
    return RuleEngine.generateFieldPlan(
      plantName: plantName,
      fieldName: fieldName,
      ph: ph ?? 6.8,
      avgTemp: avgTemp ?? 20.0,
      totalRain: totalRain ?? 15.0,
      areaDekar: areaDekar ?? 1.0,
      month: DateTime.now().month,
      plantDetails: plantDetails,
    );
  }

  // ═══════════════════════════════════════════════════
  // TARLA DETAY ANALİZİ (Hava + Toprak + 7 Gün + AI Yorum)
  // ═══════════════════════════════════════════════════
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
    double soilMoisture = 0;
    double soilTempC = 0;
    List<Map<String, dynamic>> dailyForecast = [];

    // Tüm çevre verileri paralel çekiliyor
    await Future.wait([
      // 1) Hava (Open-Meteo — key gerektirmez)
      () async {
        try {
          final wRes = await http
              .get(Uri.parse(
                'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&wind_speed_unit=ms&timezone=auto',
              ))
              .timeout(const Duration(seconds: 8));
          if (wRes.statusCode == 200) {
            final cur = jsonDecode(wRes.body)['current'];
            numericTemp = (cur['temperature_2m'] as num?)?.toDouble() ?? numericTemp;
            numericHumidity = (cur['relative_humidity_2m'] as num?)?.toDouble() ?? numericHumidity;
            numericWind = (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0;
            weatherDesc = _wmoCodeToTr((cur['weather_code'] as num?)?.toInt() ?? 0);
          }
        } catch (_) {}
      }(),
      // 2) Toprak pH
      () async {
        try {
          final phRes = await http
              .get(Uri.parse(
                'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$longitude&lat=$latitude&property=phh2o&depth=0-5cm&value=mean',
              ))
              .timeout(const Duration(seconds: 10));
          if (phRes.statusCode == 200) {
            final val = jsonDecode(phRes.body)['properties']?['layers']?[0]
                ?['depths']?[0]?['values']?['mean'];
            if (val != null) numericPh = (val as num).toDouble() / 10.0;
          }
        } catch (_) {}
      }(),
      // 3) 7 Günlük Tahmin
      () async {
        try {
          final fRes = await http
              .get(Uri.parse(
                'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto',
              ))
              .timeout(const Duration(seconds: 8));
          if (fRes.statusCode == 200) {
            final fd = jsonDecode(fRes.body)['daily'];
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
                'rain': dayRain
              });
            }
            avgWeeklyTemp = double.parse((sumTemp / 7).toStringAsFixed(1));
            totalWeeklyRain = double.parse(totalWeeklyRain.toStringAsFixed(1));
          }
        } catch (_) {}
      }(),
      // 4) Agromonitoring toprak verisi
      () async {
        try {
          final agroData = await _getAgroSoilData(latitude, longitude);
          if (agroData != null) {
            soilMoisture = agroData['moisture'] ?? 0.0;
            soilTempC = agroData['soil_temp_c'] ?? 0.0;
          }
        } catch (_) {}
      }(),
    ]);

    // Ürün önerileri (Agromonitoring + Gemini API ile %100 dinamik)
    List<Map<String, dynamic>> crops =
        await CropRules.getDynamicRecommendations(
      numericTemp,
      numericPh,
      avgWeeklyTemp,
      totalWeeklyRain,
      soilMoisture: soilMoisture,
      soilTempC: soilTempC,
    );

    // Rule Engine haftalık yorum
    final String aiWeeklyComment = RuleEngine.generateWeeklyComment(
      fieldName: fieldName,
      temp: numericTemp,
      humidity: numericHumidity,
      wind: numericWind,
      ph: numericPh,
      avgTemp: avgWeeklyTemp,
      totalWeeklyRain: totalWeeklyRain,
      soilMoisture: soilMoisture,
      soilTempC: soilTempC,
      month: DateTime.now().month,
      crops: crops,
    );

    return {
      'success': true,
      'temp': numericTemp,
      'humidity': numericHumidity,
      'wind': numericWind,
      'weather_desc': weatherDesc,
      'ph': numericPh,
      'avg_weekly_temp': avgWeeklyTemp,
      'total_weekly_rain': totalWeeklyRain,
      'soil_moisture': soilMoisture,
      'soil_temp_c': soilTempC,
      'daily_forecast': dailyForecast,
      'crops': crops,
      'ai_weekly_comment': aiWeeklyComment,
    };
  }

  // ═══════════════════════════════════════════════════
  // REHBER SİSTEMİ (Yeni Eklenen Özellik)
  // ═══════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════
  // REHBER SİSTEMİ (Gemini Çıkarıldı - Tamamen API Tabanlı)
  // ═══════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════
  // REHBER SİSTEMİ (Translator Paketi ile Tam Dinamik Çeviri)
  // ═══════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════
  // REHBER SİSTEMİ (Firestore Veritabanı + API Fallback)
  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getPlantGuide(
    String query,
    double lat,
    double lng, {
    String scale = 'Hobi',
  }) async {
    try {
      String normalizedQuery = query.toLowerCase().trim();

      // --- 1. ÇEVRESEL VERİLERİ HAZIRLA ---
      double temp = 20.0;
      double ph = 6.8;
      double hum = 50.0;
      String locationName = "Bölgeniz";
      List<Map<String, dynamic>> weeklyForecast = [];

      try {
        // Anlık hava + 7 günlük tahmin paralel çek (Open-Meteo — key yok)
        final results = await Future.wait([
          http.get(Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m&timezone=auto',
          )).timeout(const Duration(seconds: 5)),
          http.get(Uri.parse(
            'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,relative_humidity_2m_mean,windspeed_10m_max,weathercode&timezone=auto',
          )).timeout(const Duration(seconds: 5)),
          http.get(Uri.parse(
            'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$lng&lat=$lat&property=phh2o&depth=0-5cm&value=mean',
          )).timeout(const Duration(seconds: 5)),
        ]);

        // Anlık hava (Open-Meteo — lokasyon adı yok, default kalır)
        if (results[0].statusCode == 200) {
          final cur = jsonDecode(results[0].body)['current'];
          temp = (cur['temperature_2m'] as num?)?.toDouble() ?? temp;
          hum = (cur['relative_humidity_2m'] as num?)?.toDouble() ?? hum;
        }

        // 7 günlük tahmin
        if (results[1].statusCode == 200) {
          final fd = jsonDecode(results[1].body)['daily'];
          final dates = fd['time'] as List;
          for (int i = 0; i < dates.length && i < 7; i++) {
            weeklyForecast.add({
              'date': dates[i],
              'temp_max': (fd['temperature_2m_max'][i] as num).toDouble(),
              'temp_min': (fd['temperature_2m_min'][i] as num).toDouble(),
              'rain_mm': (fd['precipitation_sum'][i] as num).toDouble(),
              'humidity': (fd['relative_humidity_2m_mean']?[i] as num?)?.toDouble() ?? 50,
              'wind_kmh': (fd['windspeed_10m_max']?[i] as num?)?.toDouble() ?? 0,
              'code': fd['weathercode']?[i] ?? 0,
            });
          }
        }

        // Toprak pH
        if (results[2].statusCode == 200) {
          final val = jsonDecode(results[2].body)['properties']?['layers']?[0]
              ?['depths']?[0]?['values']?['mean'];
          if (val != null) ph = (val as num).toDouble() / 10.0;
        }
      } catch (_) {}

      String phComment = '';
      if (ph < 5.5) {
        phComment =
            "⚠️ Toprağınız çok asidik (pH ${ph.toStringAsFixed(1)}). Kireçleme gerekebilir.";
      } else if (ph > 7.5) {
        phComment =
            "⚠️ Toprağınız bazik (pH ${ph.toStringAsFixed(1)}). Elementel kükürt uygulaması düşünebilirsiniz.";
      } else {
        phComment =
            "✅ Toprak pH'ınız (${ph.toStringAsFixed(1)}) ideal aralıktadır.";
      }

      String scaleComment = scale == 'Profesyonel'
          ? "🚜 **Profesyonel Ölçek:** Tarlada sıra arası mesafelere, bölgeye uygun damla sulama sistemlerine ve taban gübresi uygulamalarına dikkat edilmelidir."
          : "🏡 **Hobi Bahçesi:** Drenajı iyi olan topraklar kullanın, doğrudan güneş alan bir konuma yerleştirin ve kök çürümesini önlemek için aşırı sulamadan kaçının.";

      // --- 2. FIRESTORE'DA ARAMA YAP (ANA VERİTABANI) ---
      final docRef =
          FirebaseFirestore.instance.collection('crops').doc(normalizedQuery);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        final data = docSnap.data()!;

        // Firestore verisini cropData formatına dönüştür
        final cropData = {
          'scientific': data["scientific"] ?? "Bilinmiyor",
          'desc': data["desc"] ?? "",
          'cycle': data["cycle"] ?? "Bilinmiyor",
          'sunlight': data["sunlight"] ?? "Bilinmiyor",
          'growth': data["growth"] ?? "Bilinmiyor",
          'care': data["care"] ?? "Bilinmiyor",
          'indoor': data["indoor"] ?? false,
          'drought': data["drought"] ?? false,
          'pruning': data["pruning"] ?? "Yok",
          'pests': data["pests"] ?? "Genel zararlı kontrolü yapın.",
          'ideal_temp_min': data["ideal_temp_min"] ?? 15,
          'ideal_temp_max': data["ideal_temp_max"] ?? 30,
          'ideal_ph_min': data["ideal_ph_min"] ?? 5.5,
          'ideal_ph_max': data["ideal_ph_max"] ?? 7.0,
          'sunlight_hours': data["sunlight_hours"] ?? 8,
          'harvest_days': data["harvest_days"] ?? 90,
          'best_planting_months': data["best_planting_months"] ?? "",
          'companion_plants': data["companion_plants"] ?? "",
          'avoid_plants': data["avoid_plants"] ?? "",
          'pest_prevention': data["pest_prevention"] ?? "",
          'region_uygunluk': data["region_uygunluk"] ?? 70,
          'region_note': data["region_note"] ?? "",
          'daily_water_liters_per_plant': data["daily_water_liters_per_plant"] ?? 2.0,
          'fertilizer_schedule': data["fertilizer_schedule"] ?? "",
          'planting_tip': data["planting_tip"] ?? "",
        };

        return {
          'success': true,
          'cropData': cropData,
          'weeklyForecast': weeklyForecast,
          'weeklyWaterPlan': [],
          'envData': {
            'temp': temp,
            'ph': ph,
            'humidity': hum,
            'location': locationName,
            'phComment': phComment,
            'scaleComment': scaleComment,
          },
          'plantingData': {
            'depth_cm': data["planting_depth_cm"] ?? 3,
            'row_spacing_cm': data["row_spacing_cm"] ?? 50,
            'plant_spacing_cm': data["plant_spacing_cm"] ?? 40,
            'seeds_per_dekar': data["seeds_per_dekar"] ?? 500,
            'irrigation_type': data["irrigation_type"] ?? "Damla Sulama",
            'irrigation_line_spacing_cm': data["irrigation_line_spacing_cm"] ?? 70,
            'irrigation_dripper_spacing_cm': data["irrigation_dripper_spacing_cm"] ?? 30,
            'fertilizer_band_cm': data["fertilizer_band_cm"] ?? 15,
            'fertilizer_depth_cm': data["fertilizer_depth_cm"] ?? 10,
            'fertilizer_type': data["fertilizer_type"] ?? "NPK 15-15-15",
            'daily_water_liters': data["daily_water_liters_per_plant"] ?? 2.0,
            'fertilizer_schedule': data["fertilizer_schedule"] ?? "",
          },
          'locationInfo':
              '🌡️ $temp°C | 🌿 pH: ${ph.toStringAsFixed(1)} | 💧 Nem: %${hum.toStringAsFixed(0)}',
        };
      }

      // --- 3. FIRESTORE'DA YOKSA OfflineEncyclopedia + statik varsayılanlar ---
      final encData = OfflineEncyclopedia.getByName(query) ?? {};

      final data = <String, dynamic>{
        'scientific': encData['scientific_name'] ?? query,
        'desc': encData['care_description'] ?? '$query bitkisi hakkında bilgi bulunamadı.',
        'cycle': encData['cycle'] ?? 'Bilinmiyor',
        'sunlight': encData['sunlight'] ?? 'Full Sun',
        'growth': encData['growth_rate'] ?? 'Moderate',
        'care': encData['care_level'] ?? 'Medium',
        'indoor': false,
        'drought': encData['drought_tolerant'] ?? false,
        'ideal_temp_min': encData['ideal_temp_min'] ?? 15,
        'ideal_temp_max': encData['ideal_temp_max'] ?? 30,
        'ideal_ph_min': encData['ideal_ph_min'] ?? 5.5,
        'ideal_ph_max': encData['ideal_ph_max'] ?? 7.0,
        'sunlight_hours': 8,
        'harvest_days': encData['harvest_days'] ?? 90,
        'best_planting_months': encData['best_planting_months'] ?? 'Nisan, Mayıs',
        'companion_plants': encData['companion_plants'] ?? '',
        'avoid_plants': encData['avoid_plants'] ?? '',
        'pruning': encData['pruning_month'] ?? 'Yok',
        'pests': encData['pest_susceptibility'] ?? 'Genel zararlı takibi yapın.',
        'pest_prevention': 'Düzenli kontrol ve önleyici ilaçlama.',
        'planting_depth_cm': encData['depth_cm'] ?? 3,
        'row_spacing_cm': encData['row_spacing_cm'] ?? 50,
        'plant_spacing_cm': encData['plant_spacing_cm'] ?? 40,
        'seeds_per_dekar': encData['seeds_per_dekar'] ?? 500,
        'planting_tip': 'Sabah erken saatlerde ekim yapın.',
        'irrigation_type': encData['irrigation_type'] ?? 'Damla Sulama',
        'irrigation_line_spacing_cm': 70,
        'irrigation_dripper_spacing_cm': 30,
        'daily_water_liters_per_plant': 2.5,
        'fertilizer_band_cm': 15,
        'fertilizer_depth_cm': 10,
        'fertilizer_type': 'NPK 15-15-15',
        'fertilizer_schedule': 'Ekimden 2 hafta sonra azot gübresi, çiçeklenme öncesi fosfor.',
        'weekly_water_plan': [],
        'region_uygunluk': 70,
        'region_note': 'Bölge koşulları genel olarak bu bitki için uygundur.',
      };

      return {
        'success': true,
        'cropData': data,
        'plantingData': {
          'depth_cm': data["planting_depth_cm"],
          'row_spacing_cm': data["row_spacing_cm"],
          'plant_spacing_cm': data["plant_spacing_cm"],
          'seeds_per_dekar': data["seeds_per_dekar"],
          'irrigation_type': data["irrigation_type"],
          'irrigation_line_spacing_cm': data["irrigation_line_spacing_cm"],
          'irrigation_dripper_spacing_cm': data["irrigation_dripper_spacing_cm"],
          'fertilizer_band_cm': data["fertilizer_band_cm"],
          'fertilizer_depth_cm': data["fertilizer_depth_cm"],
          'fertilizer_type': data["fertilizer_type"],
          'daily_water_liters': data["daily_water_liters_per_plant"],
          'fertilizer_schedule': data["fertilizer_schedule"],
        },
        'weeklyWaterPlan': [],
        'weeklyForecast': weeklyForecast,
        'envData': {
          'temp': temp,
          'ph': ph,
          'humidity': hum,
          'location': locationName,
          'phComment': phComment,
          'scaleComment': scaleComment,
        },
        'locationInfo':
            '🌡️ $temp°C | 🌿 pH: ${ph.toStringAsFixed(1)} | 💧 Nem: %${hum.toStringAsFixed(0)}',
      };
    } catch (e) {
      return {
        'success': false,
        'guide':
            'Ağ hatası veya veri çekilemedi. İnternetinizi kontrol edin.\n\nHata: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // UYDU HAVA DURUMU (NASA POWER + Open-Meteo ERA5)
  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getSatelliteWeather(
    double latitude,
    double longitude,
  ) async {
    // Varsayılan değerler
    double currentTemp = 0;
    double currentHumidity = 0;
    double currentWind = 0;
    double currentPrecip = 0;
    double currentCloudCover = 0;
    double currentPressure = 0;
    int weatherCode = 0;
    List<Map<String, dynamic>> dailyForecast = [];

    double nasaSolar = 0; // MJ/m²/gün — uydu güneş radyasyonu
    double nasaTemp = 0;
    double nasaHumidity = 0;
    double nasaWind = 0;
    double nasaPrecip = 0;
    String nasaDate = '';
    bool nasaSuccess = false;

    List<Map<String, dynamic>> hourlyForecast = [];

    // Open-Meteo anlık + saatlik + 7 günlük tahmin (ERA5 tabanlı)
    try {
      final omRes = await http
          .get(Uri.parse(
            'https://api.open-meteo.com/v1/forecast'
            '?latitude=$latitude&longitude=$longitude'
            '&current=temperature_2m,relative_humidity_2m,precipitation'
            ',wind_speed_10m,cloud_cover,surface_pressure,weather_code'
            '&hourly=temperature_2m,precipitation_probability,weather_code'
            ',wind_speed_10m,relative_humidity_2m'
            '&daily=temperature_2m_max,temperature_2m_min,precipitation_sum'
            ',uv_index_max,wind_speed_10m_max'
            '&forecast_days=7&timezone=auto',
          ))
          .timeout(const Duration(seconds: 10));
      if (omRes.statusCode == 200) {
        final omData = jsonDecode(omRes.body);
        final cur = omData['current'];
        currentTemp = (cur['temperature_2m'] as num).toDouble();
        currentHumidity = (cur['relative_humidity_2m'] as num).toDouble();
        currentWind = (cur['wind_speed_10m'] as num).toDouble();
        currentPrecip = (cur['precipitation'] as num).toDouble();
        currentCloudCover = (cur['cloud_cover'] as num).toDouble();
        currentPressure = (cur['surface_pressure'] as num).toDouble();
        weatherCode = (cur['weather_code'] as num).toInt();

        // Saatlik veri — şu andan itibaren 24 saat
        final hourly = omData['hourly'];
        final hTimes = hourly['time'] as List;
        final hTemps = hourly['temperature_2m'] as List;
        final hPrecipProb = hourly['precipitation_probability'] as List;
        final hCodes = hourly['weather_code'] as List;
        final hWind = hourly['wind_speed_10m'] as List;
        final hHumidity = hourly['relative_humidity_2m'] as List;
        final nowHour = DateTime.now().hour;
        int start = 0;
        for (int i = 0; i < hTimes.length; i++) {
          final t = hTimes[i] as String; // "2025-03-31T14:00"
          if (t.length >= 13) {
            final h = int.tryParse(t.substring(11, 13)) ?? 0;
            final isToday = t.startsWith(
                DateTime.now().toIso8601String().substring(0, 10));
            if (isToday && h >= nowHour) {
              start = i;
              break;
            }
          }
        }
        for (int i = start; i < start + 24 && i < hTimes.length; i++) {
          hourlyForecast.add({
            'time': hTimes[i] as String,
            'temp': (hTemps[i] as num).toDouble(),
            'precip_prob': (hPrecipProb[i] as num).toInt(),
            'code': (hCodes[i] as num).toInt(),
            'wind': (hWind[i] as num).toDouble(),
            'humidity': (hHumidity[i] as num).toInt(),
          });
        }

        final daily = omData['daily'];
        final dates = daily['time'] as List;
        final maxT = daily['temperature_2m_max'] as List;
        final minT = daily['temperature_2m_min'] as List;
        final rain = daily['precipitation_sum'] as List;
        final uv = daily['uv_index_max'] as List;
        final windMax = daily['wind_speed_10m_max'] as List;
        for (int i = 0; i < dates.length; i++) {
          dailyForecast.add({
            'date': dates[i] as String,
            'max': (maxT[i] as num).toDouble(),
            'min': (minT[i] as num).toDouble(),
            'rain': (rain[i] as num).toDouble(),
            'uv': uv[i] != null ? (uv[i] as num).toDouble() : 0.0,
            'wind_max': (windMax[i] as num).toDouble(),
          });
        }
      }
    } catch (_) {}

    // NASA POWER API — uydu kaynaklı tarımsal meteoroloji
    // (1-3 günlük gecikme nedeniyle 3 gün öncesinin verisi alınır)
    try {
      final now = DateTime.now().subtract(const Duration(days: 3));
      final dateStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final nasaRes = await http
          .get(Uri.parse(
            'https://power.larc.nasa.gov/api/temporal/daily/point'
            '?parameters=T2M,T2M_MAX,T2M_MIN,PRECTOTCORR,RH2M,WS2M,ALLSKY_SFC_SW_DWN'
            '&community=AG'
            '&longitude=$longitude&latitude=$latitude'
            '&start=$dateStr&end=$dateStr'
            '&format=JSON',
          ))
          .timeout(const Duration(seconds: 15));
      if (nasaRes.statusCode == 200) {
        final nasaData = jsonDecode(nasaRes.body);
        final props = nasaData['properties']?['parameter'];
        if (props != null) {
          nasaTemp = (props['T2M']?[dateStr] as num?)?.toDouble() ?? 0;
          nasaHumidity = (props['RH2M']?[dateStr] as num?)?.toDouble() ?? 0;
          nasaWind = (props['WS2M']?[dateStr] as num?)?.toDouble() ?? 0;
          nasaPrecip =
              (props['PRECTOTCORR']?[dateStr] as num?)?.toDouble() ?? 0;
          nasaSolar =
              (props['ALLSKY_SFC_SW_DWN']?[dateStr] as num?)?.toDouble() ?? 0;
          nasaDate =
              '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
          nasaSuccess = nasaTemp != 0 || nasaSolar != 0;
        }
      }
    } catch (_) {}

    // Agromonitoring toprak nemi (uydu destekli)
    double soilMoisture = 0;
    double soilTempC = 0;
    try {
      final agroData = await _getAgroSoilData(latitude, longitude);
      if (agroData != null) {
        soilMoisture = agroData['moisture'] ?? 0.0;
        soilTempC = agroData['soil_temp_c'] ?? 0.0;
      }
    } catch (_) {}

    return {
      'success': true,
      'current_temp': currentTemp,
      'current_humidity': currentHumidity,
      'current_wind': currentWind,
      'current_precip': currentPrecip,
      'current_cloud_cover': currentCloudCover,
      'current_pressure': currentPressure,
      'weather_code': weatherCode,
      'daily_forecast': dailyForecast,
      'hourly_forecast': hourlyForecast,
      'nasa_solar': nasaSolar,
      'nasa_temp': nasaTemp,
      'nasa_humidity': nasaHumidity,
      'nasa_wind': nasaWind,
      'nasa_precip': nasaPrecip,
      'nasa_date': nasaDate,
      'nasa_success': nasaSuccess,
      'soil_moisture': soilMoisture,
      'soil_temp_c': soilTempC,
    };
  }

  // ═══════════════════════════════════════════════════
  // SAATLİK HAVA (field_detail_screen için hafif çağrı)
  // ═══════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getHourlyWeather(
    double latitude,
    double longitude,
  ) async {
    try {
      final res = await http
          .get(Uri.parse(
            'https://api.open-meteo.com/v1/forecast'
            '?latitude=$latitude&longitude=$longitude'
            '&hourly=temperature_2m,precipitation_probability,weather_code'
            ',wind_speed_10m,relative_humidity_2m'
            '&forecast_days=2&timezone=auto',
          ))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body)['hourly'];
      final times = data['time'] as List;
      final temps = data['temperature_2m'] as List;
      final precip = data['precipitation_probability'] as List;
      final codes = data['weather_code'] as List;
      final wind = data['wind_speed_10m'] as List;
      final hum = data['relative_humidity_2m'] as List;

      final nowStr = DateTime.now().toIso8601String().substring(0, 13);
      final List<Map<String, dynamic>> result = [];
      for (int i = 0; i < times.length; i++) {
        // Sadece şu andan itibaren 24 saati al
        final t = times[i] as String;
        if (t.substring(0, 13).compareTo(nowStr) >= 0 &&
            result.length < 24) {
          result.add({
            'time': t,
            'temp': (temps[i] as num).toDouble(),
            'precip_prob': (precip[i] as num).toInt(),
            'code': (codes[i] as num).toInt(),
            'wind': (wind[i] as num).toDouble(),
            'humidity': (hum[i] as num).toInt(),
          });
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WMO weather code → Türkçe kısa açıklama
// (Open-Meteo weather_code; OpenWeatherMap "description" alanının karşılığı)
// ─────────────────────────────────────────────────────────────────────────────
String _wmoCodeToTr(int code) {
  if (code == 0) return 'açık';
  if (code == 1) return 'az bulutlu';
  if (code == 2) return 'parçalı bulutlu';
  if (code == 3) return 'kapalı';
  if (code == 45 || code == 48) return 'sisli';
  if (code >= 51 && code <= 57) return 'çisenti';
  if (code >= 61 && code <= 67) return 'yağmurlu';
  if (code >= 71 && code <= 77) return 'karlı';
  if (code >= 80 && code <= 82) return 'sağanak';
  if (code >= 85 && code <= 86) return 'kar sağanağı';
  if (code >= 95) return 'gök gürültülü fırtına';
  return '';
}
