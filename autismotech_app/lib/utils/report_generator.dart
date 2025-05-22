import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

class ReportGenerationHelper {
  // Add helper function to create lighter versions of PdfColor
  static PdfColor getLighterColor(PdfColor color, {double factor = 0.3}) {
    // Mix with white to create a lighter version
    return PdfColor(
      ((1.0 - factor) * color.red + factor * 1.0).clamp(0.0, 1.0),
      ((1.0 - factor) * color.green + factor * 1.0).clamp(0.0, 1.0),
      ((1.0 - factor) * color.blue + factor * 1.0).clamp(0.0, 1.0),
    );
  }

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
    
    // Define custom colors for autism-friendly design
    final PdfColor primaryColor = PdfColor.fromHex('#32B4FF'); // Calming blue
    final PdfColor secondaryColor = PdfColor.fromHex('#39D8C9'); // Soft teal
    final PdfColor accentColor = PdfColor.fromHex('#FFB347'); // Warm orange
    final PdfColor textColor = PdfColor.fromHex('#333333'); // Dark gray text
    final PdfColor lightBackgroundColor = PdfColor.fromHex('#F5FAFF'); // Light blue background
    
    // Get lighter versions of colors
    final PdfColor lighterPrimaryColor = getLighterColor(primaryColor);
    final PdfColor lighterSecondaryColor = getLighterColor(secondaryColor);
    final PdfColor lighterAccentColor = getLighterColor(accentColor);
    
    // Prepare fonts - Use default fonts instead of trying to load custom fonts
    pw.Font baseFont = pw.Font.helvetica();
    pw.Font boldFont = pw.Font.helveticaBold();
    
