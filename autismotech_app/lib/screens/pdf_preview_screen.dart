import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File pdfFile;
  final String dateFormatted;

  const PdfPreviewScreen({
    Key? key,
    required this.pdfFile,
    required this.dateFormatted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Happy Hills Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open PDF',
            onPressed: () => _openPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              try {
                final result = await Share.shareXFiles(
                  [XFile(pdfFile.path)],
                  subject: 'Happy Hills Emotion Report - $dateFormatted',
                  text:
                      'Here is the emotion report from the Happy Hills game session.',
                );
                print('Share result: ${result.status}');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.info_outline, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'You can pinch to zoom, swipe to navigate pages, and use the buttons above to share or open the report.',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // PDF Preview
          Expanded(
            child: PdfPreview(
              build: (_) => pdfFile.readAsBytes(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              previewPageMargin: const EdgeInsets.all(10),
              initialPageFormat: PdfPageFormat.a4,
              pdfFileName: 'Happy_Hills_Report_$dateFormatted.pdf',
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your report...',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom actions bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.print,
                  label: 'Print',
                  onTap: () async {
                    await Printing.layoutPdf(
                      onLayout: (_) => pdfFile.readAsBytes(),
                      name: 'Happy Hills Report',
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.download,
                  label: 'Save',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report saved to ${pdfFile.path}'),
                        action: SnackBarAction(label: 'OK', onPressed: () {}),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () async {
                    try {
                      final result = await Share.shareXFiles(
                        [XFile(pdfFile.path)],
                        subject: 'Happy Hills Emotion Report - $dateFormatted',
                        text:
                            'Here is the emotion report from the Happy Hills game session.',
                      );
                      print('Share result: ${result.status}');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error sharing: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(BuildContext context) async {
    try {
      final result = await OpenFilex.open(pdfFile.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open PDF file')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
