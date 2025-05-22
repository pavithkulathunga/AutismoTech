import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autismotech_app/utils/pdf_generator.dart';

/// Enhanced report generator with animation and user feedback
class ReportGenerationHelper {
  /// Shows an animated loading dialog while generating the report
  static Future<void> generateAndShareReport({
    required BuildContext context,
    required String result,
    required Map<String, int?> answers,
    required List<Map<String, dynamic>> questions,
    required String? imagePath,
    required AnimationController loadingController,
  }) async {
    bool dialogOpen = true;
    
    try {
      // Add haptic feedback
      HapticFeedback.mediumImpact();
      
      // Show enhanced loading dialog
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: loadingController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: loadingController.value * 2 * math.pi,
                      child: Container(
                        width: 50,
                        height: 50,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF39D8C9).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: Color(0xFF39D8C9),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Generating Report",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Creating a detailed PDF report of the diagnosis results...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 16),
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
      
      // Close loading dialog if still open
      if (dialogOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        dialogOpen = false;
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report generated successfully!'),
          backgroundColor: Color(0xFF39D8C9),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Add slight delay to improve UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Share PDF
      await PdfGenerator.sharePdf(pdfFile);
      
    } catch (e) {
      // Close loading dialog if still open
      if (dialogOpen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Rethrow for caller to handle if needed
      rethrow;
    }
  }
}