    // Create theme with default fonts
    final myTheme = pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
    );
    
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
    
    // Generate score based on answers
    final int totalAnswers = answers.values.where((v) => v != null).length;
    final int positiveScores = answers.values.where((v) => v == 1).length;
    final double scorePercentage = totalAnswers > 0 ? (positiveScores / totalAnswers) * 100 : 0;
    
    // Add cover page
    pdf.addPage(
      pw.Page(
        theme: myTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  lighterPrimaryColor,
                  PdfColors.white,
                ],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
            ),
            child: pw.Stack(
              children: [
                // Decorative elements
                pw.Positioned(
                  top: 30,
                  right: 30,
                  child: pw.Container(
                    width: 70,
                    height: 70,
                    decoration: pw.BoxDecoration(
                      color: lighterSecondaryColor,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Positioned(
                  bottom: 40,
                  left: 20,
                  child: pw.Container(
                    width: 50,
                    height: 50,
                    decoration: pw.BoxDecoration(
                      color: lighterAccentColor,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                
                // Main content
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 40),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Text(
                              'AutismoTech',
                              style: pw.TextStyle(
                                fontSize: 18,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 30),
                      pw.Center(
                        child: pw.Text(
                          'ASD Assessment Report',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 40),
                      if (profileImage != null)
                        pw.Center(
                          child: pw.Container(
                            width: 200,
                            height: 200,
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(20),
                              boxShadow: [
                                pw.BoxShadow(
                                  color: PdfColor.fromHex('#DDDDDD'),
                                  blurRadius: 10,
                                  offset: const PdfPoint(0, 5),
                                ),
                              ],
                              border: pw.Border.all(
                                color: PdfColors.white,
                                width: 5,
                              ),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 15,
                              verticalRadius: 15,
                              child: pw.Image(profileImage, fit: pw.BoxFit.cover),
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 50),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                        decoration: pw.BoxDecoration(
                          color: result.toLowerCase().contains('asd') 
                              ? lighterAccentColor
                              : lighterSecondaryColor,
                          borderRadius: pw.BorderRadius.circular(15),
                          boxShadow: [
                            pw.BoxShadow(
                              color: PdfColor.fromHex('#DDDDDD'),
                              blurRadius: 5,
                              offset: const PdfPoint(0, 3),
                            ),
                          ],
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Assessment Result',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              result,
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: result.toLowerCase().contains('asd') 
                                    ? PdfColor.fromHex('#E67E22')
                                    : PdfColor.fromHex('#27AE60'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 30),
                      pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(15),
                              decoration: pw.BoxDecoration(
                                color: lighterPrimaryColor,
                                borderRadius: pw.BorderRadius.circular(10),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Date Generated',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 15),
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(15),
                              decoration: pw.BoxDecoration(
                                color: lighterSecondaryColor,
                                borderRadius: pw.BorderRadius.circular(10),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Total Questions',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    questions.length.toString(),
                                    style: pw.TextStyle(
                                      fontSize: 16,
                                      fontWeight: pw.FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      pw.Center(
                        child: pw.Text(
                          'This report is generated by AutismoTech app and is intended for informational purposes only.\nIt does not substitute professional medical advice.',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: PdfColor.fromHex('#777777'),
                            fontStyle: pw.FontStyle.italic,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    // Add summary page
    pdf.addPage(
      pw.Page(
        theme: myTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  PdfColors.white,
                  lightBackgroundColor,
                ],
                begin: pw.Alignment.topCenter,
                end: pw.Alignment.bottomCenter,
              ),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'Assessment Summary',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Score visualization
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(15),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromHex('#DDDDDD'),
                          blurRadius: 5,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Assessment Score',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 15),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 100,
                              height: 100,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: PdfColors.white,
                                border: pw.Border.all(
                                  color: primaryColor,
                                  width: 8,
                                ),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '${scorePercentage.toInt()}%',
                                  style: pw.TextStyle(
                                    fontSize: 24,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 20),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _buildScoreLegendItem(
                              color: PdfColor.fromHex('#27AE60'), 
                              label: 'Low Concern'
                            ),
                            pw.SizedBox(width: 20),
                            _buildScoreLegendItem(
                              color: PdfColor.fromHex('#F39C12'), 
                              label: 'Medium Concern'
                            ),
                            pw.SizedBox(width: 20),
                            _buildScoreLegendItem(
                              color: PdfColor.fromHex('#E74C3C'), 
                              label: 'High Concern'
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  
                  // Interpretation and next steps
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(15),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromHex('#DDDDDD'),
                          blurRadius: 5,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'What Does This Mean?',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          result.toLowerCase().contains('asd')
                              ? 'The assessment indicates signs that may be consistent with Autism Spectrum Disorder (ASD). This screening tool identifies patterns of behavior that are common in children with ASD but is not a definitive diagnosis.'
                              : 'The assessment indicates behavioral patterns that may not be typical of Autism Spectrum Disorder (ASD). However, this is a screening tool only and cannot rule out ASD completely.',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textColor,
                            lineSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text(
                          'Recommended Next Steps',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildNextStepItem(
                          number: '1',
                          title: 'Consult a Specialist',
                          description: 'Schedule an appointment with a developmental pediatrician, child psychologist, or neurologist who specializes in ASD.',
                          color: primaryColor,
                        ),
                        _buildNextStepItem(
                          number: '2',
                          title: 'Early Intervention',
                          description: 'Look into early intervention services available in your area, which can make a significant difference in your child\'s development.',
                          color: primaryColor,
                        ),
                        _buildNextStepItem(
                          number: '3',
                          title: 'Join Support Groups',
                          description: 'Connect with other parents facing similar situations through local or online autism support groups.',
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  
                  // Resources
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: pw.BorderRadius.circular(15),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Helpful Resources',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        _buildResourceItem(
                          title: 'Autism Speaks',
                          url: 'www.autismspeaks.org',
                        ),
                        _buildResourceItem(
                          title: 'Autism Society',
                          url: 'www.autism-society.org',
                        ),
                        _buildResourceItem(
                          title: 'CDC Autism Information',
                          url: 'www.cdc.gov/ncbddd/autism',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
    // Add details page with questionnaire responses
    // This needs to be modified to ensure all questions are displayed
    pdf.addPage(
      pw.MultiPage(
        theme: myTheme,
        pageFormat: PdfPageFormat.a4,
        maxPages: 2, // Allow up to 2 pages for questions if needed
        build: (pw.Context context) {
          final List<pw.Widget> questionRows = [];
          
          // Debug info to help troubleshoot
          print('Total questions to include in PDF: ${questions.length}');
          
          for (int i = 0; i < questions.length; i++) {
            final Map<String, dynamic> q = questions[i];
            final String question = q['question'] as String;
            final String field = q['field'] as String;
            final int? answer = answers[field];
            
            print('Processing question ${i+1}: $question, field: $field, answer: $answer');
            
            String answerText = 'Not answered';
            bool isPositiveIndicator = false;
            
            if (answer != null) {
              if (field == 'feature10') {
                answerText = answer == 1 ? 'Always/Usually/Sometimes' : 'Rarely/Never';
                isPositiveIndicator = answer == 1;
              } else if (field == 'feature11') {
                answerText = answer == 1 ? 'Male' : 'Female';
                isPositiveIndicator = answer == 1;
              } else if (field == 'feature12') {
                answerText = answer == 1 ? 'Yes' : 'No';
                isPositiveIndicator = answer == 1;
              } else {
                answerText = answer == 0 ? 'Always/Usually' : 'Sometimes/Rarely/Never';
                isPositiveIndicator = answer == 1;
              }
            }
            
            questionRows.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                decoration: pw.BoxDecoration(
                  color: i % 2 == 0 ? PdfColors.white : lightBackgroundColor,
                  borderRadius: pw.BorderRadius.circular(10),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColor.fromHex('#DDDDDD'),
                      blurRadius: 3,
                      offset: const PdfPoint(0, 2),
                    ),
                  ],
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(10),
                          topRight: pw.Radius.circular(10),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 24,
                            height: 24,
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.Text(
                                '${i + 1}',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Expanded(
                            child: pw.Text(
                              question,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Response:',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: textColor,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: answer == null
                                  ? PdfColor.fromHex('#AAAAAA')
                                  : (isPositiveIndicator
                                      ? accentColor
                                      : secondaryColor),
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Text(
                              answerText,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                'Questionnaire Responses',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Questions and answers - all will be included due to MultiPage
            ...questionRows,
            
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColor.fromHex('#DDDDDD')),
            pw.SizedBox(height: 10),
            pw.Text(
              'Note: This questionnaire is based on common behavioral indicators associated with ASD. The responses provide a screening tool only and should be discussed with healthcare professionals.',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: PdfColor.fromHex('#777777'),
              ),
            ),
          ];
        },
      ),
    );
    
    // Add additional resources and information page
    pdf.addPage(
      pw.Page(
        theme: myTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [
                  lightBackgroundColor,
                  PdfColors.white,
                ],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Text(
                      'Additional Resources & Information',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Information boxes
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(15),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromHex('#DDDDDD'),
                          blurRadius: 5,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Understanding Autism Spectrum Disorder',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Autism Spectrum Disorder (ASD) is a complex developmental condition involving persistent challenges with social communication, restricted interests, and repetitive behavior. The effects of ASD and the severity of symptoms vary widely among individuals.',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textColor,
                            lineSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Early detection and intervention are crucial for improving outcomes. If you have concerns about your child\'s development, consult with healthcare professionals who can provide a comprehensive evaluation.',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textColor,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Common signs
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(15),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromHex('#DDDDDD'),
                          blurRadius: 5,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Common Signs of ASD',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        
                        _buildASDSignItem(
                          category: 'Social Communication',
                          signs: [
                            'Difficulty with back-and-forth conversation',
                            'Reduced sharing of interests or emotions',
                            'Challenges with nonverbal communication',
                            'Difficulties developing and maintaining relationships',
                          ],
                          color: primaryColor,
                        ),
                        
                        _buildASDSignItem(
                          category: 'Restricted & Repetitive Behaviors',
                          signs: [
                            'Repetitive movements or speech',
                            'Insistence on sameness and routines',
                            'Highly restricted interests',
                            'Unusual sensory sensitivities or interests',
                          ],
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  
                  // Support strategies
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(15),
                      boxShadow: [
                        pw.BoxShadow(
                          color: PdfColor.fromHex('#DDDDDD'),
                          blurRadius: 5,
                          offset: const PdfPoint(0, 3),
                        ),
                      ],
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Supporting Your Child',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        pw.Text(
                          'Every child with ASD is unique and will benefit from different approaches. Here are some general strategies that can help:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textColor,
                            lineSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 10),
                        
                        _buildSupportStrategyItem(
                          strategy: 'Create a structured environment with consistent routines',
                          color: secondaryColor,
                        ),
                        _buildSupportStrategyItem(
                          strategy: 'Use visual supports to enhance communication',
                          color: secondaryColor,
                        ),
                        _buildSupportStrategyItem(
                          strategy: 'Break tasks into smaller, manageable steps',
                          color: secondaryColor,
                        ),
                        _buildSupportStrategyItem(
                          strategy: 'Identify and minimize sensory triggers',
                          color: secondaryColor,
                        ),
                        _buildSupportStrategyItem(
                          strategy: 'Celebrate strengths and special interests',
                          color: secondaryColor,
                        ),
                      ],
                    ),
                  ),
                  
                  pw.Spacer(),
                  pw.Center(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Text(
                        'AutismoTech - Supporting autism awareness and early detection',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
  
  // Helper widget builders for the PDF report
  
  static pw.Widget _buildScoreLegendItem({required PdfColor color, required String label}) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          color: color,
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#555555'),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildNextStepItem({
    required String number,
    required String title,
    required String description,
    required PdfColor color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 22,
            height: 22,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                number,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#333333'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  description,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#555555'),
                    lineSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildResourceItem({required String title, required String url}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#333333'),
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#333333'),
            ),
          ),
          pw.Text(
            ' - ',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromHex('#333333'),
            ),
          ),
          pw.Text(
            url,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromHex('#0066CC'),
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildASDSignItem({
    required String category,
    required List<String> signs,
    required PdfColor color,
  }) {
    final lighterColor = getLighterColor(color);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: lighterColor,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(
              category,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          ...signs.map((sign) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5, left: 10),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 5,
                  height: 5,
                  margin: const pw.EdgeInsets.only(top: 4),
                  decoration: pw.BoxDecoration(
                    color: color,
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text(
                    sign,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromHex('#555555'),
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
  
  static pw.Widget _buildSupportStrategyItem({
    required String strategy,
    required PdfColor color,
  }) {
    final lighterColor = getLighterColor(color);
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 15,
            height: 15,
            decoration: pw.BoxDecoration(
              color: lighterColor,
              shape: pw.BoxShape.circle,
              border: pw.Border.all(
                color: color,
                width: 2,
              ),
            ),
            margin: const pw.EdgeInsets.only(top: 2),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              strategy,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#444444'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
