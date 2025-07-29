import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/quote.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';
import '../models/client.dart';
import '../models/company.dart';

class PdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF667eea);
  static const PdfColor accentColor = PdfColor.fromInt(0xFF764ba2);
  static const PdfColor textColor = PdfColor.fromInt(0xFF2C2C54);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF5F5F5);

  /// Generate and print/save a quote PDF
  static Future<void> generateQuotePdf({
    required Quote quote,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = await _createQuotePdf(quote, client, company);
      
      // Use quote ID if quoteNumber is empty or null
      final fileName = quote.quoteNumber.isNotEmpty 
          ? 'Quote_${quote.quoteNumber}.pdf'
          : 'Quote_${quote.id ?? 'unknown'}.pdf';
      
      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final pdfBytes = await pdf.save();
            return pdfBytes;
          },
          name: fileName,
        );
      } else {
        await _savePdfToFile(pdf, fileName);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate and print/save an invoice PDF
  static Future<void> generateInvoicePdf({
    required Invoice invoice,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = await _createInvoicePdf(invoice, client, company);
      
      // Use invoice ID if invoiceNumber is empty or null
      final fileName = invoice.invoiceNumber.isNotEmpty 
          ? 'Invoice_${invoice.invoiceNumber}.pdf'
          : 'Invoice_${invoice.id ?? 'unknown'}.pdf';
      
      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final pdfBytes = await pdf.save();
            return pdfBytes;
          },
          name: fileName,
        );
      } else {
        await _savePdfToFile(pdf, fileName);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate and print/save a receipt PDF
  static Future<void> generateReceiptPdf({
    required Receipt receipt,
    required Invoice invoice,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = await _createReceiptPdf(receipt, invoice, client, company);
      
      // Use receipt ID if receiptNumber is empty or null
      final fileName = receipt.receiptNumber.isNotEmpty 
          ? 'Receipt_${receipt.receiptNumber}.pdf'
          : 'Receipt_${receipt.id ?? 'unknown'}.pdf';
      
      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final pdfBytes = await pdf.save();
            return pdfBytes;
          },
          name: fileName,
        );
      } else {
        await _savePdfToFile(pdf, fileName);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create quote PDF document
  static Future<pw.Document> _createQuotePdf(Quote quote, Client client, Company company) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      // Ensure all string values are not null
      final safeQuoteNumber = quote.quoteNumber.isNotEmpty ? quote.quoteNumber : '#${quote.id ?? 'unknown'}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(company, 'QUOTE', safeQuoteNumber, boldFont, font),
              pw.SizedBox(height: 30),
              
              // Client and Quote Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildClientInfo(client, font, boldFont),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: _buildQuoteInfo(quote, font, boldFont),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Items Table - only if items exist
              if (quote.items.isNotEmpty) ...[
                _buildItemsTable(quote.items.map((item) => {
                  'description': item.description.toString(),
                  'quantity': item.quantity.toString(),
                  'unitPrice': 'E${item.unitPrice.toStringAsFixed(2)}',
                  'total': 'E${item.totalPrice.toStringAsFixed(2)}',
                }).toList(), font, boldFont),
                pw.SizedBox(height: 20),
              ],
              
              // Totals
              _buildTotals([
                {'label': 'Subtotal', 'value': 'E${quote.subtotal.toStringAsFixed(2)}'},
                {'label': 'Tax (${quote.subtotal > 0 ? (quote.taxAmount / quote.subtotal * 100).toStringAsFixed(1) : '0.0'}%)', 'value': 'E${quote.taxAmount.toStringAsFixed(2)}'},
                {'label': 'Total', 'value': 'E${quote.totalAmount.toStringAsFixed(2)}', 'bold': true},
              ], font, boldFont),
              
              if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 30),
                _buildNotes(quote.notes!, font, boldFont),
              ],
              
              pw.SizedBox(height: 30),
              _buildFooter(company, font),
            ];
          },
        ),
      );

      return pdf;
    } catch (e) {
      throw Exception('Failed to create quote PDF: $e');
    }
  }

  /// Create invoice PDF document
  static Future<pw.Document> _createInvoicePdf(Invoice invoice, Client client, Company company) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final safeInvoiceNumber = invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : '#${invoice.id ?? 'unknown'}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              _buildHeader(company, 'INVOICE', safeInvoiceNumber, boldFont, font),
              pw.SizedBox(height: 30),
              
              // Client and Invoice Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _buildClientInfo(client, font, boldFont),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: _buildInvoiceInfo(invoice, font, boldFont),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Items Table - only if items exist
              if (invoice.items.isNotEmpty) ...[
                _buildItemsTable(invoice.items.map((item) => {
                  'description': item.description.toString(),
                  'quantity': item.quantity.toString(),
                  'unitPrice': 'E${item.unitPrice.toStringAsFixed(2)}',
                  'total': 'E${item.totalPrice.toStringAsFixed(2)}',
                }).toList(), font, boldFont),
                pw.SizedBox(height: 20),
              ],
              
              // Totals
              _buildTotals([
                {'label': 'Subtotal', 'value': 'E${invoice.subtotal.toStringAsFixed(2)}'},
                {'label': 'Tax (${invoice.subtotal > 0 ? (invoice.taxAmount / invoice.subtotal * 100).toStringAsFixed(1) : '0.0'}%)', 'value': 'E${invoice.taxAmount.toStringAsFixed(2)}'},
                {'label': 'Total', 'value': 'E${invoice.totalAmount.toStringAsFixed(2)}', 'bold': true},
                if (invoice.paidAmount > 0) {'label': 'Paid', 'value': 'E${invoice.paidAmount.toStringAsFixed(2)}'},
                if ((invoice.totalAmount - invoice.paidAmount) > 0) {'label': 'Remaining', 'value': 'E${(invoice.totalAmount - invoice.paidAmount).toStringAsFixed(2)}', 'bold': true},
              ], font, boldFont),
              
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 30),
                _buildNotes(invoice.notes!, font, boldFont),
              ],
              
              pw.SizedBox(height: 30),
              _buildFooter(company, font),
            ];
          },
        ),
      );

      return pdf;
    } catch (e) {
      throw Exception('Failed to create invoice PDF: $e');
    }
  }

  /// Create receipt PDF document
  static Future<pw.Document> _createReceiptPdf(Receipt receipt, Invoice invoice, Client client, Company company) async {
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();

      final safeReceiptNumber = receipt.receiptNumber.isNotEmpty ? receipt.receiptNumber : '#${receipt.id ?? 'unknown'}';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(company, 'RECEIPT', safeReceiptNumber, boldFont, font),
                pw.SizedBox(height: 30),
                
                // Receipt Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _buildClientInfo(client, font, boldFont),
                    ),
                    pw.SizedBox(width: 40),
                    pw.Expanded(
                      child: _buildReceiptInfo(receipt, invoice, font, boldFont),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),
                
                // Payment Details
                _buildPaymentDetails(receipt, font, boldFont),
                
                pw.Spacer(),
                _buildFooter(company, font),
              ],
            );
          },
        ),
      );

      return pdf;
    } catch (e) {
      throw Exception('Failed to create receipt PDF: $e');
    }
  }

  /// Build document header
  static pw.Widget _buildHeader(Company company, String documentType, String documentNumber, pw.Font boldFont, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              company.name.isNotEmpty ? company.name : 'Company Name',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 24,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 5),
            if (company.address.isNotEmpty)
              pw.Text(company.address, style: pw.TextStyle(font: font, fontSize: 10)),
            if (company.phone.isNotEmpty)
              pw.Text('Phone: ${company.phone}', style: pw.TextStyle(font: font, fontSize: 10)),
            if (company.email.isNotEmpty)
              pw.Text('Email: ${company.email}', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              documentType,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 28,
                color: accentColor,
              ),
            ),
            pw.Text(
              documentNumber.isNotEmpty ? documentNumber : 'N/A',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build client information section
  static pw.Widget _buildClientInfo(Client client, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Bill To:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Text(client.name.isNotEmpty ? client.name : 'Client Name', style: pw.TextStyle(font: boldFont, fontSize: 12)),
        if (client.email.isNotEmpty)
          pw.Text(client.email, style: pw.TextStyle(font: font, fontSize: 10)),
        if (client.phone.isNotEmpty)
          pw.Text(client.phone, style: pw.TextStyle(font: font, fontSize: 10)),
        if (client.address.isNotEmpty)
          pw.Text(client.address, style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Build quote information section
  static pw.Widget _buildQuoteInfo(Quote quote, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Quote Details:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Text('Date: ${_formatDate(quote.quoteDate)}', style: pw.TextStyle(font: font, fontSize: 10)),
        if (quote.expiryDate != null)
          pw.Text('Expires: ${_formatDate(quote.expiryDate!)}', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Status: ${_capitalizeFirst(quote.status)}', style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Build invoice information section
  static pw.Widget _buildInvoiceInfo(Invoice invoice, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Invoice Details:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Text('Date: ${_formatDate(invoice.invoiceDate)}', style: pw.TextStyle(font: font, fontSize: 10)),
        if (invoice.dueDate != null)
          pw.Text('Due: ${_formatDate(invoice.dueDate!)}', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Status: ${_capitalizeFirst(invoice.status)}', style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Build receipt information section
  static pw.Widget _buildReceiptInfo(Receipt receipt, Invoice invoice, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Receipt Details:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Text('Date: ${_formatDate(receipt.createdAt ?? DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Invoice: ${invoice.invoiceNumber}', style: pw.TextStyle(font: font, fontSize: 10)),
        pw.Text('Method: ${_capitalizeFirst(receipt.paymentMethod)}', style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<Map<String, String>> items, pw.Font font, pw.Font boldFont) {
    return pw.Table(
      border: pw.TableBorder.all(color: lightGray),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightGray),
          children: [
            _buildTableCell('Description', boldFont, isHeader: true),
            _buildTableCell('Qty', boldFont, isHeader: true, align: pw.Alignment.center),
            _buildTableCell('Unit Price', boldFont, isHeader: true, align: pw.Alignment.centerRight),
            _buildTableCell('Total', boldFont, isHeader: true, align: pw.Alignment.centerRight),
          ],
        ),
        // Items
        ...items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item['description']!, font),
            _buildTableCell(item['quantity']!, font, align: pw.Alignment.center),
            _buildTableCell(item['unitPrice']!, font, align: pw.Alignment.centerRight),
            _buildTableCell(item['total']!, font, align: pw.Alignment.centerRight),
          ],
        )),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false, pw.Alignment align = pw.Alignment.centerLeft}) {    
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: align,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: textColor,
        ),
      ),
    );
  }

  /// Build totals section
  static pw.Widget _buildTotals(List<Map<String, dynamic>> totals, pw.Font font, pw.Font boldFont) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: totals.map((total) {
            final isBold = total['bold'] == true;
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: isBold ? const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: lightGray)),
              ) : null,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    total['label'],
                    style: pw.TextStyle(
                      font: isBold ? boldFont : font,
                      fontSize: isBold ? 12 : 10,
                      color: textColor,
                    ),
                  ),
                  pw.Text(
                    total['value'],
                    style: pw.TextStyle(
                      font: isBold ? boldFont : font,
                      fontSize: isBold ? 12 : 10,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build payment details for receipt
  static pw.Widget _buildPaymentDetails(Receipt receipt, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Payment Details', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Amount Paid:', style: pw.TextStyle(font: font, fontSize: 12)),
              pw.Text('E${receipt.amount.toStringAsFixed(2)}', style: pw.TextStyle(font: boldFont, fontSize: 16, color: primaryColor)),
            ],
          ),
          if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Notes:', style: pw.TextStyle(font: boldFont, fontSize: 10)),
            pw.Text(receipt.notes!, style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  /// Build notes section
  static pw.Widget _buildNotes(String notes, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Notes:', style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryColor)),
        pw.SizedBox(height: 5),
        pw.Text(notes, style: pw.TextStyle(font: font, fontSize: 10)),
      ],
    );
  }

  /// Build footer
  static pw.Widget _buildFooter(Company company, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(color: lightGray),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(font: font, fontSize: 12, color: primaryColor),
          textAlign: pw.TextAlign.center,
        ),
        if (company.name.isNotEmpty)
          pw.Text(
            company.name,
            style: pw.TextStyle(font: font, fontSize: 10, color: textColor),
            textAlign: pw.TextAlign.center,
          ),
      ],
    );
  }

  /// Save PDF to file
  static Future<void> _savePdfToFile(pw.Document pdf, String filename) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/$filename';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
  }

  /// Format date helper
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Capitalize first letter helper
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
