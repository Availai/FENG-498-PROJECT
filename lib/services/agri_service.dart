import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'crop_rules.dart';
import 'backend_service.dart';
import 'offline_encyclopedia.dart';
import 'plant_cache_service.dart';
import '../utils/image_compressor.dart';
import '../data/turkiye_crop_guides.dart';

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
  static const Duration _optionalBackendTimeout = Duration(seconds: 3);

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

      final tagNames = await _backendImageTags(imageFile);
      final plantKeywords = <String>{
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
      };
      final fieldKeywords = <String>{
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
      };
      final isPlant = tagNames.any(plantKeywords.contains);
      final isField = tagNames.any(fieldKeywords.contains);

      final env = await BackendService.fieldEnvironment(
        lat: latitude,
        lng: longitude,
      );
      final numericTemp = (env?['temp'] as num?)?.toDouble() ?? 20.0;
      final numericPh = (env?['ph'] as num?)?.toDouble() ?? 6.5;
      final avgWeeklyTemp =
          (env?['avg_weekly_temp'] as num?)?.toDouble() ?? numericTemp;
      final totalWeeklyRain =
          (env?['total_weekly_rain'] as num?)?.toDouble() ?? 0.0;
      final numericHumidity = (env?['humidity'] as num?)?.toDouble() ?? 50.0;
      final agroData = await _getAgroSoilData(latitude, longitude);
      final soilMoisture = (agroData?['moisture'] as num?)?.toDouble() ?? 0.0;
      final soilTempC = (agroData?['soil_temp_c'] as num?)?.toDouble() ?? 15.0;

      if (!isPlant && !isField) {
        final report = await _generateEnvironmentalReport(
          temp: numericTemp,
          humidity: numericHumidity,
          weeklyRain: totalWeeklyRain,
          ph: numericPh,
          soilMoisture: soilMoisture,
          soilTempC: soilTempC,
          month: DateTime.now().month,
        );
        return {
          'type': 'plant',
          'data': {
            'title': 'Bölgesel Çevre Raporu',
            'description':
                'Fotoğraf tarımsal bir içerik değil gibi görünüyor. $report',
          },
        };
      }

      if (isPlant) {
        final jpegFile = await ImageCompressor.compressToJpeg(imageFile);
        final firstRound = await Future.wait([
          _callPlantNet(jpegFile),
          _callGeminiDiseaseCheck(jpegFile, '', ''),
        ]);
        final plantNetResult = firstRound[0] as _PlantNetResult;
        var disease = firstRound[1] as _DiseaseResult;
        final plantIdentified = plantNetResult.ok &&
            plantNetResult.data?['results'] != null &&
            (plantNetResult.data!['results'] as List).isNotEmpty;

        if (plantIdentified) {
          final bestMatch = plantNetResult.data!['results'][0];
          final species = bestMatch['species'] as Map<String, dynamic>;
          final scientificName =
              species['scientificNameWithoutAuthor']?.toString() ?? '';
          final familyName =
              species['family']?['scientificNameWithoutAuthor']?.toString() ??
                  '';
          final names = (species['commonNames'] as List?) ?? const [];
          final commonTitle = names.isNotEmpty
              ? names.first.toString()
              : (scientificName.isNotEmpty ? scientificName : 'Bitki');
          final confidence =
              ((bestMatch['score'] as num?) ?? 0).toDouble() * 100;
          final detailsFromCache =
              await PlantCacheService.get(scientificName) != null;
          final secondRound = await Future.wait([
            _fetchPerenualDetails(scientificName, commonTitle),
            disease.analyzed
                ? Future.value(disease)
                : _callGeminiDiseaseCheck(
                    jpegFile, scientificName, commonTitle),
          ]);
          final perenualDetails = secondRound[0] as Map<String, dynamic>;
          disease = secondRound[1] as _DiseaseResult;

          return {
            'type': 'plant',
            'data': {
              'title': disease.analyzed && disease.present
                  ? '$commonTitle — ${disease.name}'
                  : commonTitle,
              'scientific_name': scientificName,
              'description':
                  'Botanik teşhis (%${confidence.toStringAsFixed(0)} güvenilirlik) — ${detailsFromCache ? 'önbellekten' : 'backend tabanlı'} analiz',
              'from_cache': detailsFromCache,
              'disease_analyzed': disease.analyzed,
              'disease_present': disease.present,
              'disease_name': disease.name,
              'disease_confidence': disease.confidence,
              'severity': disease.severity,
              'symptoms': disease.symptoms,
              'treatment': disease.treatment,
              'disease_failure_reason': disease.failureReason,
              'plant_details': {
                'family': familyName,
                'halk_dilindeki_adi':
                    perenualDetails['other_names'] ?? commonTitle,
                'basari_sansi': _calculateSuccessRate(
                  avgWeeklyTemp,
                  numericPh,
                  totalWeeklyRain,
                  numericHumidity,
                  perenualDetails,
                ),
                'konum_yorumu': _generateLocationComment(
                  avgWeeklyTemp,
                  numericPh,
                  totalWeeklyRain,
                  numericHumidity,
                  soilMoisture,
                  soilTempC,
                  perenualDetails,
                ),
                'nasil_yetistirilir': perenualDetails['care_description'] ??
                    _buildGrowGuide(perenualDetails),
                'bakim_puf_noktasi': _buildCareGuide(perenualDetails),
                'hastalik_riskleri': perenualDetails['pest_susceptibility'] ??
                    perenualDetails['pest_info'] ??
                    'Zararlı bilgisi bulunamadı.',
                'sulama_takvimi': _generateWateringSchedule(
                  totalWeeklyRain,
                  numericHumidity,
                  perenualDetails,
                ),
                'gubre_onerisi':
                    _generateFertilizerAdvice(numericPh, perenualDetails),
                'hasat_zamani': _buildHarvestInfo(perenualDetails),
                'depolama_saklama': _buildStorageInfo(perenualDetails),
              },
            },
          };
        }

        final report = await _generateEnvironmentalReport(
          temp: numericTemp,
          humidity: numericHumidity,
          weeklyRain: totalWeeklyRain,
          ph: numericPh,
          soilMoisture: soilMoisture,
          soilTempC: soilTempC,
          month: DateTime.now().month,
        );
        return {
          'type': 'plant',
          'data': {
            'title': disease.analyzed && disease.present
                ? 'Hasta Bitki — ${disease.name}'
                : 'Bölgesel Bitki Raporu',
            'description':
                'Kesin tür tespiti yapılamadı. Etiketler: ${tagNames.take(3).join(', ')}. $report',
            'from_cache': false,
            'disease_analyzed': disease.analyzed,
            'disease_present': disease.present,
            'disease_name': disease.name,
            'disease_confidence': disease.confidence,
            'severity': disease.severity,
            'symptoms': disease.symptoms,
            'treatment': disease.treatment,
            'disease_failure_reason': disease.failureReason,
          },
        };
      }

      final recommendations = await CropRules.getDynamicRecommendations(
        numericTemp,
        numericPh,
        avgWeeklyTemp,
        totalWeeklyRain,
        soilMoisture: soilMoisture,
        soilTempC: soilTempC,
      );

      return {
        'type': 'field',
        'data': {
          'title': 'Ayrıntılı Ziraat Raporu',
          'description':
              'pH: ${numericPh.toStringAsFixed(1)} | Ort. sıcaklık: ${avgWeeklyTemp.toStringAsFixed(1)}°C | Yağış: ${totalWeeklyRain.toStringAsFixed(1)} mm | Nem: %${numericHumidity.toStringAsFixed(0)} | Toprak nem: %${(soilMoisture * 100).toStringAsFixed(1)}',
          'crops': recommendations,
        },
      };
    } on SocketException catch (e) {
      return {
        'type': 'error',
        'data': {
          'message':
              'İnternet bağlantısı kesildi veya backend sunucusuna ulaşılamadı. (${e.osError?.message ?? e.message})',
        },
      };
    } on TimeoutException {
      return {
        'type': 'error',
        'data': {'message': 'Backend yanıt vermedi. Lütfen tekrar deneyin.'},
      };
    } catch (e) {
      return {
        'type': 'error',
        'data': {'message': 'Analiz başarısız oldu: $e'},
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // PLANTNET API — timeout + 1 retry + hata sınıflandırma
  // ═══════════════════════════════════════════════════
  static Future<List<String>> _backendImageTags(File imageFile) async {
    try {
      return await BackendService.imaggaTags(imageFile);
    } catch (_) {
      return const [];
    }
  }

  static Future<_PlantNetResult> _callPlantNet(File jpegFile) async {
    for (var i = 0; i < 2; i++) {
      try {
        final data = await BackendService.plantNetIdentify(jpegFile);
        return _PlantNetResult.ok(data);
      } on BackendException catch (e) {
        if (e.statusCode == 429) {
          return _PlantNetResult.fail('günlük kota dolu');
        }
        if (e.statusCode == 401 || e.statusCode == 403) {
          return _PlantNetResult.fail('yetki reddedildi');
        }
        if (i == 1) return _PlantNetResult.fail(e.message);
      } on TimeoutException {
        if (i == 1) return _PlantNetResult.fail('zaman aşımı');
      } on SocketException {
        if (i == 1) return _PlantNetResult.fail('bağlantı kurulamadı');
      } catch (e) {
        if (i == 1) return _PlantNetResult.fail('bilinmeyen hata');
      }
      await Future.delayed(const Duration(seconds: 2));
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
  static Future<_DiseaseResult> _callGeminiDiseaseCheck(
    File jpegFile,
    String scientificName,
    String commonName,
  ) async {
    File analysisFile;
    try {
      analysisFile = await ImageCompressor.compressToJpeg(
        jpegFile,
        maxDimension: 960,
        quality: 80,
      );
    } catch (_) {
      analysisFile = jpegFile;
    }

    try {
      final response = await BackendService.geminiDiagnose(
        imageBytes: await analysisFile.readAsBytes(),
        scientificName: scientificName,
        commonName: commonName,
      );
      final parsed = _parseGeminiResponse(jsonEncode(response['data']));
      if (parsed != null) return parsed;
      return _DiseaseResult.unknown('yanıt çözümlenemedi');
    } on BackendException catch (e) {
      return _DiseaseResult.unknown(e.message);
    } on TimeoutException {
      return _DiseaseResult.unknown('zaman aşımı');
    } on SocketException {
      return _DiseaseResult.unknown('bağlantı kurulamadı');
    } catch (_) {
      return _DiseaseResult.unknown('servis yanıt vermedi');
    }
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

      final bool present = parsedJson['disease_present'] == true ||
          parsedJson['present'] == true;
      final int rawConf = ((parsedJson['disease_confidence'] ??
                  parsedJson['confidence']) as num?)
              ?.toInt() ??
          0;
      return _DiseaseResult(
        analyzed: true,
        present: present,
        name: (parsedJson['disease_name'] ?? parsedJson['name'] ?? '')
            .toString()
            .trim(),
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

  // ═══════════════════════════════════════════════════
  // PERENUAL API — Bitki Detaylarını Çek
  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> _fetchPerenualDetails(
    String scientificName,
    String commonName,
  ) async {
    final cached = await PlantCacheService.get(scientificName);
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final result = await BackendService.plantDetails(
        commonName: commonName,
        scientificName: scientificName,
      );
      if (result.isNotEmpty) {
        PlantCacheService.save(scientificName, result);
        return result;
      }
    } catch (_) {}

    final enc = OfflineEncyclopedia.getByName(commonName);
    if (enc != null && enc.isNotEmpty) {
      PlantCacheService.save(scientificName, enc);
      return enc;
    }
    return {};
  }

  // ═══════════════════════════════════════════════════
  // AGROMONITORING API — Toprak Verisi
  // ═══════════════════════════════════════════════════
  static Future<Map<String, double>?> _getAgroSoilData(
    double lat,
    double lng,
  ) async {
    return BackendService.satelliteSoil(lat: lat, lng: lng);
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
  static Future<String> _generateEnvironmentalReport({
    required double temp,
    required double humidity,
    required double weeklyRain,
    required double ph,
    required double soilMoisture,
    required double soilTempC,
    required int month,
  }) async {
    final body = {
      'temp': temp,
      'humidity': humidity,
      'weekly_rain': weeklyRain,
      'ph': ph,
      'soil_moisture': soilMoisture,
      'soil_temp_c': soilTempC,
      'month': month,
    };
    return await BackendService.analyzeEnvironmentalReport(body) ??
        _localEnvironmentalReport(
          temp: temp,
          humidity: humidity,
          weeklyRain: weeklyRain,
          ph: ph,
          soilMoisture: soilMoisture,
          soilTempC: soilTempC,
        );
  }

  static String _localEnvironmentalReport({
    required double temp,
    required double humidity,
    required double weeklyRain,
    required double ph,
    required double soilMoisture,
    required double soilTempC,
  }) {
    final notes = <String>[];
    if (temp < 3) notes.add('Don riski var, gece koruması planlayın.');
    if (temp > 34) notes.add('Sıcak stresine karşı sabah erken sulama yapın.');
    if (weeklyRain < 5) notes.add('Yağış az, sulama ihtiyacı yüksek.');
    if (weeklyRain > 50) {
      notes.add('Aşırı yağışta drenaj ve mantar riski izlenmeli.');
    }
    if (ph < 5.8) notes.add('Toprak asidik, kireçleme gerekebilir.');
    if (ph > 7.6) {
      notes.add('Toprak bazik, kükürt ve organik madde desteği düşünülmeli.');
    }
    if (notes.isEmpty) notes.add('Koşullar genel olarak dengeli görünüyor.');
    return 'Sıcaklık ${temp.toStringAsFixed(1)}°C, nem %${humidity.toStringAsFixed(0)}, '
        'haftalık yağış ${weeklyRain.toStringAsFixed(1)} mm, pH ${ph.toStringAsFixed(1)}, '
        'toprak nemi %${(soilMoisture * 100).toStringAsFixed(0)}, '
        'toprak sıcaklığı ${soilTempC.toStringAsFixed(1)}°C. ${notes.join(' ')}';
  }

  static Future<String> _generateFieldPlanText({
    required String plantName,
    required String fieldName,
    required double ph,
    required double avgTemp,
    required double totalRain,
    required double areaDekar,
    required int month,
    required Map<String, dynamic> plantDetails,
  }) async {
    final body = {
      'plant_name': plantName,
      'field_name': fieldName,
      'ph': ph,
      'avg_temp': avgTemp,
      'total_rain': totalRain,
      'area_dekar': areaDekar,
      'month': month,
      'plant_details': plantDetails,
    };
    final backendText = await BackendService.analyzeFieldPlan(body).timeout(
      _optionalBackendTimeout,
      onTimeout: () => null,
    );
    return backendText ??
        _localFieldPlan(
          plantName: plantName,
          fieldName: fieldName,
          ph: ph,
          avgTemp: avgTemp,
          totalRain: totalRain,
          areaDekar: areaDekar,
          plantDetails: plantDetails,
        );
  }

  static String _localFieldPlan({
    required String plantName,
    required String fieldName,
    required double ph,
    required double avgTemp,
    required double totalRain,
    required double areaDekar,
    required Map<String, dynamic> plantDetails,
  }) {
    final rowSpacing = plantDetails['row_spacing_cm'] ?? 60;
    final plantSpacing = plantDetails['plant_spacing_cm'] ?? 40;
    final seedsPerDekar =
        (plantDetails['seeds_per_dekar'] as num?)?.toInt() ?? 500;
    final seedCount = (seedsPerDekar * areaDekar.clamp(0.1, 10000)).round();
    return '$fieldName için $plantName ekim planı: ortalama sıcaklık '
        '${avgTemp.toStringAsFixed(1)}°C, haftalık yağış ${totalRain.toStringAsFixed(1)} mm, '
        'pH ${ph.toStringAsFixed(1)}. Sıra arası $rowSpacing cm, bitki arası '
        '$plantSpacing cm bırakın. Yaklaşık $seedCount tohum/fide hazırlayın. '
        'İlk hafta toprağı tavında tutun ve yağışa göre sulamayı ayarlayın.';
  }

  static Future<String> _generateWeeklyComment({
    required String fieldName,
    required double temp,
    required double humidity,
    required double wind,
    required double ph,
    required double avgTemp,
    required double totalWeeklyRain,
    required double soilMoisture,
    required double soilTempC,
    required int month,
    required List<Map<String, dynamic>> crops,
  }) async {
    final body = {
      'field_name': fieldName,
      'temp': temp,
      'humidity': humidity,
      'wind': wind,
      'ph': ph,
      'avg_temp': avgTemp,
      'total_weekly_rain': totalWeeklyRain,
      'soil_moisture': soilMoisture,
      'soil_temp_c': soilTempC,
      'month': month,
      'crops': crops,
    };
    final backendText = await BackendService.analyzeWeeklyComment(body).timeout(
      _optionalBackendTimeout,
      onTimeout: () => null,
    );
    return backendText ??
        _localWeeklyComment(
          fieldName: fieldName,
          temp: temp,
          humidity: humidity,
          wind: wind,
          ph: ph,
          totalWeeklyRain: totalWeeklyRain,
          crops: crops,
        );
  }

  static String _localWeeklyComment({
    required String fieldName,
    required double temp,
    required double humidity,
    required double wind,
    required double ph,
    required double totalWeeklyRain,
    required List<Map<String, dynamic>> crops,
  }) {
    final bestCrop = crops.isNotEmpty ? crops.first['name']?.toString() : null;
    final notes = <String>[
      '$fieldName için haftalık yerel değerlendirme hazır.',
      'Sıcaklık ${temp.toStringAsFixed(1)}°C, nem %${humidity.toStringAsFixed(0)}, rüzgar ${wind.toStringAsFixed(1)} m/sn.',
      'pH ${ph.toStringAsFixed(1)}, haftalık yağış ${totalWeeklyRain.toStringAsFixed(1)} mm.',
    ];
    if (bestCrop != null && bestCrop.isNotEmpty) {
      notes.add('En uygun ürün adayı: $bestCrop.');
    }
    if (totalWeeklyRain < 5) notes.add('Sulama programını öne alın.');
    if (totalWeeklyRain > 45) notes.add('Drenaj ve hastalık takibi yapın.');
    return notes.join(' ');
  }

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
    return await _generateFieldPlanText(
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
    // Bağımsız iki ağ çağrısını PARALEL başlat; agroSoil opsiyonel —
    // bekletmemek için kendi 6s timeout'u var (BackendService).
    final envFuture = BackendService.fieldEnvironment(
      lat: latitude,
      lng: longitude,
    ).timeout(_optionalBackendTimeout, onTimeout: () => null);
    final agroFuture = _getAgroSoilData(latitude, longitude)
        .timeout(_optionalBackendTimeout, onTimeout: () => null);
    final env = await envFuture;
    final agroData = await agroFuture;

    final numericTemp = (env?['temp'] as num?)?.toDouble() ?? 20.0;
    final numericHumidity = (env?['humidity'] as num?)?.toDouble() ?? 50.0;
    final numericWind = (env?['wind'] as num?)?.toDouble() ?? 0.0;
    final numericPh = (env?['ph'] as num?)?.toDouble() ?? 6.5;
    final weatherDesc = env?['weather_desc']?.toString() ?? '';
    final avgWeeklyTemp =
        (env?['avg_weekly_temp'] as num?)?.toDouble() ?? numericTemp;
    final totalWeeklyRain =
        (env?['total_weekly_rain'] as num?)?.toDouble() ?? 0.0;
    final dailyForecast = ((env?['daily_forecast'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final soilMoisture = (agroData?['moisture'] as num?)?.toDouble() ?? 0.0;
    final soilTempC = (agroData?['soil_temp_c'] as num?)?.toDouble() ?? 0.0;

    final crops = await CropRules.getDynamicRecommendations(
      numericTemp,
      numericPh,
      avgWeeklyTemp,
      totalWeeklyRain,
      soilMoisture: soilMoisture,
      soilTempC: soilTempC,
    );

    final aiWeeklyComment = await _generateWeeklyComment(
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
      'offline_fallback': env == null,
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
  static Map<String, dynamic> _withTurkiyeCropGuide(
    Map<String, dynamic> response,
    TurkiyeCropGuide? guide,
  ) {
    if (guide == null) return response;

    final enriched = Map<String, dynamic>.from(response);
    final cropData = Map<String, dynamic>.from(
      (enriched['cropData'] as Map?) ?? const {},
    )..addAll(guide.cropDataOverrides);
    final plantingData = Map<String, dynamic>.from(
      (enriched['plantingData'] as Map?) ?? const {},
    )..addAll(guide.plantingDataOverrides);

    enriched
      ..['cropData'] = cropData
      ..['plantingData'] = plantingData
      ..['turkiyeGuide'] = guide.toJson()
      ..['sourceRefs'] = guide.sourceRefs
      ..['technicalMetrics'] = guide.technicalMetrics
      ..['growthStages'] = guide.stages.map((stage) => stage.toJson()).toList()
      ..['pestGuides'] = guide.pests.map((pest) => pest.toJson()).toList()
      ..['regionalCalendar'] =
          guide.regionalCalendar.map((region) => region.toJson()).toList()
      ..['rotationNotes'] = guide.rotationNotes
      ..['harvestQualityNotes'] = guide.harvestQualityNotes;

    return enriched;
  }

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
      final turkiyeGuide = TurkiyeCropGuides.lookup(query);
      final env = await BackendService.fieldEnvironment(lat: lat, lng: lng);
      final temp = (env?['temp'] as num?)?.toDouble() ?? 20.0;
      final ph = (env?['ph'] as num?)?.toDouble() ?? 6.8;
      final hum = (env?['humidity'] as num?)?.toDouble() ?? 50.0;
      final weeklyForecast = ((env?['daily_forecast'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final fetched = await _fetchPerenualDetails(query, query);
      final encData = fetched.isNotEmpty
          ? fetched
          : (OfflineEncyclopedia.getByName(query) ?? const <String, dynamic>{});

      final phComment = ph < 5.5
          ? 'Toprak asidik. Ekimden önce kireçleme düşünülmeli.'
          : ph > 7.5
              ? 'Toprak bazik. Organik madde ve kükürt desteği gerekebilir.'
              : 'Toprak pH değeri uygun aralıkta.';
      final scaleComment = scale == 'Profesyonel'
          ? 'Profesyonel ölçekte kayıt, sulama ve gübreleme takibi düzenli tutulmalı.'
          : 'Hobi ölçekte az sayıda fideyle başlayıp düzenli gözlem yapmak yeterlidir.';

      final data = <String, dynamic>{
        'scientific': encData['scientific_name'] ?? query,
        'desc': encData['care_description'] ??
            encData['description'] ??
            '$query bitkisi için çevrimdışı rehber kullanılabilir.',
        'cycle': encData['cycle'] ?? 'Bilinmiyor',
        'sunlight': encData['sunlight'] ?? 'Tam güneş',
        'growth': encData['growth_rate'] ?? 'Orta',
        'care': encData['care_level'] ?? 'Orta',
        'indoor': encData['indoor'] ?? false,
        'drought': encData['drought_tolerant'] ?? false,
        'ideal_temp_min': encData['ideal_temp_min'] ?? 15,
        'ideal_temp_max': encData['ideal_temp_max'] ?? 30,
        'ideal_ph_min': encData['ideal_ph_min'] ?? 5.5,
        'ideal_ph_max': encData['ideal_ph_max'] ?? 7.0,
        'sunlight_hours': 8,
        'harvest_days': encData['harvest_days'] ?? 90,
        'best_planting_months':
            encData['best_planting_months'] ?? 'Nisan, Mayıs',
        'companion_plants': encData['companion_plants'] ?? '',
        'avoid_plants': encData['avoid_plants'] ?? '',
        'pruning': encData['pruning_month'] ?? 'Yok',
        'pests': encData['pest_susceptibility'] ??
            encData['pest_info'] ??
            'Genel zararlı takibi yapın.',
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
        'fertilizer_schedule':
            'Ekimden 2 hafta sonra azot gübresi, çiçeklenme öncesi fosfor.',
        'weekly_water_plan': [],
        'region_uygunluk': 70,
        'region_note': 'Bölge koşulları genel olarak bu bitki için uygundur.',
      };

      return _withTurkiyeCropGuide({
        'success': true,
        'offline_fallback': env == null,
        'cropData': data,
        'plantingData': {
          'depth_cm': data['planting_depth_cm'],
          'row_spacing_cm': data['row_spacing_cm'],
          'plant_spacing_cm': data['plant_spacing_cm'],
          'seeds_per_dekar': data['seeds_per_dekar'],
          'irrigation_type': data['irrigation_type'],
          'irrigation_line_spacing_cm': data['irrigation_line_spacing_cm'],
          'irrigation_dripper_spacing_cm':
              data['irrigation_dripper_spacing_cm'],
          'fertilizer_band_cm': data['fertilizer_band_cm'],
          'fertilizer_depth_cm': data['fertilizer_depth_cm'],
          'fertilizer_type': data['fertilizer_type'],
          'daily_water_liters': data['daily_water_liters_per_plant'],
          'fertilizer_schedule': data['fertilizer_schedule'],
        },
        'weeklyWaterPlan': [],
        'weeklyForecast': weeklyForecast,
        'envData': {
          'temp': temp,
          'ph': ph,
          'humidity': hum,
          'location': 'Bölgeniz',
          'phComment': phComment,
          'scaleComment': scaleComment,
        },
        'locationInfo':
            'Sıcaklık ${temp.toStringAsFixed(1)}°C | pH: ${ph.toStringAsFixed(1)} | Nem: %${hum.toStringAsFixed(0)}',
      }, turkiyeGuide);
    } catch (e) {
      return {
        'success': false,
        'guide':
            'Rehber verisi hazırlanamadı. Çevrimdışı ansiklopediye bakın. Hata: $e',
      };
    }
  }

  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> getSatelliteWeather(
    double latitude,
    double longitude,
  ) async {
    final env = await BackendService.fieldEnvironment(
      lat: latitude,
      lng: longitude,
    );
    final dailyForecast = ((env?['daily_forecast'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hourlyForecast = ((env?['hourly_forecast'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final now = DateTime.now().subtract(const Duration(days: 1));
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final nasa = await BackendService.nasaPowerHistorical(
      lat: latitude,
      lng: longitude,
      startYyyymmdd: dateStr,
      endYyyymmdd: dateStr,
      parameters: 'T2M,PRECTOTCORR,RH2M,WS2M,ALLSKY_SFC_SW_DWN',
    );
    final props = nasa?['properties']?['parameter'];
    final nasaTemp = (props?['T2M']?[dateStr] as num?)?.toDouble() ?? 0.0;
    final nasaHumidity = (props?['RH2M']?[dateStr] as num?)?.toDouble() ?? 0.0;
    final nasaWind = (props?['WS2M']?[dateStr] as num?)?.toDouble() ?? 0.0;
    final nasaPrecip =
        (props?['PRECTOTCORR']?[dateStr] as num?)?.toDouble() ?? 0.0;
    final nasaSolar =
        (props?['ALLSKY_SFC_SW_DWN']?[dateStr] as num?)?.toDouble() ?? 0.0;
    final agroData = await _getAgroSoilData(latitude, longitude);

    return {
      'success': true,
      'offline_fallback': env == null,
      'current_temp': (env?['temp'] as num?)?.toDouble() ?? 0.0,
      'current_humidity': (env?['humidity'] as num?)?.toDouble() ?? 0.0,
      'current_wind': (env?['wind'] as num?)?.toDouble() ?? 0.0,
      'current_precip': (env?['current_precip'] as num?)?.toDouble() ?? 0.0,
      'current_cloud_cover':
          (env?['current_cloud_cover'] as num?)?.toDouble() ?? 0.0,
      'current_pressure': (env?['current_pressure'] as num?)?.toDouble() ?? 0.0,
      'weather_code': (env?['weather_code'] as num?)?.toInt() ?? 0,
      'daily_forecast': dailyForecast,
      'hourly_forecast': hourlyForecast,
      'nasa_solar': nasaSolar,
      'nasa_temp': nasaTemp,
      'nasa_humidity': nasaHumidity,
      'nasa_wind': nasaWind,
      'nasa_precip': nasaPrecip,
      'nasa_date':
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}',
      'nasa_success': nasaTemp != 0 || nasaSolar != 0,
      'soil_moisture': (agroData?['moisture'] as num?)?.toDouble() ?? 0.0,
      'soil_temp_c': (agroData?['soil_temp_c'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ═══════════════════════════════════════════════════
  // SAATLİK HAVA (field_detail_screen için hafif çağrı)
  // ═══════════════════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getHourlyWeather(
    double latitude,
    double longitude,
  ) async {
    return BackendService.hourlyWeather(lat: latitude, lng: longitude);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WMO weather code → Türkçe kısa açıklama
// (Open-Meteo weather_code; OpenWeatherMap "description" alanının karşılığı)
