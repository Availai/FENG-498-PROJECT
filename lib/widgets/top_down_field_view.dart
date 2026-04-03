import 'package:flutter/material.dart';

import '../models/crop_layer.dart';
import '../theme/app_theme.dart';

class TopDownFieldView extends StatelessWidget {
  final String fieldName;
  final double areaDekar;
  final Map<String, dynamic> plantingData;
  final String cropName;
  final List<CropLayer> extraCrops;

  const TopDownFieldView({
    super.key,
    required this.fieldName,
    required this.areaDekar,
    required this.plantingData,
    required this.cropName,
    required this.extraCrops,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fieldName,
                  style: AppText.h3(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppTag('${areaDekar.toStringAsFixed(1)} da'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.sm,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: const Color(0xFFE8F5E9),
                      ),
                      for (final layer in extraCrops)
                        Positioned(
                          left: constraints.maxWidth * layer.startPercent,
                          top: 0,
                          width: constraints.maxWidth *
                              (layer.endPercent - layer.startPercent).clamp(0.0, 1.0),
                          height: constraints.maxHeight,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: layer.color.withValues(alpha: 0.75),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                layer.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sıra arası ${(plantingData['row_spacing_cm'] as num?)?.round() ?? 0} cm • Bitki arası ${(plantingData['plant_spacing_cm'] as num?)?.round() ?? 0} cm',
            style: AppText.sm(context),
          ),
        ],
      ),
    );
  }
}
