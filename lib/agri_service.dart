import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'crop_rules.dart';
import 'package:translator/translator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:translator/translator.dart';

class AgriService {
  static String get _plantNetKey => dotenv.env['PLANTNET_API_KEY'] ?? '';
  static String get _imaggaKey => dotenv.env['IMAGGA_API_KEY'] ?? '';
  static String get _imaggaSecret => dotenv.env['IMAGGA_API_SECRET'] ?? '';
  static String get _perenualKey => dotenv.env['PERENUAL_API_KEY'] ?? '';
  static String get _agroKey => dotenv.env['AGROMONITORING_API_KEY'] ?? '';

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
        // 1) Anlık Hava (OpenWeatherMap)
        () async {
          try {
            final weatherKey = dotenv.env['WEATHER_API_KEY'] ?? '';
            final wRes = await http
                .get(Uri.parse(
                  'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherKey&units=metric&lang=tr',
                ))
                .timeout(const Duration(seconds: 8));
            if (wRes.statusCode == 200) {
              final wd = jsonDecode(wRes.body);
              numericTemp = (wd['main']['temp'] as num).toDouble();
              numericHumidity = (wd['main']['humidity'] as num).toDouble();
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
        // ═══ SENARYO C: İLGİSİZ FOTOĞRAF — Gemini Vision + Bölgesel Rapor ═══
        try {
          final model = GenerativeModel(
            model: 'gemini-2.5-pro',
            apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
          );
          final bytes = await imageFile.readAsBytes();
          final prompt = '''
Sen tarım ve çevre analiz asistanısın. Kullanıcı bir fotoğraf yükledi, ancak görüntü sınıflandırıcıları bunun tarımsal bir içerik olmadığını veya bir tarla/bitki olmadığını söylüyor. Lütfen bu fotoğrafla ilgili 1 cümlelik çok kısa bir yorum yap (örn: "Bu bir bilgisayar ekranı gibi görünüyor"). Ardından, sensörlerden gelen alttaki konum verilerini birleştirerek "Ancak bulunduğunuz bölgedeki güncel tarımsal çevre şartları şu şekildedir:" diyerek kullanıcıya o bölgenin toprak ve iklim şartları için detaylıca bir rapor paragrafı sun. (Lütfen Markdown kullanma, direkt ve akıcı bir metin yaz)

Bölge Verileri:
- Ortalama Sıcaklık: $avgWeeklyTemp°C
- Anlık Sıcaklık: $numericTemp°C
- Haftalık Toplam Yağış: $totalWeeklyRain mm
- Ortalama Nem: %$numericHumidity
- Toprak pH: ${numericPh.toStringAsFixed(1)}
- Yüzey Toprak Nemi: %${(soilMoisture * 100).toStringAsFixed(1)}
''';
          final content = [
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', bytes),
            ])
          ];
          final res = await model.generateContent(content);

          return {
            "type": "plant",
            "data": {
              "title": "Görüntü Analizi & Çevre Raporu",
              "description": res.text?.trim() ?? "Çevresel veriler listelendi.",
            }
          };
        } catch (e) {
          // Vision modeli bir şekilde çalışmazsa standart metin döndür
          return {
            "type": "plant",
            "data": {
              "title": "Bölgesel Çevre Raporu",
              "description":
                  "Fotoğraf tarımsal bir içerik değil gibi görünüyor (Etiketler: ${tagNames.take(3).join(', ')}). Ancak bulunduğunuz bölgenin toprak pH'ı ${numericPh.toStringAsFixed(1)} ve sıcaklığı $numericTemp°C civarındadır. Detaylı analiz için daha net bir bitki veya tarla fotoğrafı çekebilirsiniz.",
            }
          };
        }
      } else if (isPlant) {
        // ═══ SENARYO A: BİTKİ — %100 DETERMİNİSTİK (Perenual API) ═══

        // 3A-1: PlantNet ile bitkiyi teşhis et
        var plantNetReq = http.MultipartRequest(
          'POST',
          Uri.parse(
            'https://my-api.plantnet.org/v2/identify/all?api-key=$_plantNetKey',
          ),
        );
        plantNetReq.files.add(
          await http.MultipartFile.fromPath('images', imageFile.path),
        );
        plantNetReq.fields['organs'] = 'auto'; // KESINLIKLE ZORUNLU

        final plantNetRes = await plantNetReq.send();
        final rawResponse = await plantNetRes.stream.bytesToString();
        final plantData = jsonDecode(rawResponse);

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
          double confidence = ((bestMatch['score'] ?? 0) * 100).toDouble();

          // 3A-2: Perenual API ile detaylları çek (LLM YOK — %100 API)
          Map<String, dynamic> perenualDetails =
              await _fetchPerenualDetails(scientificName, commonTitle);

          // 3A-3: Çevresel verilere göre deterministik başarı şansı hesapla
          String basariSansi = _calculateSuccessRate(
            avgWeeklyTemp,
            numericPh,
            totalWeeklyRain,
            numericHumidity,
            perenualDetails,
          );

          // 3A-4: Konum yorumu hesapla (deterministik)
          String konumYorumu = _generateLocationComment(
            avgWeeklyTemp,
            numericPh,
            totalWeeklyRain,
            numericHumidity,
            soilMoisture,
            soilTempC,
            perenualDetails,
          );

          // 3A-5: Sulama takvimi hesapla (deterministik)
          String sulamaTakvimi = _generateWateringSchedule(
            totalWeeklyRain,
            numericHumidity,
            perenualDetails,
          );

          // 3A-6: Gübre önerisi hesapla (deterministik)
          String gubreOnerisi =
              _generateFertilizerAdvice(numericPh, perenualDetails);

          return {
            "type": "plant",
            "data": {
              "title": commonTitle,
              "scientific_name": scientificName,
              "description":
                  "Botanik Teşhis (%${confidence.toStringAsFixed(0)} güvenilirlik) — API Tabanlı Analiz",
              "plant_details": {
                "family": familyName,
                "halk_dilindeki_adi":
                    perenualDetails['other_names'] ?? commonTitle,
                "basari_sansi": basariSansi,
                "konum_yorumu": konumYorumu,
                "nasil_yetistirilir": perenualDetails['care_description'] ??
                    _buildGrowGuide(perenualDetails),
                "bakim_puf_noktasi": _buildCareGuide(perenualDetails),
                "hastalik_riskleri": perenualDetails['pest_susceptibility'] ??
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
          return {
            "type": "error",
            "data": {
              "message":
                  "Bitki teşhis edilemedi. Lütfen daha net bir fotoğraf yükleyin veya internet bağlantınızı kontrol edin."
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
    } catch (e) {
      return {
        'type': 'error',
        'data': {
          'message': 'Bağlantı Hatası: Lütfen internetinizi kontrol edin. ($e)',
        },
      };
    }
  }

  // ═══════════════════════════════════════════════════
  // PERENUAL API — Bitki Detaylarını Çek
  // ═══════════════════════════════════════════════════
  static Future<Map<String, dynamic>> _fetchPerenualDetails(
    String scientificName,
    String commonName,
  ) async {
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

    // Perenual API boş döndüyse Gemini AI ile tüm alanları doldur
    if (result.isEmpty) {
      result = await _fetchAIPlantDetails(scientificName, commonName);
    }

    return result;
  }

  /// Gemini AI fallback — Perenual API boş döndüğünde tüm bitki bilgilerini AI'dan çek
  static Future<Map<String, dynamic>> _fetchAIPlantDetails(
    String scientificName,
    String commonName,
  ) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final prompt = '''
Sen bitki bilimi ve tarım alanında uzman bir yapay zekasın.
"$commonName" ($scientificName) bitkisi hakkında aşağıdaki JSON formatında Türkiye koşullarına uygun bilgi ver.
Yalnızca geçerli JSON döndür, kesinlikle markdown veya ``` etiketi kullanma.

{
  "other_names": "Halk dilindeki adları (virgülle ayrılmış)",
  "type": "vegetable veya fruit veya herb veya tree veya shrub veya flower",
  "cycle": "Annual veya Perennial veya Biennial",
  "watering": "Frequent veya Average veya Minimum",
  "sunlight": "Full Sun veya Partial Shade veya Full Shade",
  "soil": "Uygun toprak türleri",
  "growth_rate": "Slow veya Moderate veya Fast",
  "care_level": "Low veya Medium veya High",
  "maintenance": "Low veya Medium veya High",
  "drought_tolerant": false,
  "salt_tolerant": false,
  "tropical": false,
  "invasive": false,
  "medicinal": false,
  "poisonous_to_humans": false,
  "poisonous_to_pets": false,
  "edible_fruit": false,
  "edible_leaf": false,
  "flowering_season": "Mevsim adı veya null",
  "fruiting_season": "Mevsim adı veya null",
  "harvest_season": "Hasat mevsimi bilgisi veya null",
  "harvest_method": "Hasat yöntemi veya null",
  "pruning_month": "Budama ayları veya null",
  "origin": "Köken ülkeler",
  "propagation": "Tohumla, çelikleme, aşılama vb.",
  "pest_susceptibility": "Bu bitkinin hassas olduğu başlıca hastalık ve zararlılar (2-3 cümle Türkçe detaylı)",
  "care_description": "💧 Sulama: ...\n\n☀️ Güneş İhtiyacı: ...\n\n✂️ Budama: ...\n\n🧪 Gübreleme: ... (detaylı Türkçe bakım rehberi, her bölüm 2-3 cümle)"
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      String text = response.text?.trim() ?? '';
      if (text.startsWith('```json')) text = text.substring(7);
      if (text.startsWith('```')) text = text.substring(3);
      if (text.endsWith('```')) text = text.substring(0, text.length - 3);
      text = text.trim();

      final Map<String, dynamic> aiData = jsonDecode(text);
      return Map<String, dynamic>.from(aiData);
    } catch (_) {
      return {};
    }
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
  // MEVSİM YARDIMCISI
  // ═══════════════════════════════════════════════════
  static String _getCurrentSeason(int month) {
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  // ═══════════════════════════════════════════════════
  // TARLAYA ÖZEL EKİM PLANI (Gemini LLM — sadece bu fonksiyon kullanıyor)
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
    try {
      final now = DateTime.now();
      final monthNames = [
        '',
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık'
      ];

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      String contextBlock = '';
      if (latitude != null && longitude != null) {
        contextBlock = '''
📊 TARLA VERİLERİ:
- Konum: $latitude, $longitude
- Alan: ${areaDekar != null ? '${areaDekar.toStringAsFixed(1)} Dekar' : 'Belirtilmedi'}
- Toprak pH: ${ph != null ? ph.toStringAsFixed(1) : 'Bilinmiyor'}
- Haftalık Ort. Sıcaklık: ${avgTemp != null ? '${avgTemp.toStringAsFixed(1)}°C' : 'Bilinmiyor'}
- Haftalık Toplam Yağış: ${totalRain != null ? '${totalRain.toStringAsFixed(1)} mm' : 'Bilinmiyor'}
''';
      }

      final prompt = '''
Sen profesyonel bir ziraat mühendisisin ve Türkiye'de çiftçilere danışmanlık yapıyorsun.

📋 GÖREV:
Kullanıcı "$plantName" bitkisini, kayıtlı olan "$fieldName" isimli tarlasına ekecek.
Bugünün tarihi: ${now.day} ${monthNames[now.month]} ${now.year}
Mevcut Mevsim: ${_getCurrentSeason(now.month)}

$contextBlock

Lütfen bu tarlaya özel, bugünden başlayarak adım adım bir yetiştirme takvimi çıkar.
Aşağıdaki başlıkları detaylı olarak doldur:

🌱 1. TOPRAK HAZIRLIĞI
${ph != null ? '- pH ${ph.toStringAsFixed(1)} değerine göre kireçleme/kükürt gerekli mi?' : ''}
- Taban gübresi ne zaman, ne kadar atılmalı (dekara kg)

🌾 2. EKİM / DİKİM SÜRECİ
- Ekim derinliği, sıra arası ve sıra üzeri mesafeleri
- Tohum/fide miktarı (dekara)

💧 3. SULAMA VE GÜBRELEME TAKVİMİ
${totalRain != null ? '- Haftalık yağış $totalRain mm. Ek sulama gerekli mi?' : ''}

🌡️ 4. BAKIM VE HASTALIK TAKİBİ

🎯 5. HASAT BEKLENTİSİ
${areaDekar != null ? '- ${areaDekar.toStringAsFixed(1)} dekar alandan beklenen verim (kg)' : ''}

Cevabın şık, cesaretlendirici, somut ve akıcı Türkçe metin olsun.
Emoji kullanarak başlıkları renklendir. JSON KULLANMA.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Plan oluşturulamadı.';
    } catch (e) {
      return 'Bağlantı hatası: Plan şu an oluşturulamıyor.';
    }
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
      // 1) Hava
      () async {
        try {
          final weatherKey = dotenv.env['WEATHER_API_KEY'] ?? '';
          final wRes = await http
              .get(Uri.parse(
                'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherKey&units=metric&lang=tr',
              ))
              .timeout(const Duration(seconds: 8));
          if (wRes.statusCode == 200) {
            final wd = jsonDecode(wRes.body);
            numericTemp = (wd['main']['temp'] as num).toDouble();
            numericHumidity = (wd['main']['humidity'] as num).toDouble();
            numericWind = (wd['wind']?['speed'] as num?)?.toDouble() ?? 0;
            weatherDesc = wd['weather']?[0]?['description'] ?? '';
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

    // Gemini AI haftalık yorum
    String aiWeeklyComment = '';
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final now = DateTime.now();
      final monthNames = [
        '',
        'Ocak',
        'Şubat',
        'Mart',
        'Nisan',
        'Mayıs',
        'Haziran',
        'Temmuz',
        'Ağustos',
        'Eylül',
        'Ekim',
        'Kasım',
        'Aralık'
      ];
      String suggestedCrops = crops.map((c) => c['name']).join(', ');

      final prompt = '''
Sen uzman bir ziraat mühendisisin.
Tarla: "$fieldName" (${areaDekar.toStringAsFixed(1)} Dekar)
Konum: $latitude, $longitude | Tarih: ${now.day} ${monthNames[now.month]} ${now.year}
Hava: ${numericTemp.toStringAsFixed(1)}°C, $weatherDesc, Nem %${numericHumidity.toStringAsFixed(0)}, Rüzgar ${numericWind.toStringAsFixed(1)} m/s
Toprak — pH: ${numericPh.toStringAsFixed(1)}, Nem: %${(soilMoisture * 100).toStringAsFixed(1)}, Sıcaklık: ${soilTempC.toStringAsFixed(1)}°C
Haftalık: Ort. $avgWeeklyTemp°C, Yağış $totalWeeklyRain mm
Önerilen Ürünler: $suggestedCrops

5-6 paragraf detaylı Türkçe haftalık yorum yaz. Başlıklar:
🌤️ Haftalık Hava Değerlendirmesi
🌱 Bu Hafta Yapılması Gerekenler
🧪 Toprak ve Gübre Durumu
⚠️ Riskler
💡 Hobi Bahçecileri İçin İpuçları

Düz metin, JSON kullanma, emoji kullan, somut bilgi ver.
''';
      final response = await model.generateContent([Content.text(prompt)]);
      aiWeeklyComment = response.text ?? 'AI yorumu oluşturulamadı.';
    } catch (e) {
      aiWeeklyComment = 'AI yorumu şu an yüklenemedi.';
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

      try {
        final weatherKey = dotenv.env['WEATHER_API_KEY'] ?? '';
        final wRes = await http
            .get(Uri.parse(
              'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$weatherKey&units=metric&lang=tr',
            ))
            .timeout(const Duration(seconds: 4));
        if (wRes.statusCode == 200) {
          final wd = jsonDecode(wRes.body);
          temp = (wd['main']['temp'] as num).toDouble();
          hum = (wd['main']['humidity'] as num).toDouble();
          locationName = wd['name'] ?? locationName;
        }

        final phRes = await http
            .get(Uri.parse(
              'https://rest.isric.org/soilgrids/v2.0/properties/query?lon=$lng&lat=$lat&property=phh2o&depth=0-5cm&value=mean',
            ))
            .timeout(const Duration(seconds: 4));
        if (phRes.statusCode == 200) {
          final val = jsonDecode(phRes.body)['properties']?['layers']?[0]
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
        // Veritabanında bulundu! Sıfır çeviri gecikmesiyle direkt raporu basıyoruz.
        final data = docSnap.data()!;

        StringBuffer guide = StringBuffer();
        guide.writeln('# 🌿 ${query.toUpperCase()} Yetiştirme Rehberi');
        guide.writeln('*Bilimsel Adı: ${data["scientific"] ?? "Bilinmiyor"}*');
        guide.writeln('\n${data["desc"] ?? ""}\n');

        guide.writeln('### 📊 Bölge Uyumu');
        guide.writeln('- **Bölgeniz:** $locationName');
        guide.writeln(
            '- **Anlık Durum:** $temp°C sıcaklık ve %${hum.toStringAsFixed(0)} nem.');
        guide.writeln('- **Toprak Uyumu:** $phComment');

        guide.writeln('\n### 💧 Yaşam Döngüsü ve İhtiyaçlar');
        guide.writeln('- **Döngü:** ${data["cycle"] ?? "Bilinmiyor"}');
        guide.writeln('- **Su İhtiyacı:** ${data["watering"] ?? "Bilinmiyor"}');
        guide.writeln('- **Güneş:** ${data["sunlight"] ?? "Bilinmiyor"}');
        guide.writeln('- **Büyüme Hızı:** ${data["growth"] ?? "Bilinmiyor"}');
        guide.writeln('- **Bakım Zorluğu:** ${data["care"] ?? "Bilinmiyor"}');
        if (data["indoor"] == true)
          guide.writeln(
              '- **İç Mekan:** Bu bitki kapalı alanda/saksıda yetiştirmeye uygundur.');

        guide.writeln('\n### 🛠️ $scale İçin Ekim ve Bakım Pratikleri');
        guide.writeln(scaleComment);
        if (data["drought"] == true) {
          guide.writeln(
              '\n💡 **İpucu:** Bu bitki kuraklığa oldukça dayanıklıdır. Toprak tamamen kurumadan sulama yapmayın.');
        }
        if (data["pruning"] != null && data["pruning"] != "Yok") {
          guide.writeln('\n✂️ **Budama / Seyreltme:** ${data["pruning"]}');
        }

        guide.writeln('\n### ⚠️ Hastalık ve Zararlılar');
        guide.writeln(
            '**Dikkat Edilmesi Gereken Riskler:** ${data["pests"] ?? "Genel zararlı kontrolü yapın."}');

        return {
          'success': true,
          'guide': guide.toString(),
          'locationInfo':
              '🌡️ $temp°C | 🌿 pH: ${ph.toStringAsFixed(1)} | 💧 Nem: %${hum.toStringAsFixed(0)}',
        };
      }

      // --- 3. FIRESTORE'DA YOKSA GEMİNİ AI İLE REHBER OLUŞTUR (FALLBACK) ---
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final geminiPrompt = '''
"$query" bitkisi için Türkçe yetiştirme rehberi oluştur.
Bölge verileri: $locationName, Sıcaklık: $temp°C, Nem: %${hum.toStringAsFixed(0)}, Toprak pH: ${ph.toStringAsFixed(1)}
Ölçek: $scale

Aşağıdaki JSON formatında yanıt ver. Markdown KULLANMA, saf JSON:
{
  "scientific": "Bilimsel adı",
  "desc": "2-3 cümle genel açıklama",
  "cycle": "Tek Yıllık / Çok Yıllık",
  "watering": "Su ihtiyacı açıklaması",
  "sunlight": "Güneş ihtiyacı",
  "growth": "Büyüme hızı",
  "care": "Bakım zorluğu",
  "indoor": false,
  "drought": false,
  "pruning": "Budama bilgisi veya Yok",
  "pests": "Yaygın zararlı ve hastalıklar",
  "planting_depth_cm": 3,
  "row_spacing_cm": 50,
  "plant_spacing_cm": 40,
  "seeds_per_dekar": 500,
  "planting_tip": "Ekim ile ilgili 1 cümle pratik bilgi"
}
''';

      final response = await model.generateContent([Content.text(geminiPrompt)]);
      String responseText = response.text?.trim() ?? '{}';
      if (responseText.startsWith('```json')) responseText = responseText.substring(7);
      if (responseText.startsWith('```')) responseText = responseText.substring(3);
      if (responseText.endsWith('```')) responseText = responseText.substring(0, responseText.length - 3);
      responseText = responseText.trim();

      final data = jsonDecode(responseText) as Map<String, dynamic>;

      StringBuffer guide = StringBuffer();
      guide.writeln('# 🌿 ${query.toUpperCase()} Yetiştirme Rehberi');
      guide.writeln('*Bilimsel Adı: ${data["scientific"] ?? "Bilinmiyor"}*');
      guide.writeln('\n${data["desc"] ?? ""}\n');

      guide.writeln('### 📊 Bölge Uyumu');
      guide.writeln('- **Bölgeniz:** $locationName');
      guide.writeln(
          '- **Anlık Durum:** $temp°C sıcaklık ve %${hum.toStringAsFixed(0)} nem.');
      guide.writeln('- **Toprak Uyumu:** $phComment');

      guide.writeln('\n### 💧 Yaşam Döngüsü ve İhtiyaçlar');
      guide.writeln('- **Döngü:** ${data["cycle"] ?? "Bilinmiyor"}');
      guide.writeln('- **Su İhtiyacı:** ${data["watering"] ?? "Bilinmiyor"}');
      guide.writeln('- **Güneş:** ${data["sunlight"] ?? "Bilinmiyor"}');
      guide.writeln('- **Büyüme Hızı:** ${data["growth"] ?? "Bilinmiyor"}');
      guide.writeln('- **Bakım Zorluğu:** ${data["care"] ?? "Bilinmiyor"}');
      if (data["indoor"] == true)
        guide.writeln(
            '- **İç Mekan:** Bu bitki kapalı alanda/saksıda yetiştirmeye uygundur.');

      guide.writeln('\n### 🌱 Ekim Bilgileri');
      guide.writeln('- **Ekim Derinliği:** ${data["planting_depth_cm"] ?? 3} cm');
      guide.writeln('- **Sıra Arası:** ${data["row_spacing_cm"] ?? 50} cm');
      guide.writeln('- **Bitki Arası:** ${data["plant_spacing_cm"] ?? 40} cm');
      guide.writeln('- **Dekara Fide/Tohum:** ${data["seeds_per_dekar"] ?? 500} adet');
      if (data["planting_tip"] != null)
        guide.writeln('- **💡 İpucu:** ${data["planting_tip"]}');

      guide.writeln('\n### 🛠️ $scale İçin Ekim ve Bakım Pratikleri');
      guide.writeln(scaleComment);
      if (data["drought"] == true) {
        guide.writeln(
            '\n💡 **İpucu:** Bu bitki kuraklığa oldukça dayanıklıdır.');
      }
      if (data["pruning"] != null && data["pruning"] != "Yok") {
        guide.writeln('\n✂️ **Budama:** ${data["pruning"]}');
      }

      guide.writeln('\n### ⚠️ Hastalık ve Zararlılar');
      guide.writeln(
          '**Dikkat Edilmesi Gereken Riskler:** ${data["pests"] ?? "Genel zararlı kontrolü yapın."}');

      return {
        'success': true,
        'guide': guide.toString(),
        'plantingData': {
          'depth_cm': data["planting_depth_cm"] ?? 3,
          'row_spacing_cm': data["row_spacing_cm"] ?? 50,
          'plant_spacing_cm': data["plant_spacing_cm"] ?? 40,
          'seeds_per_dekar': data["seeds_per_dekar"] ?? 500,
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
}
