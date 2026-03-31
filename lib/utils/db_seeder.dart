import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDatabaseOneTime() async {
  final firestore = FirebaseFirestore.instance;

  // Yapay zekaya ürettirebileceğin devasa JSON listen
  final Map<String, Map<String, dynamic>> initialData = {
    "domates": {
      "scientific": "Solanum lycopersicum",
      "desc":
          "Türkiye'de en çok yetiştirilen ve tüketilen sebzelerden biridir. Sıcak ve ılıman iklimleri sever, dona karşı hassastır.",
      "cycle": "Tek Yıllık",
      "watering": "Orta - Sık (Toprak kurumadan)",
      "sunlight": "Tam Güneş (Günde en az 6-8 saat)",
      "growth": "Hızlı",
      "care": "Orta",
      "indoor": false,
      "drought": false,
      "pruning": "Haziran, Temmuz (Koltuk alma işlemi şarttır)",
      "pests":
          "Tuta absoluta (Domates Güvesi), Kırmızı Örümcek, Mildiyö Hastalığı"
    },
    "buğday": {
      "scientific": "Triticum",
      "desc":
          "Karasal iklime en uygun, Türkiye'nin en stratejik tahıl ürünüdür. Soğuğa ve kuraklığa toleranslıdır.",
      "cycle": "Tek Yıllık",
      "watering": "Az (Genelde yağmur suyuyla yetişir)",
      "sunlight": "Tam Güneş",
      "growth": "Orta",
      "care": "Düşük",
      "indoor": false,
      "drought": true,
      "pruning": "Yok",
      "pests": "Süne, Kımıl, Pas Hastalıkları"
    },
    // Buraya yüzlerce ürünü yapıştırabilirsin...
  };

  for (var entry in initialData.entries) {
    await firestore.collection('crops').doc(entry.key).set(entry.value);
  }

  print("Veritabanı başarıyla tohumlandı! 🌱");
}
