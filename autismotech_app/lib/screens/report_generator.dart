import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autismotech_app/utils/pdf_generator.dart';

/// This class is deprecated. Use ReportGenerationHelper from utils/report_generator.dart instead.
@Deprecated('Use ReportGenerationHelper from utils/report_generator.dart instead')
class ReportGenerationHelper {
  
  /// Shows an animated loading dialog while generating the report
  /// This method is deprecated. Use the version in utils/report_generator.dart instead.
  @Deprecated('Use the version in utils/report_generator.dart instead')
  static Future<void> generateAndShareReport({
    required BuildContext context,
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    required String? imagePath,
    required AnimationController loadingController,
  }) async {
    // Import the actual implementation
    await _redirectToCorrectImplementation(
      context: context,
      result: result,
      answers: answers,
      questions: questions,
      imagePath: imagePath,
      loadingController: loadingController
    );
  }
  
  static Future<void> _redirectToCorrectImplementation({
    required BuildContext context,
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    required String? imagePath,
    required AnimationController loadingController,
  }) async {
    try {
      // Redirect to correct implementation
      print('Warning: Using deprecated ReportGenerationHelper, redirecting to correct implementation');
      final actualHelper = await import('package:autismotech_app/utils/report_generator.dart');
      await actualHelper.ReportGenerationHelper.generateAndShareReport(
        context: context,
        result: result,
        answers: answers,
        questions: questions,
        imagePath: imagePath,
        loadingController: loadingController,
      );
    } catch (e) {
      print('Error redirecting to correct implementation: $e');
      // Fallback implementation
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
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
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text("Generating Report"),
                ],
              ),
            ),
          ),
        );
        
        // Generate PDF
        final File pdfFile = await PdfGenerator.generateDiagnosisReport(
          result: result,
          answers: answers,
          questions: questions,
          imagePath: imagePath,
        );
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        // Share PDF
        await PdfGenerator.sharePdf(pdfFile);
      } catch (fallbackError) {
        // Handle errors in fallback implementation
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $fallbackError')),
        );
      }
    }
  }
}
