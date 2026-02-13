import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/product_model.dart';
import '../../data/models/stock_movement_model.dart';

class ExportHelper {
  /// Ürün listesini CSV formatında dışa aktarır ve paylaşım dialogunu açar.
  static Future<void> exportProductsToCsv(List<Product> products) async {
    try {
      List<List<dynamic>> rows = [];

      // Başlıklar
      rows.add([
        "ID",
        "Urun Adi",
        "Kategori",
        "Miktar",
        "Minimum Stok",
        "Barkod",
        "Olusturulma Tarihi",
      ]);

      for (var product in products) {
        rows.add([
          product.id,
          product.title,
          product.category,
          product.quantity,
          product.minStockLevel,
          product.barcode ?? "",
          DateFormat('yyyy-MM-dd HH:mm').format(product.createdAt),
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/urunler_$dateStr.csv';

      final file = File(path);
      // Windows Excel'de UTF-8 karakterlerin okunabilmesi için BOM eklendi.
      await file.writeAsString('\uFEFF$csvData');

      await Share.shareXFiles([
        XFile(path),
      ], text: 'SmartInventory Ürün Listesi');
    } catch (e) {
      throw Exception('CSV dışa aktarımında hata oluştu: $e');
    }
  }

  /// Ürün listesini PDF formatında dışa aktarır ve paylaşım dialogunu açar.
  static Future<void> exportProductsToPdf(List<Product> products) async {
    try {
      final pdf = pw.Document();

      // Türkçe karakter desteği için font ayarlanıyor.
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartInventory Ürün Raporu',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),
              ],
            );
          },
          build: (context) {
            return [
              pw.TableHelper.fromTextArray(
                headers: [
                  'ID',
                  'Ürün Adı',
                  'Kategori',
                  'Miktar',
                  'Min. Stok',
                  'Barkod',
                ],
                data: products.map((product) {
                  return [
                    product.id.toString(),
                    product.title,
                    product.category,
                    product.quantity.toString(),
                    product.minStockLevel.toString(),
                    product.barcode ?? "",
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.centerLeft,
                },
              ),
            ];
          },
          footer: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey,
                  ),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/urun_raporu_$dateStr.pdf';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(path),
      ], text: 'SmartInventory Ürün Raporu');
    } catch (e) {
      throw Exception('PDF dışa aktarımında hata oluştu: $e');
    }
  }

  /// Stok hareketleri listesini PDF formatında dışa aktarır ve paylaşıma açar.
  static Future<void> exportMovementsToPdf(
    List<StockMovement> movements,
  ) async {
    try {
      final pdf = pw.Document();

      // Türkçe karakter desteği için font ayarlanıyor.
      final fontRegular = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SmartInventory Stok Hareketleri Raporu',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.Divider(),
                pw.SizedBox(height: 16),
              ],
            );
          },
          build: (context) {
            return [
              pw.TableHelper.fromTextArray(
                headers: [
                  'Islem Tarihi',
                  'Urun ID',
                  'Islem Tipi',
                  'Miktar',
                  'Sebep',
                ],
                data: movements.map((movement) {
                  return [
                    DateFormat('dd.MM.yyyy HH:mm').format(movement.createdAt),
                    movement.productId.toString(),
                    movement.type == MovementType.inbound ? 'Girisi' : 'Cikisi',
                    movement.quantity.toString(),
                    movement.reason,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellHeight: 30,
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/stok_hareketleri_$dateStr.pdf';

      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([
        XFile(path),
      ], text: 'SmartInventory Stok Hareketleri Raporu');
    } catch (e) {
      throw Exception('Stok hareketleri PDF dışa aktarımında hata oluştu: $e');
    }
  }
}
