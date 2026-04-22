/// ÇKS Uyumlu Sezon Sonu Tarım Raporu PDF Üreticisi
///
/// Çiftçilerin devlet desteği başvuruları için gereken detaylı döküm:
///  • Tarla bilgileri (konum, dekar, ürün)
///  • Tarla günlüğü (sulama, gübreleme, ilaçlama faaliyetleri)
///  • Cüzdan masrafları (tohum, gübre, yakıt vb.)
///  • Tahmini verim ve kâr
///  • Resmi kurumlara sunulabilecek format (logo, tarih, imza alanı)
library;

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class SeasonReportData {
  final String fieldName;
  final double dekar;
  final String cropName;
  final String city;
  final double latitude;
  final double longitude;
  final DateTime plantingDate;
  final DateTime? harvestDate;

  // Günlük aktiviteler
  final List<Map<String, dynamic>> activities;

  // Cüzdan masrafları
  final List<Map<String, dynamic>> expenses;

  // Tahmini sonuçlar
  final double estimatedYieldKg;
  final double estimatedProfitTl;
  final double totalCostTl;
  final String farmerName;
  final String? farmerPhone;
  final String? farmerEmail;

  SeasonReportData({
    required this.fieldName,
    required this.dekar,
    required this.cropName,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.plantingDate,
    this.harvestDate,
    required this.activities,
    required this.expenses,
    required this.estimatedYieldKg,
    required this.estimatedProfitTl,
    required this.totalCostTl,
    required this.farmerName,
    this.farmerPhone,
    this.farmerEmail,
  });
}

