import 'package:flutter/material.dart';

class PlantDbCategory {
  static const grain = 'Tahıl';
  static const vegetable = 'Sebze';
  static const fruit = 'Meyve';
  static const industrial = 'Endüstri';
  static const legume = 'Baklagil';
}

class PlantRenderType {
  static const stalk = 'stalk';
  static const bush = 'bush';
  static const broadleaf = 'leaf';
  static const root = 'root';
  static const vine = 'vine';
  static const tree = 'tree';
  static const dense = 'dense';
}

/// Render DTO for 3D field visualization. Populated from TurkishCrop via
/// field_detail_screen._turkishCropToAgriPlant().
class AgriPlant {
  final String id;
  final String nameTr;
  final String category;
  final String cycle;

  final double minPh;
  final double maxPh;
  final double optimalTemp;
  final double minTemp;
  final double maxTemp;
  final double waterReqMmPerSeason;

  final int daysToHarvest;
  final int plantDensityPerDekar;
  final double maxVisualHeight;

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
}
