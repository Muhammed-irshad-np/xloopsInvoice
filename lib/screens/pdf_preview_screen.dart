import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../services/pdf_service.dart';

class PDFPreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;

  const PDFPreviewScreen({super.key, required this.invoice});

  Future<void> _savePDF() async {
    try {
      final pdfService = PDFService();
      final pdfBytes = await pdfService.generateInvoicePDF(invoice);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      if (file.existsSync()) {
        // Show success message
        // Note: In a real app, you might want to use a snackbar or dialog
        debugPrint('PDF saved to: ${file.path}');
      }
    } catch (e) {
      debugPrint('Error saving PDF: $e');
    }
  }

  Future<void> _sharePDF() async {
    try {
      final pdfService = PDFService();
      final pdfBytes = await pdfService.generateInvoicePDF(invoice);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'invoice_${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(pdfBytes);
      
      if (file.existsSync()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Invoice ${invoice.invoiceNumber}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePDF,
            tooltip: 'Save PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF,
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: FutureBuilder<List<int>>(
        future: PDFService().generateInvoicePDF(invoice),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error generating PDF: ${snapshot.error}'),
                ],
              ),
            );
          }
          
          final pdfBytes = Uint8List.fromList(snapshot.data!);
          
          return PdfPreview(
            build: (format) async => pdfBytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}

