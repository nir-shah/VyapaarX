import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:whatsapp_share/whatsapp_share.dart';

import '../models/customer_model.dart';
import '../models/sales_invoice_model.dart';

class WhatsappService {
  const WhatsappService();

  Future<void> shareInvoicePdf({
    required SalesInvoiceModel invoice,
    required CustomerModel customer,
    required Uint8List pdfBytes,
  }) async {
    final fileName = '${invoice.invoiceNumber}.pdf';
    final message =
        'Namaste ${customer.name}, please find invoice ${invoice.invoiceNumber}. '
        'Total: INR ${invoice.totalAmount.toStringAsFixed(2)}, '
        'Balance: INR ${invoice.balanceAmount.toStringAsFixed(2)}.';

    await _tryDirectWhatsappMessage(phone: customer.phone, message: message);

    await SharePlus.instance.share(
      ShareParams(
        title: invoice.invoiceNumber,
        subject: invoice.invoiceNumber,
        text: message,
        files: [
          XFile.fromData(pdfBytes, name: fileName, mimeType: 'application/pdf'),
        ],
        fileNameOverrides: [fileName],
      ),
    );
  }

  Future<void> _tryDirectWhatsappMessage({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final isInstalled = await WhatsappShare.isInstalled();
      if (isInstalled != true) return;

      await WhatsappShare.share(phone: normalizedPhone, text: message);
    } on Object {
      return;
    }
  }
}
