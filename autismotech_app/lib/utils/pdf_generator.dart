import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfGenerator {
  static Future<File> generateDiagnosisReport({
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    String? imagePath,
  }) async {
    final pdf = pw.Document();
    final ByteData logoData = await rootBundle.load('assets/icons/app_icon.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    // Format the current date
    final now = DateTime.now();
    final formatter = DateFormat('MMMM d, yyyy');
    final formattedDate = formatter.format(now);

    pw.Widget? imageWidget;
    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final image = pw.MemoryImage(imageBytes);
          imageWidget = pw.Container(
            height: 200,
            width: 200,
            alignment: pw.Alignment.center,
            child: pw.Image(image, fit: pw.BoxFit.contain),
          );
        }
      } catch (e) {
        print('Error loading image: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header with logo and title
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Image(pw.MemoryImage(logoBytes),
                          width: 50, height: 50),
                      pw.SizedBox(width: 10),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('AutismoTech',
                              style: pw.TextStyle(
                                  fontSize: 24, fontWeight: pw.FontWeight.bold)),
                          pw.Text('ASD Diagnosis Report',
                              style: pw.TextStyle(
                                  fontSize: 16,
                                  fontStyle: pw.FontStyle.italic)),
                        ],
                      ),
                    ],
                  ),
                  pw.Text('Generated on: $formattedDate',
                      style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Result section
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Diagnosis Result',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(result, style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Image if available
            if (imageWidget != null) ...[
              pw.Center(child: imageWidget),
              pw.SizedBox(height: 20),
            ],
            
            // Questionnaire responses
            pw.Text('Assessment Responses',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FractionColumnWidth(0.7),
                1: const pw.FractionColumnWidth(0.3),
              },
              children: [
                // Table header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Question',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Response',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                
                // Table rows with questions and answers
                ...questions.map((question) {
                  final fieldName = question['field'] as String;
                  final questionText = question['question'] as String;
                  int? answerValue = answers[fieldName];
                  String answerText = 'Not answered';
                  
                  if (answerValue != null) {
                    if (fieldName == 'feature10') {
                      answerText = answerValue == 1
                          ? 'Always/Usually/Sometimes'
                          : 'Rarely/Never';
                    } else if (fieldName == 'feature11') {
                      answerText = answerValue == 1 ? 'Male' : 'Female';
                    } else if (fieldName == 'feature12') {
                      answerText = answerValue == 1 ? 'Yes' : 'No';
                    } else {
                      answerText = answerValue == 0
                          ? 'Always/Usually'
                          : 'Sometimes/Rarely/Never';
                    }
                  }
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(questionText),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(answerText),
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Disclaimer
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Important Note:',
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'This report is generated based on the screening tool used within the AutismoTech application. '
                    'It should not be considered as a definitive medical diagnosis. '
                    'Please consult with a qualified healthcare professional for a comprehensive evaluation.',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            
            // Footer
            pw.Footer(
              leading: pw.Text('AutismoTech - Helping with early detection',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              trailing: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ),
          ];
        },
      ),
    );

    // Get directory for saving file
    final output = await getTemporaryDirectory();
    final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final String filename = 'autism_diagnosis_report_$timestamp.pdf';
    final file = File('${output.path}/$filename');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> sharePdf(File pdf) async {
    await Share.shareXFiles([XFile(pdf.path)], text: 'ASD Diagnosis Report');
  }
}
