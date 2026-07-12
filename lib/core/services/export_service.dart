import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr/qr.dart';
import 'package:archive/archive_io.dart';

import '../security/device_integrity_service.dart';
import '../../data/models/history_entry.dart';
import '../utils/formatters.dart';

class ExportService {
  const ExportService();

  Future<void> shareQrSvg({
    required String data,
    required Color color,
    required String fileName,
  }) async {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.L,
    );
    final qrImage = QrImage(qrCode);
    
    final int size = qrImage.moduleCount;
    final String colorHex = '#${color.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    
    final StringBuffer svg = StringBuffer();
    svg.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    svg.writeln('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 $size $size" shape-rendering="crispEdges">');
    svg.writeln('<rect width="$size" height="$size" fill="#ffffff"/>');
    
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        if (qrImage.isDark(y, x)) {
          svg.writeln('<rect x="$x" y="$y" width="1" height="1" fill="$colorHex"/>');
        }
      }
    }
    
    svg.writeln('</svg>');

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName.svg');
    await file.writeAsString(svg.toString());
    await Share.shareXFiles([XFile(file.path)], subject: 'SafeText Secure QR (Vector)');
  }
  Future<void> shareTextReport({
    required List<HistoryEntry> history,
    required DeviceIntegrityResult integrity,
  }) async {
    final report = _generateTextReport(history, integrity);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/safetext_audit_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(report);
    await Share.shareXFiles([XFile(file.path)], subject: 'SafeText Security Audit Report');
  }

  Future<void> sharePdfReport({
    required List<HistoryEntry> history,
    required DeviceIntegrityResult integrity,
    String? password,
  }) async {
    final pdfBytes = await _generatePdfReport(history, integrity, password: password);
    final tempDir = await getTemporaryDirectory();
    final baseName = 'safetext_audit_${DateTime.now().millisecondsSinceEpoch}';

    if (password != null && password.isNotEmpty) {
      final archive = Archive();
      archive.addFile(ArchiveFile('$baseName.pdf', pdfBytes.length, pdfBytes));
      
      final zipBytes = ZipEncoder(password: password).encode(archive);
      final zipFile = File('${tempDir.path}/$baseName.zip');
      await zipFile.writeAsBytes(zipBytes);
      await Share.shareXFiles([XFile(zipFile.path)], subject: 'SafeText Security Audit Report (ZIP Container)');
    } else {
      final file = File('${tempDir.path}/$baseName.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], subject: 'SafeText Security Audit Report');
    }
  }

  Future<void> printReport({
    required List<HistoryEntry> history,
    required DeviceIntegrityResult integrity,
  }) async {
    final pdfBytes = await _generatePdfReport(history, integrity);
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  String _generateTextReport(List<HistoryEntry> history, DeviceIntegrityResult integrity) {
    final StringBuffer report = StringBuffer();
    report.writeln('========================================');
    report.writeln('      SAFETEXT SECURITY AUDIT REPORT    ');
    report.writeln('      GENERATED: ${DateTime.now()}      ');
    report.writeln('========================================\n');
    report.writeln('[DEVICE INTEGRITY]');
    report.writeln('ROOTED: ${integrity.isRooted ? 'YES (CRITICAL)' : 'NO'}');
    report.writeln('REAL DEVICE: ${integrity.isRealDevice ? 'YES' : 'NO (EMULATOR)'}');
    report.writeln('DEV MODE: ${integrity.isDevMode ? 'ENABLED' : 'DISABLED'}');
    report.writeln('SAFE DEVICE: ${integrity.isSafe ? 'YES' : 'NO'}\n');
    report.writeln('[AUDIT LOGS]');
    for (final entry in history) {
      report.writeln('${Formatters.timestamp(entry.timestamp)} | ${entry.operation.name.toUpperCase()} | ${entry.toolId} | ${entry.status.name.toUpperCase()}');
    }
    return report.toString();
  }

  Future<Uint8List> _generatePdfReport(
    List<HistoryEntry> history,
    DeviceIntegrityResult integrity, {
    String? password,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoMonoBold();
    final fontRegular = await PdfGoogleFonts.robotoMonoRegular();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: font),
        build: (pw.Context context) {
          return [
            _buildHeader(font),
            pw.SizedBox(height: 20),
            _buildIntegritySection(integrity, font),
            pw.SizedBox(height: 30),
            pw.Text('AUDIT TIMELINE', style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.black)),
            pw.SizedBox(height: 10),
            ...history.map((entry) => _buildTimelineEntry(entry, font, fontRegular)),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'PAGE ${context.pageNumber} OF ${context.pagesCount} | CONFIDENTIAL',
              style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _buildHeader(pw.Font font) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('SAFETEXT AUDIT', style: pw.TextStyle(font: font, fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
              child: pw.Text('CONFIDENTIAL', style: pw.TextStyle(font: font, fontSize: 10)),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('GENERATED: ${DateTime.now().toIso8601String()}', style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildIntegritySection(DeviceIntegrityResult integrity, pw.Font font) {
    final isCompromised = integrity.isRooted || !integrity.isSafe;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 2, color: isCompromised ? PdfColors.red : PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DEVICE INTEGRITY STATUS: ${isCompromised ? 'COMPROMISED' : 'SECURE'}',
              style: pw.TextStyle(font: font, fontSize: 12, color: isCompromised ? PdfColors.red : PdfColors.green700)),
          pw.SizedBox(height: 8),
          _integrityRow('ROOT ACCESS', integrity.isRooted ? 'DETECTED' : 'NONE', integrity.isRooted),
          _integrityRow('EMULATOR CHECK', integrity.isRealDevice ? 'PASSED' : 'FAILED', !integrity.isRealDevice),
          _integrityRow('DEVELOPER MODE', integrity.isDevMode ? 'ACTIVE' : 'DISABLED', integrity.isDevMode),
          _integrityRow('SYSTEM INTEGRITY', integrity.isSafe ? 'VERIFIED' : 'SUSPICIOUS', !integrity.isSafe),
        ],
      ),
    );
  }

  pw.Widget _integrityRow(String label, String value, bool isError) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, color: isError ? PdfColors.red : PdfColors.black, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildTimelineEntry(HistoryEntry entry, pw.Font fontBold, pw.Font fontRegular) {
    final isSuccess = entry.status == HistoryStatus.success;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 10,
                height: 10,
                decoration: pw.BoxDecoration(
                  color: isSuccess ? PdfColors.green : PdfColors.red,
                  border: pw.Border.all(width: 1),
                ),
              ),
              pw.Container(width: 1, height: 30, color: PdfColors.grey400),
            ],
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(entry.operation.name.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10)),
                    pw.Text(Formatters.timestamp(entry.timestamp), style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                  ],
                ),
                pw.Text('TOOL: ${entry.toolId.toString().split('.').last.toUpperCase()}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('TARGET: ${entry.imageName}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                if (entry.cipherAlgorithm != null)
                  pw.Text('ALGORITHM: ${entry.cipherAlgorithm}', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final exportServiceProvider = Provider((ref) => const ExportService());
