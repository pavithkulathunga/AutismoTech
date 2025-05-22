import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ReportGenerationHelper {
  static Future<void> generateAndShareReport({
    required BuildContext context,
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    String? imagePath,
    required AnimationController loadingController,
  }) async {
    print('ReportGenerationHelper.generateAndShareReport called');
    print('Image path: $imagePath');
    
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildLoadingDialog(context, loadingController),
    );
    
    try {
      print('Starting PDF generation');
      
      // Generate the PDF file
      final pdfFile = await _generatePdf(
        result: result,
        answers: answers,
        questions: questions,
        imagePath: imagePath,
      );
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Share the PDF file
      if (pdfFile != null) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          text: 'ASD Diagnosis Report',
        );
      } else {
        throw Exception('Failed to generate PDF file');
      }
    } catch (e) {
      // Close the loading dialog if it's still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Error in report generation: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw to be caught by the calling function
    }
  }

  static Widget _buildLoadingDialog(
    BuildContext context, 
    AnimationController controller,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CircularProgressIndicator(
                  valueColor: controller.drive(
                    ColorTween(
                      begin: const Color(0xFF32B4FF),
                      end: const Color(0xFF39D8C9),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Generating report...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<File?> _generatePdf({
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    String? imagePath,
  }) async {
    // Create a PDF document
    final pdf = pw.Document();
    
    // Add a logo or image if available (safely handling null)
    pw.MemoryImage? profileImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          final imageBytes = await imageFile.readAsBytes();
          profileImage = pw.MemoryImage(imageBytes);
        } else {
          print('Image file does not exist: $imagePath');
        }
      } catch (e) {
        print('Error loading image: $e');
        // Continue without the image
      }
    }
    
    // Add title page
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'ASD Diagnosis Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                if (profileImage != null)
                  pw.Container(
                    width: 200,
                    height: 200,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Image(profileImage),
                  ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Result: $result',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Add details page
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final List<pw.Widget> questionRows = [];
          
          for (final q in questions) {
            final String question = q['question'] as String;
            final String field = q['field'] as String;
            final int? answer = answers[field];
            
            String answerText = 'Not answered';
            if (answer != null) {
              if (field == 'feature10') {
                answerText = answer == 1 ? 'Always/Usually/Sometimes' : 'Rarely/Never';
              } else if (field == 'feature11') {
                answerText = answer == 1 ? 'Male' : 'Female';
              } else if (field == 'feature12') {
                answerText = answer == 1 ? 'Yes' : 'No';
              } else {
                answerText = answer == 0 ? 'Always/Usually' : 'Sometimes/Rarely/Never';
              }
            }
            
            questionRows.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.95, 0.95, 0.95),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      question,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Answer: $answerText'),
                  ],
                ),
              ),
            );
          }
          
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Questionnaire Responses',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              ...questionRows,
            ],
          );
        },
      ),
    );
    
    // Save the PDF to a file
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/asd_diagnosis_report.pdf');
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }
}
