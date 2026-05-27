/// Sulama Tasarruf Raporu PDF dışa aktarımı.
///
/// `IrrigationCostEngine.compute()` çıktısını çiftçi/kurum için A4 rapor
/// olarak basar. Kullanım amacı: KKYDP hibe başvurusu, ziraat odası
/// konsültasyonu, yatırım kararı belgesi.
library;

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'irrigation_cost_engine.dart';

class IrrigationSavingsPdfInput {
  final String fieldName;
  final String? province;
  final double areaDekar;
  final double seasonNetMm;
  final String cropName;
  final CostResult result;
  final double waterTlPerM3;
  final double electricityTlPerKwh;
  final double pumpKwhPerM3;
  final bool withSubsidy;
  final String farmerName;
  final DateTime createdAt;

  const IrrigationSavingsPdfInput({
    required this.fieldName,
    required this.province,
    required this.areaDekar,
    required this.seasonNetMm,
    required this.cropName,
    required this.result,
    required this.waterTlPerM3,
    required this.electricityTlPerKwh,
    required this.pumpKwhPerM3,
    required this.withSubsidy,
    required this.farmerName,
    required this.createdAt,
  });
}

class IrrigationSavingsPdfService {
  const IrrigationSavingsPdfService();

  Future<File> generate(IrrigationSavingsPdfInput d) async {
    final doc = pw.Document(
      title: 'Sulama Tasarruf Raporu',
      author: 'Tarlam',
      creator: 'Tarlam',
    );

    String tl(double v) {
      if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(2)} M TL';
      if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)} K TL';
      return '${v.toStringAsFixed(0)} TL';
    }

    String m3(double v) => '${v.toStringAsFixed(0)} m³';

    final dateStr =
        '${d.createdAt.day.toString().padLeft(2, '0')}.${d.createdAt.month.toString().padLeft(2, '0')}.${d.createdAt.year}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Başlık
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.green800,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TARLAM',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold)),
                pw.Text('Sulama Tasarruf Raporu',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Olusturulma tarihi: $dateStr',
                    style: const pw.TextStyle(
                        color: PdfColors.white, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Tarla bilgileri
          _sectionHeader('Tarla Bilgileri'),
          _kv('Tarla', d.fieldName),
          _kv('Ciftci', d.farmerName),
          _kv('Bolge', d.province ?? 'Belirtilmedi'),
          _kv('Alan', '${d.areaDekar.toStringAsFixed(1)} dekar'),
          _kv('Urun', d.cropName),
          _kv('Sezonluk net su ihtiyaci',
              '${d.seasonNetMm.toStringAsFixed(0)} mm'),
          pw.SizedBox(height: 16),

          // Maliyet parametreleri
          _sectionHeader('Hesap Parametreleri'),
          _kv('Su tarifesi',
              '${d.waterTlPerM3.toStringAsFixed(2)} TL/m³'),
          _kv('Elektrik tarifesi',
              '${d.electricityTlPerKwh.toStringAsFixed(2)} TL/kWh'),
          _kv('Pompa enerjisi',
              '${d.pumpKwhPerM3.toStringAsFixed(2)} kWh/m³'),
          _kv('KKYDP hibe',
              d.withSubsidy ? '%50 (hesaba dahil)' : 'Yok'),
          pw.SizedBox(height: 16),

          // Karşılaştırma tablosu
          _sectionHeader('Yontem Karsilastirmasi'),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['', 'Mevcut', 'Alternatif'],
            data: [
              ['Yontem', d.result.current.method, d.result.alternative.method],
              [
                'Verim',
                '%${(d.result.current.efficiency * 100).toStringAsFixed(0)}',
                '%${(d.result.alternative.efficiency * 100).toStringAsFixed(0)}'
              ],
              [
                'Verilen su',
                m3(d.result.current.grossM3),
                m3(d.result.alternative.grossM3)
              ],
              [
                'Su faturasi',
                tl(d.result.current.waterCostTl),
                tl(d.result.alternative.waterCostTl)
              ],
              [
                'Pompa elektrigi',
                tl(d.result.current.energyCostTl),
                tl(d.result.alternative.energyCostTl)
              ],
              [
                'Toplam',
                tl(d.result.current.totalCostTl),
                tl(d.result.alternative.totalCostTl)
              ],
            ],
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
                fontSize: 10, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(6),
          ),
          pw.SizedBox(height: 18),

          // Ana sonuç
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: d.result.savedTlPerSeason > 0
                  ? PdfColors.green100
                  : PdfColors.grey200,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(
                  color: PdfColors.green800, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SEZONLUK TASARRUF',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800)),
                pw.SizedBox(height: 4),
                pw.Text(tl(d.result.savedTlPerSeason),
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green900)),
                pw.SizedBox(height: 4),
                pw.Text(
                    '${m3(d.result.savedM3)} su tasarrufu / sezon',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Yatırım
          if (d.result.investmentTl != null) ...[
            _sectionHeader('Yatirim ve Geri Odeme'),
            _kv('Tahmini yatirim', tl(d.result.investmentTl!)),
            _kv('Hibe sonrasi net',
                tl(d.result.investmentAfterSubsidyTl!)),
            if (d.result.paybackYears != null)
              _kv('Geri odeme (hibesiz)',
                  '${d.result.paybackYears!.toStringAsFixed(1)} yil'),
            if (d.result.paybackYearsWithSubsidy != null)
              _kv('Geri odeme (hibeli)',
                  '${d.result.paybackYearsWithSubsidy!.toStringAsFixed(1)} yil'),
            pw.SizedBox(height: 14),
          ],

          // Kaynak + disclaimer
          _sectionHeader('Kaynak ve Notlar'),
          pw.Bullet(
            text:
                'Su tarifesi: DSI Tarimsal Sulama Ucret Tarifeleri 2025 ortalama degerleri.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
                'Elektrik tarifesi: EPDK 2025 tarimsal sulama abone grubu.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
                'Yontem verim katsayilari: TAGEM ve suverimliligi.gov.tr aralik ortalamalari.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
                'Yatirim aralik degerleri yerel ekipman fiyatlarina gore degisir. Kesin teklif icin yetkili saticidan fiyat alin.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Bullet(
            text:
                'Bu rapor bilgi amaclidir. Resmi karar oncesi il/ilce tarim mudurlugu ve DSI bolge mudurluguyle gorusun.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 18),

          // İmza alanı
          pw.Divider(),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Hazirlayan',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(d.farmerName,
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Tarih',
                      style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(dateStr,
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Tarlam · Sayfa ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safeName = d.fieldName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File(
        '${dir.path}/tarlam_sulama_tasarruf_${safeName}_${d.createdAt.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> generateAndOpen(IrrigationSavingsPdfInput d) async {
    final file = await generate(d);
    await OpenFile.open(file.path);
  }

  static pw.Widget _sectionHeader(String t) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800)),
      );

  static pw.Widget _kv(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.SizedBox(
                width: 160,
                child: pw.Text(k,
                    style: pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700))),
            pw.Expanded(
              child: pw.Text(v,
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
      );
}
