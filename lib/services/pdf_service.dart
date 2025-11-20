import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/company_info.dart';

class PDFService {
  static const double pageMargin = 50.0;
  static const double headerHeight = 120.0;
  static const double footerHeight = 80.0;
  static double get availableHeight => PdfPageFormat.a4.height - (pageMargin * 2) - headerHeight - footerHeight;

  Future<Uint8List> generateInvoicePDF(InvoiceModel invoice) async {
    final pdf = pw.Document();
    // Always use placeholder - logo is optional
    // Skip logo loading to avoid any errors - placeholder will be shown
    pw.ImageProvider? logo;
    
    // Try to load logo only if needed (commented out for now - use placeholder)
    // Uncomment below when logo file is added to assets/logo/xloop_logo.png
    /*
    try {
      final logoData = await rootBundle.load(CompanyInfo.logoPath);
      final logoBytes = logoData.buffer.asUint8List();
      logo = pw.MemoryImage(logoBytes);
    } catch (e) {
      logo = null;
    }
    */

    // Load fonts for multilingual support
    pw.Font arabicFont;
    pw.Font arabicBoldFont;
    
    try {
      final arabicFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
      final arabicBoldFontData = await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf');
      
      // Verify fonts are not empty
      if (arabicFontData.lengthInBytes == 0 || arabicBoldFontData.lengthInBytes == 0) {
        throw Exception('Font files are empty');
      }
      
      // pw.Font.ttf expects ByteData directly
      arabicFont = pw.Font.ttf(arabicFontData);
      arabicBoldFont = pw.Font.ttf(arabicBoldFontData);
    } catch (e) {
      // Fallback: Use default fonts if Arabic fonts fail to load
      print('Warning: Failed to load Arabic fonts: $e');
      // Use default fonts - Arabic will show as symbols but won't crash
      arabicFont = pw.Font.helvetica();
      arabicBoldFont = pw.Font.helveticaBold();
    }

    // Calculate how many pages we need for line items (excluding first page)
    final lineItemsPerPage = _calculateLineItemsPerPage();
    var lineItemPages = (invoice.lineItems.length / lineItemsPerPage).ceil();
    if (invoice.lineItems.isEmpty) lineItemPages = 0;
    
    // Total pages = 1 (first page) + line item pages + 1 (totals page) + 1 (bank details page)
    // If no line items: 1 (first page) + 1 (totals page) + 1 (bank details page) = 3 pages
    final totalPages = invoice.lineItems.isEmpty 
        ? 3 
        : (1 + lineItemPages + 1 + 1); // First page + line item pages + totals page + bank details page
    var lineItemIndex = 0; // Track which line item we're on

    // Page 1: Header + Invoice Details + Bill To + Footer
    // If no line items, also show totals on first page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(pageMargin),
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Invoice Details and Bill To
                _buildInvoiceDetails(invoice),
                pw.SizedBox(height: 20),
                _buildBillToSection(invoice.customer),

                // Footer
                pw.Spacer(),
                _buildFooter(1, totalPages),
              ],
            );
        },
      ),
    );

    // Pages 2+: Header + Line Items + Footer
    for (int pageIndex = 0; pageIndex < lineItemPages; pageIndex++) {
      final startIndex = lineItemIndex;
      final endIndex = (startIndex + lineItemsPerPage).clamp(0, invoice.lineItems.length);
      final pageLineItems = invoice.lineItems.sublist(startIndex, endIndex);
      lineItemIndex = endIndex;
      final currentPageNumber = 2 + pageIndex; // Page 2, 3, 4, etc.

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(pageMargin),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header (on every page)
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Line Items Table
                _buildLineItemsTable(pageLineItems, startIndex + 1),

                // Footer (on every page)
                pw.Spacer(),
                _buildFooter(currentPageNumber, totalPages),
              ],
            );
          },
        ),
      );
    }

    // Last page with line items: Totals Section
    if (invoice.lineItems.isNotEmpty) {
      final totalsPageNumber = 2 + lineItemPages;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(pageMargin),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Totals Section
                _buildTotalsSection(invoice),

                // Footer
                pw.Spacer(),
                _buildFooter(totalsPageNumber, totalPages),
              ],
            );
          },
        ),
      );
    }

    // Bank Details Page (separate page after totals)
    if (invoice.lineItems.isNotEmpty) {
      final bankDetailsPageNumber = 2 + lineItemPages + 1;
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(pageMargin),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Bank Details
                _buildBankDetails(),

                // Footer
                pw.Spacer(),
                _buildFooter(bankDetailsPageNumber, totalPages),
              ],
            );
          },
        ),
      );
    } else {
      // If no line items: Page 2 = Totals, Page 3 = Bank Details
      // Add Totals page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(pageMargin),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Totals Section
                _buildTotalsSection(invoice),

                // Footer
                pw.Spacer(),
                _buildFooter(2, totalPages),
              ],
            );
          },
        ),
      );

      // Add Bank Details page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(pageMargin),
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicBoldFont,
          ),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                _buildHeader(logo),
                pw.SizedBox(height: 20),

                // Bank Details
                _buildBankDetails(),

                // Footer
                pw.Spacer(),
                _buildFooter(3, totalPages),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                CompanyInfo.companyNameEn,
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                CompanyInfo.companyNameEn2,
                style: pw.TextStyle(fontSize: 20),
              ),
            ],
          ),
          // Logo placeholder - always same size (60x60) to prevent layout issues
          // If logo is not available, shows placeholder with "XK" text
          pw.Column(
            children: [
              pw.Container(
                width: 60,
                height: 60,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: PdfColors.grey400, width: 2),
                  color: PdfColors.grey100,
                ),
                child: logo != null
                    ? pw.Image(logo, fit: pw.BoxFit.contain)
                    : pw.Center(
                        child: pw.Text(
                          'XK',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                CompanyInfo.crNumber,
                style: pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                CompanyInfo.companyNameAr,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                CompanyInfo.companyNameAr2,
                style: pw.TextStyle(fontSize: 20),
                textDirection: pw.TextDirection.rtl,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceDetails(InvoiceModel invoice) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 1.2),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'INVOICE',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'فاتورة',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ],
        ),
        // Date row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Date',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                dateFormat.format(invoice.date),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Invoice Number row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Invoice Number',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                invoice.invoiceNumber,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Contract reference row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Contract reference',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                invoice.contractReference,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Payment terms row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Payment terms',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                invoice.paymentTerms,
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildBillToSection(dynamic customer) {
    return pw.SizedBox(
      width: double.infinity,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1.2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
          pw.Text(
            'BILL TO:',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (customer != null) ...[
            pw.Text(
              customer.companyName,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${customer.streetAddress}, Building ${customer.buildingNumber}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              customer.addressAdditionalNumber != null &&
                      customer.addressAdditionalNumber!.isNotEmpty
                  ? '${customer.district}, Addl. No: ${customer.addressAdditionalNumber}'
                  : customer.district,
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              '${customer.city}, ${customer.postalCode}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.Text(
              customer.country,
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'VAT Treatment: ${customer.vatRegisteredInKSA ? 'VAT registered in KSA' : 'Not VAT registered in KSA'}',
              style: pw.TextStyle(fontSize: 9),
            ),
            pw.Text(
              'Tax Reg. No: ${customer.taxRegistrationNumber}',
              style: pw.TextStyle(fontSize: 9),
            ),
          ] else
            pw.Text(
              '(Customer Name & Address)',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateLineItemsPerPage() {
    // Approximate calculation: each row takes about 30 points
    // Available height minus space for other sections
    final availableSpace = availableHeight - 100; // Reserve space for other elements
    return (availableSpace / 30).floor().clamp(5, 20);
  }

  pw.Widget _buildLineItemsTable(List<dynamic> lineItems, int startIndex) {
    if (lineItems.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        child: pw.Text(
          'No line items',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.0),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('L/I\nالبند', isHeader: true, isArabic: false),
            _buildTableCell('DESCRIPTION\nالأوصاف', isHeader: true, isArabic: false),
            _buildTableCell('UNIT\nالوحدة', isHeader: true, isArabic: false),
            _buildTableCell('SUBTOTAL AMOUNT\nالمجموع الفرعي', isHeader: true, isArabic: false),
            _buildTableCell('DISCOUNT RATE 3%\nتخفيض', isHeader: true, isArabic: false),
            _buildTableCell('TOTAL AMOUNT\nالإجمالي', isHeader: true, isArabic: false),
          ],
        ),
        // Data rows
        ...lineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final rowNumber = startIndex + index;
          final currencyFormat = NumberFormat.currency(symbol: 'SR ', decimalDigits: 2);
          
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: rowNumber % 2 == 0 ? PdfColors.white : PdfColors.grey100,
            ),
            children: [
              _buildTableCell('$rowNumber\n${_toArabicNumber(rowNumber)}', isArabic: false),
              _buildTableCell(
                item.description.isNotEmpty 
                  ? '${item.description}\nرسوم خدمة التحويل' 
                  : 'TRANSPORTATION CHARGES\nرسوم خدمة التحويل', 
                isArabic: false
              ),
              _buildTableCell(
                item.unit.isNotEmpty 
                  ? '${item.unit}\nحبة' 
                  : '1 LOT\nحبة', 
                isArabic: false
              ),
              _buildTableCell(currencyFormat.format(item.subtotalAmount), isArabic: false, alignRight: true),
              _buildTableCell('${item.discountRate.toStringAsFixed(0)}%', isArabic: false, alignRight: true),
              _buildTableCell(currencyFormat.format(item.totalAmount), isArabic: false, alignRight: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isArabic = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicDigits[int.parse(digit)]).join();
  }

  pw.Widget _buildTotalsSection(InvoiceModel invoice) {
    final currencyFormat = NumberFormat.currency(symbol: 'SR ', decimalDigits: 2);
    
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Total: ${_numberToWords(invoice.totalAmount)} Only',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'المجموع: ${_numberToWordsArabic(invoice.totalAmount)} فقط',
                  style: pw.TextStyle(fontSize: 10),
                  textDirection: pw.TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _buildTotalRow('Total Amount:', currencyFormat.format(invoice.totalAmount), 'الإجمالي:', true),
                _buildTotalRow('WHT 5%:', currencyFormat.format(invoice.whtAmount), 'ضريبة:', true),
                pw.Divider(),
                _buildTotalRow('Grand Total:', currencyFormat.format(invoice.grandTotal), 'المجموع:', true, isBold: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String labelEn, String valueEn, String labelAr, bool showArabic, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '$labelEn $valueEn',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          if (showArabic)
            pw.Text(
              '$labelAr $valueEn',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
              textDirection: pw.TextDirection.rtl,
            ),
        ],
      ),
    );
  }

  pw.Widget _buildBankDetails() {
    return pw.SizedBox(
      width: double.infinity,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1.2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bank Details',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildBankDetailRow('Account Name:', CompanyInfo.accountName),
                      _buildBankDetailRow('Account Number:', CompanyInfo.accountNumber),
                      _buildBankDetailRow('IBAN:', CompanyInfo.iban),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Prepared By:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Muhammed Saleh',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildBankDetailRow('Bank Name:', CompanyInfo.bankName),
                      _buildBankDetailRow('SWIFT Code:', CompanyInfo.swiftCode),
                      _buildBankDetailRow('Currency:', CompanyInfo.currency),
                      pw.SizedBox(height: 40),
                      // Space for signature (will be added later)
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBankDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TRN No# ${CompanyInfo.trnNumber}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      CompanyInfo.addressEn,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Contact: ${CompanyInfo.contact}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Email: ${CompanyInfo.email}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'رقم الضريبة # ${CompanyInfo.trnNumberAr}',
                      style: pw.TextStyle(fontSize: 9),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      CompanyInfo.addressAr,
                      style: pw.TextStyle(fontSize: 9),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'الاتصال: ${CompanyInfo.contactAr}',
                      style: pw.TextStyle(fontSize: 9),
                      textDirection: pw.TextDirection.rtl,
                    ),
                    pw.Text(
                      'البريد الإلكتروني: ${CompanyInfo.email}',
                      style: pw.TextStyle(fontSize: 9),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              '$pageNumber',
              style: pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWords(double amount) {
    // Simple implementation - can be enhanced
    final rounded = amount.round();
    if (rounded == 0) return 'Zero';
    return '$rounded Saudi Riyals';
  }

  String _numberToWordsArabic(double amount) {
    // Simple implementation - can be enhanced
    final rounded = amount.round();
    if (rounded == 0) return 'صفر';
    return '$rounded ريال سعودي';
  }
}

