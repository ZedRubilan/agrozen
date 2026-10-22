import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Turns the on-screen bank report into a PDF and hands it to the share
/// sheet (Telegram, e-mail, Files…).
///
/// The report widget is captured as an image and placed on one A4-wide page,
/// so the PDF matches the screen exactly in every language without bundling
/// separate PDF fonts for Cyrillic and Uzbek.
class ReportExport {
  const ReportExport._();

  static Future<Uint8List> capture(
    RenderRepaintBoundary boundary, {
    double pixelRatio = 3,
  }) async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  static Future<Uint8List> pdfFromPng(
    Uint8List png, {
    required int widthPx,
    required int heightPx,
    required String title,
  }) async {
    final doc = pw.Document(title: title, creator: 'AgroZen');
    const margin = 24.0;
    final width = PdfPageFormat.a4.width;
    final contentWidth = width - margin * 2;
    final height = contentWidth * heightPx / widthPx + margin * 2;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height, marginAll: margin),
        build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
      ),
    );
    return doc.save();
  }

  static Future<void> share(
    Uint8List pdf, {
    required String fileName,
    required String text,
  }) async {
    await Share.shareXFiles(
      [XFile.fromData(pdf, mimeType: 'application/pdf', name: fileName)],
      text: text,
      fileNameOverrides: [fileName],
    );
  }
}
