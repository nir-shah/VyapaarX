import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/business_model.dart';
import '../models/customer_model.dart';
import '../models/sales_invoice_model.dart';

class PdfInvoiceService {
  const PdfInvoiceService();

  Future<Uint8List> generateInvoicePdf({
    required BusinessModel business,
    required CustomerModel customer,
    required SalesInvoiceModel invoice,
  }) async {
    final document = pw.Document(
      title: invoice.invoiceNumber,
      author: business.name,
      creator: 'VyapaarX',
    );
    final logo = await _loadLogo(business.logoUrl);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          _Header(business: business, invoice: invoice, logo: logo),
          pw.SizedBox(height: 18),
          _Parties(business: business, customer: customer),
          pw.SizedBox(height: 18),
          _ItemsTable(invoice: invoice),
          pw.SizedBox(height: 14),
          _TotalsAndQr(invoice: invoice),
          if (invoice.notes.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _Notes(notes: invoice.notes),
          ],
          pw.Spacer(),
          _Footer(),
        ],
      ),
    );

    return document.save();
  }

  Future<void> printInvoice({
    required BusinessModel business,
    required CustomerModel customer,
    required SalesInvoiceModel invoice,
  }) async {
    final pdfBytes = await generateInvoicePdf(
      business: business,
      customer: customer,
      invoice: invoice,
    );

    await Printing.layoutPdf(
      name: '${invoice.invoiceNumber}.pdf',
      onLayout: (_) async => pdfBytes,
    );
  }

  Future<pw.ImageProvider?> _loadLogo(String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) return null;

    try {
      return await networkImage(logoUrl);
    } on Object {
      return null;
    }
  }
}

class _Header extends pw.StatelessWidget {
  _Header({required this.business, required this.invoice, required this.logo});

  final BusinessModel business;
  final SalesInvoiceModel invoice;
  final pw.ImageProvider? logo;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              width: 58,
              height: 58,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(logo!, fit: pw.BoxFit.contain),
            )
          else
            pw.Container(
              width: 58,
              height: 58,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue700,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'VX',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  business.name,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(business.address, style: _mutedStyle()),
                pw.Text('Phone: ${business.phone}', style: _mutedStyle()),
                pw.Text('Email: ${business.email}', style: _mutedStyle()),
                pw.Text('GSTIN: ${business.gstin}', style: _mutedStyle()),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TAX INVOICE',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(invoice.invoiceNumber),
              pw.Text(_dateText(invoice.createdAt ?? DateTime.now())),
              pw.SizedBox(height: 6),
              pw.Text('Status: ${invoice.paymentStatus.label}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Parties extends pw.StatelessWidget {
  _Parties({required this.business, required this.customer});

  final BusinessModel business;
  final CustomerModel customer;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _InfoBox(
            title: 'Bill From',
            lines: [
              business.name,
              business.address,
              'Phone: ${business.phone}',
              'GSTIN: ${business.gstin}',
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: _InfoBox(
            title: 'Bill To',
            lines: [
              customer.name,
              customer.fullAddress,
              'Phone: ${customer.phone}',
              if (customer.email != null) 'Email: ${customer.email}',
              if (customer.gstin != null) 'GSTIN: ${customer.gstin}',
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends pw.StatelessWidget {
  _InfoBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          ...lines
              .where((line) => line.trim().isNotEmpty)
              .map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Text(line, style: _mutedStyle()),
                ),
              ),
        ],
      ),
    );
  }
}

class _ItemsTable extends pw.StatelessWidget {
  _ItemsTable({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  pw.Widget build(pw.Context context) {
    final rows = invoice.items.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final item = entry.value;
      return [
        '$index',
        item.productName,
        item.hsnCode,
        '${item.quantity} ${item.unit}',
        _money(item.rate),
        '${item.gstRate.toStringAsFixed(0)}%',
        _money(item.discount),
        _money(item.lineTotal),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 9,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(22),
        1: const pw.FlexColumnWidth(2.1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(0.9),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(0.8),
        6: const pw.FlexColumnWidth(1),
        7: const pw.FlexColumnWidth(1.2),
      },
      headers: const [
        '#',
        'Item',
        'HSN',
        'Qty',
        'Rate',
        'GST',
        'Disc.',
        'Total',
      ],
      data: rows,
    );
  }
}

class _TotalsAndQr extends pw.StatelessWidget {
  _TotalsAndQr({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 96,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: invoice.invoiceNumber,
                width: 72,
                height: 72,
              ),
              pw.SizedBox(height: 6),
              pw.Text('QR placeholder', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(child: _GstSummary(invoice: invoice)),
        pw.SizedBox(width: 12),
        pw.Container(
          width: 180,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _TotalRow('Subtotal', _money(invoice.subtotal)),
              _TotalRow('Discount', _money(invoice.discountTotal)),
              _TotalRow('GST', _money(invoice.gstTotal)),
              pw.Divider(),
              _TotalRow('Grand Total', _money(invoice.totalAmount), bold: true),
              _TotalRow('Paid', _money(invoice.paidAmount)),
              _TotalRow('Balance', _money(invoice.balanceAmount), bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _GstSummary extends pw.StatelessWidget {
  _GstSummary({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  pw.Widget build(pw.Context context) {
    final grouped = <double, double>{};
    for (final item in invoice.items) {
      grouped[item.gstRate] = (grouped[item.gstRate] ?? 0) + item.gstAmount;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GST Summary',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (grouped.isEmpty)
            pw.Text('No GST applied', style: _mutedStyle())
          else
            ...grouped.entries.map(
              (entry) => _TotalRow(
                'GST ${entry.key.toStringAsFixed(0)}%',
                _money(entry.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notes extends pw.StatelessWidget {
  _Notes({required this.notes});

  final String notes;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(notes, style: _mutedStyle()),
        ],
      ),
    );
  }
}

class _TotalRow extends pw.StatelessWidget {
  _TotalRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  pw.Widget build(pw.Context context) {
    final style = pw.TextStyle(
      fontSize: 9,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}

class _Footer extends pw.StatelessWidget {
  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Text(
        'Generated by VyapaarX | This invoice is computer generated.',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }
}

pw.TextStyle _mutedStyle() {
  return const pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
}

String _money(num value) => 'INR ${value.toStringAsFixed(2)}';

String _dateText(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
