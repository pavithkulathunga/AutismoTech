import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
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
        title: const Text('Report Preview'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share PDF',
            onPressed: () async {
              final result = await Share.shareXFiles(
                [XFile(pdfFile.path)],
                subject: 'Happy Hills Emotion Report - $dateFormatted',
                text:
                    'Here is the emotion report from the Happy Hills game session.',
              );
              print('Share result: ${result.status}');
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => pdfFile.readAsBytes(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }

  void _openPdf(BuildContext context) async {
    try {
      final result = await OpenFilex.open(pdfFile.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open PDF file')));
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
