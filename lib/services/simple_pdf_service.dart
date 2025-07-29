import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/quote.dart';
import '../models/invoice.dart';
import '../models/receipt.dart';
import '../models/client.dart';
import '../models/company.dart';

class SimplePdfService {
  // Professional color scheme
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF1565C0); // Deep Blue
  static const PdfColor accentColor = PdfColor.fromInt(0xFF0D47A1); // Darker Blue
  static const PdfColor textColor = PdfColor.fromInt(0xFF212121); // Dark Gray
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor successColor = PdfColor.fromInt(0xFF2E7D32); // Green

  /// Generate and print/save a quote PDF - Ultra Simple version
  static Future<void> generateQuotePdf({
    required Quote quote,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Create simple content - all fields are non-nullable so direct access
      final quoteNum = quote.quoteNumber.isEmpty ? quote.id.toString() : quote.quoteNumber;
      final clientName = client.name.isEmpty ? 'Client' : client.name;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(company, quoteNum),
                pw.SizedBox(height: 30),
                
                // Client and Quote Info Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Client Information
                    pw.Expanded(
                      flex: 2,
                      child: _buildClientSection(clientName, client),
                    ),
                    pw.SizedBox(width: 40),
                    // Quote Information
                    pw.Expanded(
                      flex: 1,
                      child: _buildQuoteSection(quote),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Items Table
                _buildItemsTable(quote.items),
                
                pw.SizedBox(height: 30),
                
                // Totals Section
                _buildTotalsSection(quote),
                
                pw.SizedBox(height: 40),
                
                // Terms and Footer
                _buildFooter(company),
              ],
            );
          },
        ),
      );

      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final pdfBytes = await pdf.save();
            return pdfBytes;
          },
          name: 'Quote_$quoteNum.pdf',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate and print/save an invoice PDF - Ultra Simple version
  static Future<void> generateInvoicePdf({
    required Invoice invoice,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = pw.Document();
      
      final invoiceNum = invoice.invoiceNumber.isEmpty ? invoice.id.toString() : invoice.invoiceNumber;
      final companyName = company.name.isEmpty ? 'Company' : company.name;
      final clientName = client.name.isEmpty ? 'Client' : client.name;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('INVOICE'),
                pw.SizedBox(height: 20),
                pw.Text('Invoice Number: $invoiceNum'),
                pw.Text('Company: $companyName'),
                pw.Text('Client: $clientName'),
                pw.Text('Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
                pw.Text('Status: ${invoice.status}'),
                pw.SizedBox(height: 20),
                pw.Text('Items:'),
                ...invoice.items.map((item) {
                  final desc = item.description.isEmpty ? 'Item' : item.description;
                  return pw.Text('$desc - Qty: ${item.quantity} - Price: E${item.unitPrice.toStringAsFixed(2)} - Total: E${item.totalPrice.toStringAsFixed(2)}');
                }),
                pw.SizedBox(height: 20),
                pw.Text('Subtotal: E${invoice.subtotal.toStringAsFixed(2)}'),
                pw.Text('Tax: E${invoice.taxAmount.toStringAsFixed(2)}'),
                pw.Text('Total: E${invoice.totalAmount.toStringAsFixed(2)}'),
                pw.Text('Paid: E${invoice.paidAmount.toStringAsFixed(2)}'),
                pw.Text('Remaining: E${(invoice.totalAmount - invoice.paidAmount).toStringAsFixed(2)}'),
              ],
            );
          },
        ),
      );

      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: 'Invoice_$invoiceNum.pdf',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Generate and print/save a receipt PDF - Professional version
  static Future<void> generateReceiptPdf({
    required Receipt receipt,
    required Invoice invoice,
    required Client client,
    required Company company,
    bool showPrintDialog = true,
  }) async {
    try {
      final pdf = pw.Document();
      
      final receiptId = receipt.id?.toString() ?? 'N/A';
      final clientName = client.name.isEmpty ? 'Client' : client.name;
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildReceiptHeader(company, receiptId),
                pw.SizedBox(height: 30),
                
                // Receipt and Client Info Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Client Information
                    pw.Expanded(
                      flex: 2,
                      child: _buildClientSection(clientName, client),
                    ),
                    pw.SizedBox(width: 40),
                    // Receipt Information
                    pw.Expanded(
                      flex: 1,
                      child: _buildReceiptSection(receipt, invoice),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 40),
                
                // Payment Details Table
                _buildPaymentDetailsTable(receipt, invoice),
                
                pw.SizedBox(height: 40),
                
                // Footer
                _buildReceiptFooter(company),
              ],
            );
          },
        ),
      );

      if (showPrintDialog) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async {
            final pdfBytes = await pdf.save();
            return pdfBytes;
          },
          name: 'Receipt_$receiptId.pdf',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Build professional header with company branding
  static pw.Widget _buildHeader(Company company, String quoteNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [primaryColor, accentColor],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              if (company.phone.isNotEmpty)
                pw.Text(
                  company.phone,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              if (company.email.isNotEmpty)
                pw.Text(
                  company.email,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'QUOTATION',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                quoteNumber,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build client information section
  static pw.Widget _buildClientSection(String clientName, Client client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
        color: lightGray,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'BILL TO:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            clientName,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
          pw.SizedBox(height: 4),
          if (client.company != null && client.company!.isNotEmpty)
            pw.Text(
              client.company!,
              style: pw.TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Text(
            client.email,
            style: pw.TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            client.phone,
            style: pw.TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
          if (client.address.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              client.address,
              style: pw.TextStyle(
                fontSize: 12,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build quote information section
  static pw.Widget _buildQuoteSection(Quote quote) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'QUOTE DETAILS:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildDetailRow('Date:', _formatDate(quote.quoteDate)),
          pw.SizedBox(height: 6),
          if (quote.expiryDate != null)
            _buildDetailRow('Valid Until:', _formatDate(quote.expiryDate!)),
          pw.SizedBox(height: 6),
          _buildDetailRow('Status:', _capitalizeFirst(quote.status)),
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List items) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'DESCRIPTION',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'QTY',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'PRICE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isEven = index % 2 == 0;
            
            return pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: isEven ? PdfColors.white : lightGray,
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      item.description.isEmpty ? 'Service Item' : item.description,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      item.quantity.toString(),
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'E${item.unitPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: textColor,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'E${item.totalPrice.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build totals section
  static pw.Widget _buildTotalsSection(Quote quote) {
    return pw.Row(
      children: [
        pw.Expanded(child: pw.Container()),
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: borderColor),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', 'E${quote.subtotal.toStringAsFixed(2)}', false),
              pw.SizedBox(height: 8),
              _buildTotalRow('Tax:', 'E${quote.taxAmount.toStringAsFixed(2)}', false),
              pw.SizedBox(height: 12),
              pw.Divider(color: borderColor),
              pw.SizedBox(height: 8),
              _buildTotalRow('TOTAL:', 'E${quote.totalAmount.toStringAsFixed(2)}', true),
            ],
          ),
        ),
      ],
    );
  }

  /// Build footer with terms
  static pw.Widget _buildFooter(Company company) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderColor),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TERMS & CONDITIONS:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '- This quote is valid for 30 days from the date of issue\n'
                '- Payment terms: 50% deposit required, balance on completion\n'
                '- Prices include all applicable taxes unless otherwise stated\n'
                '- Changes to scope may affect pricing and timeline',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'Thank you for choosing ${company.name}--- Invoice Generated by EBS',
            style: pw.TextStyle(
              fontSize: 12,
              fontStyle: pw.FontStyle.italic,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build detail rows
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            color: textColor,
          ),
        ),
      ],
    );
  }

  /// Helper method to build total rows
  static pw.Widget _buildTotalRow(String label, String value, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isTotal ? successColor : textColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: pw.FontWeight.bold,
            color: isTotal ? successColor : textColor,
          ),
        ),
      ],
    );
  }

  /// Format date helper
  static String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Capitalize first letter helper
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Build professional receipt header
  static pw.Widget _buildReceiptHeader(Company company, String receiptId) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [successColor, primaryColor],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.name.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              if (company.phone.isNotEmpty)
                pw.Text(
                  company.phone,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
              if (company.email.isNotEmpty)
                pw.Text(
                  company.email,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'RECEIPT',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                receiptId,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build receipt information section
  static pw.Widget _buildReceiptSection(Receipt receipt, Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PAYMENT DETAILS:',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildDetailRow('Receipt ID:', receipt.id?.toString() ?? 'N/A'),
          pw.SizedBox(height: 6),
          _buildDetailRow('Invoice:', invoice.invoiceNumber),
          pw.SizedBox(height: 6),
          _buildDetailRow('Date:', _formatDate(receipt.createdAt ?? DateTime.now())),
          pw.SizedBox(height: 6),
          _buildDetailRow('Method:', _capitalizeFirst(receipt.paymentMethod)),
        ],
      ),
    );
  }

  /// Build payment details table
  static pw.Widget _buildPaymentDetailsTable(Receipt receipt, Invoice invoice) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: successColor,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'DESCRIPTION',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'AMOUNT',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Payment row
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'Payment received for Invoice ${invoice.invoiceNumber}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: textColor,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'E${receipt.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          // Total row
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightGray,
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL PAYMENT:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: successColor,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Text(
                    'E${receipt.amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: successColor,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build receipt footer
  static pw.Widget _buildReceiptFooter(Company company) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: lightGray,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: borderColor),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PAYMENT ACKNOWLEDGMENT:',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '- This receipt confirms payment has been received\n'
                '- Please retain this receipt for your records\n'
                '- For any queries, contact us using the details above',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'Thank you for your payment! - ${company.name}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: successColor,
            ),
          ),
        ),
      ],
    );
  }
}