class PdfExportService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<void> _loadFonts() async {
    if (_regularFont != null) return;
    final regularData =
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final boldData =
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
  }

  /// Sezon sonu raporunu PDF olarak oluştur, kaydet ve aç
  static Future<String?> exportSeasonReport(SeasonReportData data) async {
    try {
      await _loadFonts();

      final theme = pw.ThemeData.withFont(
        base: _regularFont!,
        bold: _boldFont!,
      );

      final pdf = pw.Document(theme: theme);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildTitle(),
              pw.SizedBox(height: 20),
              _buildFarmerInfo(data),
              pw.Divider(height: 20),
              _buildFieldInfo(data),
              pw.Divider(height: 20),
              _buildActivitiesSection(data),
              pw.Divider(height: 20),
              _buildExpensesSection(data),
              pw.Divider(height: 20),
              _buildEstimatesSection(data),
              pw.SizedBox(height: 30),
              _buildSignatureArea(),
              pw.SizedBox(height: 20),
              _buildFooterNote(),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();
      // Dosya adındaki özel karakterleri temizle
      final safeName = data.fieldName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');
      final fileName = 'Tarlam_Raporu_${safeName}_${DateTime.now().year}.pdf';

      // İndirme klasörünü dene, yoksa uygulama belgeler klasörüne kaydet
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Dosyayı otomatik aç
      await OpenFile.open(filePath);

      return filePath;
    } catch (e, st) {
      // ignore: avoid_print
      print('[PdfExportService] HATA: $e\n$st');
      return null;
    }
  }

  // ── Header: Logo ve kurum bilgileri ──
  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.green700),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TARLAM',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
              pw.Text(
                'Çiftçi Yönetim Sistemi',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'ÇKS Uyumlu Sezon Raporu',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.Text(
                DateFormat('dd.MM.yyyy HH:mm', 'tr_TR')
                    .format(DateTime.now()),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ── Ana başlık ──
  static pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'SEZON SONU TARIM RAPORU',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Devlet Desteği ve Tarım Kredileri için Resmi Döküm',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.blue800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Çiftçi bilgileri ──
  static pw.Widget _buildFarmerInfo(SeasonReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ÇİFTÇİ BİLGİLERİ',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green900,
            ),
          ),
          pw.SizedBox(height: 10),
          _infoRow('Ad/Soyadı:', data.farmerName),
          if (data.farmerPhone != null)
            _infoRow('Telefon:', data.farmerPhone!),
          if (data.farmerEmail != null)
            _infoRow('E-posta:', data.farmerEmail!),
          _infoRow('Rapor Tarihi:', DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now())),
        ],
      ),
    );
  }

  // ── Tarla bilgileri ──
  static pw.Widget _buildFieldInfo(SeasonReportData data) {
    final plantingStr = DateFormat('dd.MM.yyyy').format(data.plantingDate);
    final harvestStr = data.harvestDate != null
        ? DateFormat('dd.MM.yyyy').format(data.harvestDate!)
        : 'Henüz Hasat Yapılmadı';

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TARLA BİLGİLERİ',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          _infoRow('Tarla Adı:', data.fieldName),
          _infoRow('Ürün Adı:', data.cropName),
          _infoRow('Alan (Dekar):', data.dekar.toStringAsFixed(2)),
          _infoRow('İl / İlçe:', data.city),
          _infoRow('Koordinatlar:', '${data.latitude.toStringAsFixed(5)}, ${data.longitude.toStringAsFixed(5)}'),
          _infoRow('Ekim Tarihi:', plantingStr),
          _infoRow('Hasat Tarihi:', harvestStr),
        ],
      ),
    );
  }

  // ── Faaliyetler tablosu ──
  static pw.Widget _buildActivitiesSection(SeasonReportData data) {
    final activities = data.activities;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TARIM FAALİYETLERİ (Tarla Günlüğü)',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 10),
        if (activities.isEmpty)
          pw.Text(
            'Kayıtlı faaliyete bulunmamaktadır.',
            style: pw.TextStyle(color: PdfColors.grey600),
          )
        else
          pw.Column(
            children: [
              pw.Text('Aktiviteler: ${activities.length} kayıt',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 5),
              ...activities.take(15).map((act) {
                final date = DateTime.tryParse(act['date']?.toString() ?? '');
                final dateStr = date != null
                    ? DateFormat('dd.MM.yyyy').format(date)
                    : '--';
                final type = act['activity_type']?.toString() ?? 'Bilinmiyor';
                final notes = act['notes']?.toString() ?? '';

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    '$dateStr · $type · ${notes.length > 40 ? notes.substring(0, 40) : notes}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                );
              }),
            ],
          ),
      ],
    );
  }

  // ── Masraflar tablosu ──
  static pw.Widget _buildExpensesSection(SeasonReportData data) {
    final expenses = data.expenses;
    double totalByCategory = 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'HASAT ÖNCESİ MASRAFLAR (ÇKS Cüzdan)',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green900,
          ),
        ),
        pw.SizedBox(height: 10),
        if (expenses.isEmpty)
          pw.Text(
            'Kayıtlı masrafa bulunmamaktadır.',
            style: pw.TextStyle(color: PdfColors.grey600),
          )
        else ...[
          pw.Column(
            children: [
              ...expenses.take(20).map((exp) {
                totalByCategory +=
                    (exp['total_try'] as num?)?.toDouble() ?? 0;
                final date = DateTime.tryParse(exp['date']?.toString() ?? '');
                final dateStr = date != null
                    ? DateFormat('dd.MM.yyyy').format(date)
                    : '--';
                final item = exp['item']?.toString() ?? 'Diğer';
                final qty = exp['quantity']?.toString() ?? '';
                final total = (exp['total_try'] as num?)?.toDouble() ?? 0;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    '$dateStr · $item · $qty · ${total.toStringAsFixed(2)} ₺',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                );
              }),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  border: pw.Border.all(color: PdfColors.green700),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOPLAM MASRAF:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      '${totalByCategory.toStringAsFixed(2)} ₺',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.green900,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Not: Tohum, gübre, yakıt, işçilik, pestisit vb. masrafları kapsamaktadır.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Tahmini sonuçlar ──
  static pw.Widget _buildEstimatesSection(SeasonReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'TAHMİNİ SEZON SONU SONUÇLARI',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _estimateBox(
                'Beklenen Verim',
                '${data.estimatedYieldKg.toStringAsFixed(0)} kg',
              ),
              _estimateBox(
                'Toplam Masraf',
                '${data.totalCostTl.toStringAsFixed(2)} ₺',
              ),
              _estimateBox(
                'Tahmini Net Kâr',
                '${data.estimatedProfitTl.toStringAsFixed(2)} ₺',
                isProfit: data.estimatedProfitTl >= 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── İmza alanı ──
  static pw.Widget _buildSignatureArea() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.SizedBox(height: 30),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Çiftçi / Temsilci İmzası',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.SizedBox(height: 30),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Ziraat Danışmanı İmzası',
              style: const pw.TextStyle(fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  // ── Footer notu ──
  static pw.Widget _buildFooterNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
          width: 0.5,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GENEL UYARILAR VE BİLGİLENDİRME',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '• Bu rapor Tarlam Çiftçi Yönetim Sistemi tarafından otomatik olarak oluşturulmuştur.\n'
            '• Tarla günlüğü ve cüzdan verilerinin doğruluğundan çiftçi sorumludur.\n'
            '• Tahmini verim ve kâr; iklim şartlarına, hastalık/zararlı basıncına göre değişebilir.\n'
            '• Bu rapor devlet destek başvurusu ve tarım kredileri için resmi kurumlara sunulabilir.\n'
            '• Herhangi bir sorun veya düzeltme için lütfen Tarlam Uygulaması desteğine başvurunuz.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ── Yardımcı widget'lar ──
  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }


  static pw.Widget _estimateBox(String label, String value, {bool isProfit = true}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: isProfit ? PdfColors.green50 : PdfColors.red50,
        border: pw.Border.all(
          color: isProfit ? PdfColors.green700 : PdfColors.red700,
          width: 1,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: isProfit ? PdfColors.green900 : PdfColors.red900,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: isProfit ? PdfColors.green900 : PdfColors.red900,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
