import 'package:flutter/material.dart';

class PlantDbCategory {
  static const grain = 'Tahıl';
  static const vegetable = 'Sebze';
  static const fruit = 'Meyve';
  static const industrial = 'Endüstri';
  static const legume = 'Baklagil';
}

class PlantRenderType {
  static const stalk = 'stalk';     // e.g. corn, wheat
  static const bush = 'bush';       // e.g. tomato, pepper
  static const broadleaf = 'leaf';  // e.g. cabbage, lettuce
  static const root = 'root';       // e.g. potato, carrot
  static const vine = 'vine';       // e.g. grape, melon
  static const tree = 'tree';       // e.g. apple, olive
  static const dense = 'dense';     // e.g. clover, alfalfa
}

class AgriPlant {
  final String id;
  final String nameTr;
  final String category;
  final String cycle;
  
  // Environment Needs
  final double minPh;
  final double maxPh;
  final double optimalTemp;
  final double minTemp;
  final double maxTemp;
  final double waterReqMmPerSeason;
  
  // Cultivation
  final int daysToHarvest;
  final int plantDensityPerDekar; // Approximate seeds/plants per dekar (1000 m2)
  final double maxVisualHeight; // Used for 3D engine (e.g. 24.0 for corn, 5.0 for lettuce)
  
  // Rendering Properties
  final Color renderColor;
  final String renderType;

  const AgriPlant({
    required this.id,
    required this.nameTr,
    this.category = PlantDbCategory.vegetable,
    this.cycle = 'Yıllık',
    required this.minPh,
    required this.maxPh,
    required this.optimalTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.waterReqMmPerSeason,
    required this.daysToHarvest,
    required this.plantDensityPerDekar,
    required this.maxVisualHeight,
    required this.renderColor,
    required this.renderType,
  });

  /// Evaluates how suitable a given environment is (0 to 100 score).
  int evaluateSuitability(double soilPh, double currentTemp, double annualRainMm) {
    double tempScore = 100.0;
    if (currentTemp < minTemp || currentTemp > maxTemp) tempScore = 20.0;
    else if (currentTemp != optimalTemp) {
      tempScore = 100.0 - ((currentTemp - optimalTemp).abs() * 5);
    }
    
    double phScore = 100.0;
    if (soilPh < minPh || soilPh > maxPh) {
       phScore = 100.0 - ((soilPh - ((minPh + maxPh)/2)).abs() * 30);
    }

    double waterScore = 100.0;
    // Assuming annualRain is a proxy for water availability. If lower, requires irrigation.
    // If significantly lower and no irrigation info, drops score.
    if (annualRainMm < waterReqMmPerSeason * 0.4) {
      waterScore = 50.0;
    }

    double finalScore = (tempScore * 0.5) + (phScore * 0.3) + (waterScore * 0.2);
    return finalScore.clamp(0, 100).toInt();
  }
}

