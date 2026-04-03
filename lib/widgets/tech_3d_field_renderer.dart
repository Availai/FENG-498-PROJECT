import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/verified_agri_database.dart';

enum FieldViewMode { physical, heatmap, moisture }

class Point3D {
  final double x, y, z;
  const Point3D(this.x, this.y, this.z);
}

class Tech3DRenderData {
  final int r;
  final int c;
  final double cx, cy;
  final String plantId;
  final double growthProgress; // 0.0 (seed) to 1.0 (mature)
  
  Tech3DRenderData(this.r, this.c, this.cx, this.cy, this.plantId, this.growthProgress);
}

class Tech3DRenderer extends CustomPainter {
  final Map<String, Tech3DRenderData> farmGrid;
  final int rows;
  final int cols;
  final double blockSize;
  
  final double cameraYaw;
  final double cameraPitch;
  final double cameraScale;
  final FieldViewMode viewMode;
  
  final int? selectedRow;
  final int? selectedCol;
  final double globalGrowth; // the slider value applied to crops that don't have individual growth data

  Tech3DRenderer({
    required this.farmGrid,
    required this.rows,
    required this.cols,
    required this.blockSize,
    required this.cameraYaw,
    required this.cameraPitch,
    required this.cameraScale,
    this.viewMode = FieldViewMode.physical,
    this.selectedRow,
    this.selectedCol,
    this.globalGrowth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2;
    double cy = size.height / 2;

    double cosY = math.cos(cameraYaw);
    double sinY = math.sin(cameraYaw);
    double cosP = math.cos(cameraPitch);
    double sinP = math.sin(cameraPitch);

    double gridW = cols * blockSize;
    double gridH = rows * blockSize;

    // Projection Function
    Offset project(Point3D p) {
      double tx = p.x - gridW / 2;
      double ty = p.y - gridH / 2;

      // Rotate around Z axis (Yaw)
      double r1x = tx * cosY - ty * sinY;
      double r1y = tx * sinY + ty * cosY;

      // Rotate around X axis (Pitch)
      double r2y = r1y * cosP - p.z * sinP;

      return Offset(cx + r1x * cameraScale, cy + r2y * cameraScale);
    }

    // Depth Calculation for Z-sorting (Higher depth = painted earlier/further back)
    double getDepth(double x, double y, double z) {
      double tx = x - gridW / 2;
      double ty = y - gridH / 2;
      // The distance away from camera based on Yaw and Pitch
      double rotatedY = tx * sinY + ty * cosY;
      return -(rotatedY * sinP + z * cosP);
    }

    // List of draw calls to be z-sorted
    List<_DrawCommand> drawQueue = [];

    // Base lighting colors for 3D boxes
    final Color topSoilColor = const Color(0xFF332014); // Very dark rich soil
    final Color leftSoilColor = const Color(0xFF26180E);
    final Color rightSoilColor = const Color(0xFF1E130B);

    final Paint borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void addSoilBlock(int r, int c, double x, double y) {
      double d = getDepth(x + blockSize/2, y + blockSize/2, 0);
      
      drawQueue.add(_DrawCommand(d, () {
        // Draw the 3D block
        final pTop1 = project(Point3D(x, y, 0));
        final pTop2 = project(Point3D(x + blockSize, y, 0));
        final pTop3 = project(Point3D(x + blockSize, y + blockSize, 0));
        final pTop4 = project(Point3D(x, y + blockSize, 0));

        final soilDepth = 6.0;
        final pBot1 = project(Point3D(x, y, -soilDepth));
        final pBot2 = project(Point3D(x + blockSize, y, -soilDepth));
        final pBot3 = project(Point3D(x + blockSize, y + blockSize, -soilDepth));
        final pBot4 = project(Point3D(x, y + blockSize, -soilDepth));

        // Draw Left Face
        if (cosY > 0) { // Approx visibility logic
          final pathL = Path()..moveTo(pTop1.dx, pTop1.dy)..lineTo(pTop4.dx, pTop4.dy)..lineTo(pBot4.dx, pBot4.dy)..lineTo(pBot1.dx, pBot1.dy)..close();
          canvas.drawPath(pathL, Paint()..color = leftSoilColor);
        }
        // Draw Right Face
        if (sinY > 0) {
          final pathR = Path()..moveTo(pTop4.dx, pTop4.dy)..lineTo(pTop3.dx, pTop3.dy)..lineTo(pBot3.dx, pBot3.dy)..lineTo(pBot4.dx, pBot4.dy)..close();
          canvas.drawPath(pathR, Paint()..color = rightSoilColor);
        }

        // Draw Top Soil Face
        final pathTop = Path()..moveTo(pTop1.dx, pTop1.dy)..lineTo(pTop2.dx, pTop2.dy)..lineTo(pTop3.dx, pTop3.dy)..lineTo(pTop4.dx, pTop4.dy)..close();
        
        Color topColor = topSoilColor;
        if (viewMode == FieldViewMode.heatmap) topColor = Colors.orange.shade900.withValues(alpha: 0.5);
        if (viewMode == FieldViewMode.moisture) topColor = Colors.blue.shade900.withValues(alpha: 0.5);

        canvas.drawPath(pathTop, Paint()..color = topColor);
        canvas.drawPath(pathTop, borderPaint);

        // Selection Highlight
        if (r == selectedRow && c == selectedCol) {
          canvas.drawPath(pathTop, Paint()..color = Colors.lightGreenAccent.withValues(alpha: 0.3));
          
          final centerBase = project(Point3D(x + blockSize/2, y + blockSize/2, 0));
          final centerTop = project(Point3D(x + blockSize/2, y + blockSize/2, 20));
          canvas.drawLine(centerBase, centerTop, Paint()..color = Colors.lightGreenAccent..strokeWidth=1.5);
          canvas.drawCircle(centerTop, 3.0, Paint()..color = Colors.white);
        }
      }));
    }

    void addVolumetricPlant(Tech3DRenderData data) {
      final plant = VerifiedAgriDatabase.getById(data.plantId);
      if (plant == null) return;

      double px = data.cx;
      double py = data.cy;
      double growth = data.growthProgress * globalGrowth;

      if (growth < 0.05) return; // Too small to render

      final h = plant.maxVisualHeight * growth;
      final type = plant.renderType;
      final color = plant.renderColor;

      double d = getDepth(px, py, h / 2);

      drawQueue.add(_DrawCommand(d + 1.0, () { // +1 depth to ensure it draws over its own soil
        final base = project(Point3D(px, py, 0));
        final top = project(Point3D(px, py, h));

        Paint fill(Color c) => Paint()..color = c..style = PaintingStyle.fill;
        Paint stroke(Color c, double w) => Paint()..color = c..style = PaintingStyle.stroke..strokeWidth = w * cameraScale..strokeCap = StrokeCap.round;

        // Shadow projection (raytraced downwards)
        final shadowOffset = Offset((h * 0.3) * cameraScale, (h * 0.1) * cameraScale);
        canvas.drawOval(Rect.fromCenter(center: base + shadowOffset, width: h * 0.6 * cameraScale, height: h * 0.3 * cameraScale), fill(Colors.black.withValues(alpha: 0.3)));

        if (type == PlantRenderType.tree) {
          // Trunk
          canvas.drawLine(base, top, stroke(const Color(0xFF5D4037), 3.0));
          // Canopy layers (volumetric spheres)
          canvas.drawCircle(project(Point3D(px, py, h * 0.6)), h * 0.4 * cameraScale, fill(color.withValues(alpha: 0.8)));
          canvas.drawCircle(project(Point3D(px + 2, py + 2, h * 0.8)), h * 0.35 * cameraScale, fill(color));
          canvas.drawCircle(project(Point3D(px - 2, py - 2, h)), h * 0.3 * cameraScale, fill(color.withValues(alpha: 0.9)));
        } 
        else if (type == PlantRenderType.stalk) {
          canvas.drawLine(base, top, stroke(color, 2.0));
          // Leaves
          int leafCount = (h / 3).floor();
          for (int i = 0; i < leafCount; i++) {
            double z = 2.0 + i * 3.0;
            if (z > h) break;
            double dir = (i % 2 == 0) ? 1.0 : -1.0;
            final lStart = project(Point3D(px, py, z));
            final lEnd = project(Point3D(px + dir * 4 * growth, py, z + 2 * growth));
            canvas.drawLine(lStart, lEnd, stroke(color.withValues(alpha: 0.8), 1.0));
          }
          if (plant.id == 'corn' && growth > 0.7) {
             canvas.drawCircle(project(Point3D(px + 1.5, py + 1.5, h * 0.6)), 2.0 * cameraScale, fill(Colors.yellow));
          }
        }
        else if (type == PlantRenderType.bush) {
          // Volumetric bush
          canvas.drawCircle(project(Point3D(px, py, h * 0.4)), h * 0.5 * cameraScale, fill(color.withValues(alpha: 0.6)));
          canvas.drawCircle(project(Point3D(px, py, h * 0.7)), h * 0.4 * cameraScale, fill(color));
          if (growth > 0.8 && (plant.id == 'tomato' || plant.id == 'pepper' || plant.id == 'eggplant')) {
            Color fruitC = plant.renderColor != color ? Colors.red : Colors.greenAccent;
            if (plant.id == 'tomato') fruitC = Colors.red;
            if (plant.id == 'eggplant') fruitC = Colors.deepPurple;
            canvas.drawCircle(project(Point3D(px + 2, py + 2, h * 0.5)), 2 * cameraScale, fill(fruitC));
            canvas.drawCircle(project(Point3D(px - 1, py - 2, h * 0.6)), 1.5 * cameraScale, fill(fruitC));
          }
        }
        else if (type == PlantRenderType.root) {
          // Leaves on top
          canvas.drawLine(base, project(Point3D(px - 3*growth, py - 3*growth, h)), stroke(Colors.green, 1.5));
          canvas.drawLine(base, project(Point3D(px + 3*growth, py + 3*growth, h)), stroke(Colors.green, 1.5));
          canvas.drawLine(base, project(Point3D(px - 2*growth, py + 3*growth, h*0.8)), stroke(Colors.green, 1.5));
          
          if (viewMode == FieldViewMode.physical && selectedRow == data.r && selectedCol == data.c && growth > 0.5) {
             // Show root inside soil in xray
             canvas.drawOval(Rect.fromCenter(center: project(Point3D(px, py, -2)), width: 6*growth*cameraScale, height: 8*growth*cameraScale), fill(color));
          }
        }
        else if (type == PlantRenderType.vine) {
          canvas.drawLine(base, project(Point3D(px + 8*growth, py + 8*growth, 0)), stroke(Colors.green.shade800, 1.5));
          canvas.drawLine(base, project(Point3D(px - 6*growth, py + 4*growth, 0)), stroke(Colors.green.shade800, 1.5));
          if (growth > 0.7) {
            canvas.drawCircle(project(Point3D(px + 4, py + 4, 1)), 3 * cameraScale, fill(color));
          }
        }
        else if (type == PlantRenderType.broadleaf) {
           canvas.drawCircle(base, h * 1.5 * cameraScale, fill(color.withValues(alpha: 0.9)));
           canvas.drawCircle(base, h * 1.0 * cameraScale, fill(color.withValues(alpha: 0.5)));
           // Draw leaf veins
           canvas.drawLine(base, project(Point3D(px + h, py + h, 1)), stroke(Colors.lightGreen, 0.5));
           canvas.drawLine(base, project(Point3D(px - h, py - h, 1)), stroke(Colors.lightGreen, 0.5));
        }
        else if (type == PlantRenderType.dense) {
           canvas.drawRect(Rect.fromCenter(center: project(Point3D(px, py, h/2)), width: blockSize*0.9*cameraScale, height: h*cameraScale), fill(color));
           canvas.drawRect(Rect.fromCenter(center: project(Point3D(px, py, h*0.8)), width: blockSize*0.8*cameraScale, height: h*0.5*cameraScale), fill(Colors.lightGreen));
        }
      }));
    }

    // 1. Queue all map elements
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        double px = c * blockSize;
        double py = r * blockSize;
        
        // Add Soil
        addSoilBlock(r, c, px, py);
        
        // Add Plant if exists
        String key = '${r}_$c';
        if (farmGrid.containsKey(key)) {
          final data = farmGrid[key]!;
          // Multiple plants per cell if tree vs density etc?
          // For super-tech representation we draw 1 visually prominent representative volumetric model per block
          addVolumetricPlant(data);
        }
      }
    }

    // 2. Sort by Depth (Painter's Algorithm)
    drawQueue.sort((a, b) => b.depth.compareTo(a.depth));

    // 3. Render
    for (var cmd in drawQueue) {
      cmd.draw();
    }
  }

  @override
  bool shouldRepaint(covariant Tech3DRenderer old) => true;
}

class _DrawCommand {
  final double depth;
  final VoidCallback draw;
  _DrawCommand(this.depth, this.draw);
}