class VerifiedAgriDatabase {
  static const List<AgriPlant> plants = [
    // ── TAHILLAR ──
    AgriPlant(id: 'wheat', nameTr: 'Buğday', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 20, minTemp: 5, maxTemp: 30, waterReqMmPerSeason: 450, 
      daysToHarvest: 210, plantDensityPerDekar: 40000, maxVisualHeight: 18.0, renderColor: Color(0xFFFBC02D), renderType: PlantRenderType.stalk),
    AgriPlant(id: 'barley', nameTr: 'Arpa', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 8.0, optimalTemp: 18, minTemp: 3, maxTemp: 35, waterReqMmPerSeason: 350, 
      daysToHarvest: 180, plantDensityPerDekar: 35000, maxVisualHeight: 16.0, renderColor: Color(0xFFD4E157), renderType: PlantRenderType.stalk),
    AgriPlant(id: 'corn', nameTr: 'Mısır', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 5.8, maxPh: 7.0, optimalTemp: 26, minTemp: 10, maxTemp: 35, waterReqMmPerSeason: 600, 
      daysToHarvest: 120, plantDensityPerDekar: 7000, maxVisualHeight: 28.0, renderColor: Color(0xFF689F38), renderType: PlantRenderType.stalk),
    AgriPlant(id: 'rice', nameTr: 'Çeltik (Pirinç)', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 5.5, maxPh: 6.5, optimalTemp: 28, minTemp: 15, maxTemp: 35, waterReqMmPerSeason: 1200, 
      daysToHarvest: 140, plantDensityPerDekar: 25000, maxVisualHeight: 12.0, renderColor: Color(0xFFAED581), renderType: PlantRenderType.dense),
    AgriPlant(id: 'oats', nameTr: 'Yulaf', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 5.0, maxPh: 7.5, optimalTemp: 16, minTemp: 2, maxTemp: 30, waterReqMmPerSeason: 400, 
      daysToHarvest: 190, plantDensityPerDekar: 30000, maxVisualHeight: 17.0, renderColor: Color(0xFFC5E1A5), renderType: PlantRenderType.stalk),
    AgriPlant(id: 'rye', nameTr: 'Çavdar', category: PlantDbCategory.grain, cycle: 'Yıllık',
      minPh: 5.0, maxPh: 7.5, optimalTemp: 15, minTemp: -5, maxTemp: 28, waterReqMmPerSeason: 300, 
      daysToHarvest: 200, plantDensityPerDekar: 35000, maxVisualHeight: 20.0, renderColor: Color(0xFF8D6E63), renderType: PlantRenderType.stalk),

    // ── ENDÜSTRİ BİTKİLERİ ──
    AgriPlant(id: 'sunflower', nameTr: 'Ayçiçeği', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 25, minTemp: 10, maxTemp: 35, waterReqMmPerSeason: 450, 
      daysToHarvest: 120, plantDensityPerDekar: 5000, maxVisualHeight: 24.0, renderColor: Color(0xFFFFCA28), renderType: PlantRenderType.stalk),
    AgriPlant(id: 'cotton', nameTr: 'Pamuk', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 5.8, maxPh: 8.0, optimalTemp: 30, minTemp: 15, maxTemp: 40, waterReqMmPerSeason: 700, 
      daysToHarvest: 160, plantDensityPerDekar: 6000, maxVisualHeight: 16.0, renderColor: Colors.white, renderType: PlantRenderType.bush),
    AgriPlant(id: 'sugarbeet', nameTr: 'Şeker Pancarı', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 6.5, maxPh: 8.0, optimalTemp: 22, minTemp: 8, maxTemp: 30, waterReqMmPerSeason: 650, 
      daysToHarvest: 170, plantDensityPerDekar: 9000, maxVisualHeight: 7.0, renderColor: Color(0xFF81C784), renderType: PlantRenderType.broadleaf),
    AgriPlant(id: 'tobacco', nameTr: 'Tütün', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 5.5, maxPh: 6.5, optimalTemp: 26, minTemp: 12, maxTemp: 35, waterReqMmPerSeason: 400, 
      daysToHarvest: 110, plantDensityPerDekar: 3500, maxVisualHeight: 18.0, renderColor: Color(0xFF4CAF50), renderType: PlantRenderType.broadleaf),
    AgriPlant(id: 'sesame', nameTr: 'Susam', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 5.5, maxPh: 8.0, optimalTemp: 28, minTemp: 15, maxTemp: 40, waterReqMmPerSeason: 350, 
      daysToHarvest: 100, plantDensityPerDekar: 20000, maxVisualHeight: 14.0, renderColor: Color(0xFFFFCC80), renderType: PlantRenderType.bush),
    AgriPlant(id: 'peanut', nameTr: 'Yer Fıstığı', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 5.8, maxPh: 7.0, optimalTemp: 28, minTemp: 15, maxTemp: 35, waterReqMmPerSeason: 500, 
      daysToHarvest: 140, plantDensityPerDekar: 8000, maxVisualHeight: 6.0, renderColor: Color(0xFF6D4C41), renderType: PlantRenderType.bush),
    AgriPlant(id: 'soybean', nameTr: 'Soya Fasulyesi', category: PlantDbCategory.industrial, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 25, minTemp: 10, maxTemp: 35, waterReqMmPerSeason: 550, 
      daysToHarvest: 130, plantDensityPerDekar: 15000, maxVisualHeight: 12.0, renderColor: Color(0xFF8BC34A), renderType: PlantRenderType.bush),

    // ── BAKLAGİLLER ──
    AgriPlant(id: 'chickpea', nameTr: 'Nohut', category: PlantDbCategory.legume, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 8.0, optimalTemp: 22, minTemp: 5, maxTemp: 30, waterReqMmPerSeason: 300, 
      daysToHarvest: 100, plantDensityPerDekar: 30000, maxVisualHeight: 9.0, renderColor: Color(0xFFC5E1A5), renderType: PlantRenderType.bush),
    AgriPlant(id: 'lentil', nameTr: 'Mercimek', category: PlantDbCategory.legume, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 8.0, optimalTemp: 18, minTemp: 2, maxTemp: 30, waterReqMmPerSeason: 250, 
      daysToHarvest: 110, plantDensityPerDekar: 25000, maxVisualHeight: 6.0, renderColor: Color(0xFF9CCC65), renderType: PlantRenderType.bush),
    AgriPlant(id: 'bean_dry', nameTr: 'Kuru Fasulye', category: PlantDbCategory.legume, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 24, minTemp: 10, maxTemp: 32, waterReqMmPerSeason: 450, 
      daysToHarvest: 90, plantDensityPerDekar: 20000, maxVisualHeight: 10.0, renderColor: Color(0xFF388E3C), renderType: PlantRenderType.bush),
    AgriPlant(id: 'pea', nameTr: 'Bezelye', category: PlantDbCategory.legume, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 18, minTemp: 4, maxTemp: 28, waterReqMmPerSeason: 350, 
      daysToHarvest: 80, plantDensityPerDekar: 20000, maxVisualHeight: 12.0, renderColor: Color(0xFF4CAF50), renderType: PlantRenderType.vine),

    // ── SEBZELER ──
    AgriPlant(id: 'tomato', nameTr: 'Domates', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 6.8, optimalTemp: 24, minTemp: 10, maxTemp: 35, waterReqMmPerSeason: 500, 
      daysToHarvest: 80, plantDensityPerDekar: 2500, maxVisualHeight: 14.0, renderColor: Colors.redAccent, renderType: PlantRenderType.bush),
    AgriPlant(id: 'pepper', nameTr: 'Biber', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 6.8, optimalTemp: 25, minTemp: 12, maxTemp: 35, waterReqMmPerSeason: 550, 
      daysToHarvest: 90, plantDensityPerDekar: 3000, maxVisualHeight: 12.0, renderColor: Color(0xFF388E3C), renderType: PlantRenderType.bush),
    AgriPlant(id: 'eggplant', nameTr: 'Patlıcan', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 5.5, maxPh: 6.8, optimalTemp: 26, minTemp: 15, maxTemp: 35, waterReqMmPerSeason: 500, 
      daysToHarvest: 90, plantDensityPerDekar: 2500, maxVisualHeight: 11.0, renderColor: Color(0xFF6A1B9A), renderType: PlantRenderType.bush),
    AgriPlant(id: 'onion', nameTr: 'Soğan', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 20, minTemp: 5, maxTemp: 30, waterReqMmPerSeason: 400, 
      daysToHarvest: 120, plantDensityPerDekar: 35000, maxVisualHeight: 6.0, renderColor: Color(0xFFE6EE9C), renderType: PlantRenderType.root),
    AgriPlant(id: 'garlic', nameTr: 'Sarımsak', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 18, minTemp: 0, maxTemp: 30, waterReqMmPerSeason: 350, 
      daysToHarvest: 150, plantDensityPerDekar: 30000, maxVisualHeight: 5.0, renderColor: Colors.white, renderType: PlantRenderType.root),
    AgriPlant(id: 'potato', nameTr: 'Patates', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 5.0, maxPh: 6.5, optimalTemp: 18, minTemp: 7, maxTemp: 28, waterReqMmPerSeason: 500, 
      daysToHarvest: 110, plantDensityPerDekar: 5000, maxVisualHeight: 8.0, renderColor: Color(0xFF8D6E63), renderType: PlantRenderType.root),
    AgriPlant(id: 'carrot', nameTr: 'Havuç', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 6.8, optimalTemp: 18, minTemp: 5, maxTemp: 28, waterReqMmPerSeason: 450, 
      daysToHarvest: 90, plantDensityPerDekar: 40000, maxVisualHeight: 7.0, renderColor: Colors.orange, renderType: PlantRenderType.root),
    AgriPlant(id: 'cabbage', nameTr: 'Lahana', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 16, minTemp: 0, maxTemp: 25, waterReqMmPerSeason: 600, 
      daysToHarvest: 90, plantDensityPerDekar: 4000, maxVisualHeight: 8.0, renderColor: Color(0xFF1B5E20), renderType: PlantRenderType.broadleaf),
    AgriPlant(id: 'lettuce', nameTr: 'Marul', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 16, minTemp: 5, maxTemp: 25, waterReqMmPerSeason: 400, 
      daysToHarvest: 60, plantDensityPerDekar: 8000, maxVisualHeight: 6.0, renderColor: Color(0xFF66BB6A), renderType: PlantRenderType.broadleaf),
    AgriPlant(id: 'spinach', nameTr: 'Ispanak', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 15, minTemp: 0, maxTemp: 22, waterReqMmPerSeason: 350, 
      daysToHarvest: 50, plantDensityPerDekar: 15000, maxVisualHeight: 4.0, renderColor: Color(0xFF2E7D32), renderType: PlantRenderType.broadleaf),
    AgriPlant(id: 'cucumber', nameTr: 'Salatalık', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 26, minTemp: 12, maxTemp: 35, waterReqMmPerSeason: 500, 
      daysToHarvest: 60, plantDensityPerDekar: 2500, maxVisualHeight: 18.0, renderColor: Color(0xFF4CAF50), renderType: PlantRenderType.vine),
    AgriPlant(id: 'pumpkin', nameTr: 'Kabak / Balkabağı', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 24, minTemp: 10, maxTemp: 35, waterReqMmPerSeason: 550, 
      daysToHarvest: 100, plantDensityPerDekar: 1500, maxVisualHeight: 14.0, renderColor: Color(0xFFE65100), renderType: PlantRenderType.vine),
    AgriPlant(id: 'watermelon', nameTr: 'Karpuz', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 28, minTemp: 15, maxTemp: 40, waterReqMmPerSeason: 600, 
      daysToHarvest: 90, plantDensityPerDekar: 1000, maxVisualHeight: 10.0, renderColor: Color(0xFF64DD17), renderType: PlantRenderType.vine),
    AgriPlant(id: 'melon', nameTr: 'Kavun', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 28, minTemp: 15, maxTemp: 40, waterReqMmPerSeason: 550, 
      daysToHarvest: 90, plantDensityPerDekar: 1000, maxVisualHeight: 10.0, renderColor: Color(0xFFFFD54F), renderType: PlantRenderType.vine),
    AgriPlant(id: 'leek', nameTr: 'Pırasa', category: PlantDbCategory.vegetable, cycle: 'Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 18, minTemp: 0, maxTemp: 28, waterReqMmPerSeason: 500, 
      daysToHarvest: 120, plantDensityPerDekar: 20000, maxVisualHeight: 9.0, renderColor: Color(0xFFAED581), renderType: PlantRenderType.stalk),
    
    // ── MEYVELER (Çok Yıllık, Bağ/Bahçe) ──
    AgriPlant(id: 'grapevine', nameTr: 'Üzüm (Bağ)', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 5.5, maxPh: 8.0, optimalTemp: 25, minTemp: -15, maxTemp: 40, waterReqMmPerSeason: 600, 
      daysToHarvest: 150, plantDensityPerDekar: 250, maxVisualHeight: 22.0, renderColor: Color(0xFF4A148C), renderType: PlantRenderType.vine),
    AgriPlant(id: 'apple', nameTr: 'Elma', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 20, minTemp: -20, maxTemp: 35, waterReqMmPerSeason: 800, 
      daysToHarvest: 160, plantDensityPerDekar: 60, maxVisualHeight: 40.0, renderColor: Colors.red, renderType: PlantRenderType.tree),
    AgriPlant(id: 'olive', nameTr: 'Zeytin', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.5, maxPh: 8.5, optimalTemp: 25, minTemp: -5, maxTemp: 45, waterReqMmPerSeason: 400, 
      daysToHarvest: 180, plantDensityPerDekar: 30, maxVisualHeight: 35.0, renderColor: Color(0xFF827717), renderType: PlantRenderType.tree),
    AgriPlant(id: 'hazelnut', nameTr: 'Fındık', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 5.5, maxPh: 7.0, optimalTemp: 18, minTemp: -10, maxTemp: 35, waterReqMmPerSeason: 800, 
      daysToHarvest: 150, plantDensityPerDekar: 50, maxVisualHeight: 25.0, renderColor: Color(0xFF8D6E63), renderType: PlantRenderType.tree),
    AgriPlant(id: 'pistachio', nameTr: 'Antep Fıstığı', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 7.0, maxPh: 8.5, optimalTemp: 30, minTemp: -15, maxTemp: 45, waterReqMmPerSeason: 300, 
      daysToHarvest: 160, plantDensityPerDekar: 35, maxVisualHeight: 30.0, renderColor: Color(0xFFA4C639), renderType: PlantRenderType.tree),
    AgriPlant(id: 'fig', nameTr: 'İncir', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 8.0, optimalTemp: 30, minTemp: -5, maxTemp: 45, waterReqMmPerSeason: 500, 
      daysToHarvest: 130, plantDensityPerDekar: 40, maxVisualHeight: 35.0, renderColor: Color(0xFF6B4582), renderType: PlantRenderType.tree),
    AgriPlant(id: 'apricot', nameTr: 'Kayısı', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 24, minTemp: -15, maxTemp: 40, waterReqMmPerSeason: 600, 
      daysToHarvest: 110, plantDensityPerDekar: 40, maxVisualHeight: 35.0, renderColor: Color(0xFFFF9800), renderType: PlantRenderType.tree),
    AgriPlant(id: 'cherry', nameTr: 'Kiraz', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 7.0, optimalTemp: 22, minTemp: -15, maxTemp: 35, waterReqMmPerSeason: 700, 
      daysToHarvest: 90, plantDensityPerDekar: 50, maxVisualHeight: 30.0, renderColor: Color(0xFFC2185B), renderType: PlantRenderType.tree),
    AgriPlant(id: 'peach', nameTr: 'Şeftali', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 24, minTemp: -12, maxTemp: 35, waterReqMmPerSeason: 650, 
      daysToHarvest: 120, plantDensityPerDekar: 50, maxVisualHeight: 30.0, renderColor: Color(0xFFFF8A65), renderType: PlantRenderType.tree),
    AgriPlant(id: 'citrus', nameTr: 'Narenciye (Portakal/Limon)', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 6.0, maxPh: 7.5, optimalTemp: 26, minTemp: -2, maxTemp: 40, waterReqMmPerSeason: 900, 
      daysToHarvest: 180, plantDensityPerDekar: 45, maxVisualHeight: 35.0, renderColor: Color(0xFFFFB300), renderType: PlantRenderType.tree),
    AgriPlant(id: 'strawberry', nameTr: 'Çilek', category: PlantDbCategory.fruit, cycle: 'Çok Yıllık',
      minPh: 5.5, maxPh: 6.5, optimalTemp: 22, minTemp: -5, maxTemp: 30, waterReqMmPerSeason: 400, 
      daysToHarvest: 60, plantDensityPerDekar: 6000, maxVisualHeight: 4.0, renderColor: Colors.red, renderType: PlantRenderType.bush),
  ];

  static AgriPlant? getById(String id) {
    for (var p in plants) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<AgriPlant> search(String query) {
    if (query.isEmpty) return plants;
    final q = query.toLowerCase();
    return plants.where((p) => p.nameTr.toLowerCase().contains(q)).toList();
  }
}
