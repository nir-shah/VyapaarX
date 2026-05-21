import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../models/business_model.dart';
import '../../models/customer_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/business_service.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_service.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/widgets.dart';

class InvoiceDetailScreen extends StatelessWidget {
  const InvoiceDetailScreen({super.key, required this.invoice});

  final SalesInvoiceModel invoice;

  Future<void> _printInvoice(
    BuildContext context,
    SalesInvoiceModel invoice,
  ) async {
    try {
      final data = await _loadInvoiceShareData(context, invoice);
      if (data == null) return;

      await const PdfInvoiceService().printInvoice(
        business: data.business,
        customer: data.customer,
        invoice: invoice,
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to generate invoice PDF.',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> _shareInvoice(
    BuildContext context,
    SalesInvoiceModel invoice,
  ) async {
    try {
      final data = await _loadInvoiceShareData(context, invoice);
      if (data == null) return;

      final pdfBytes = await const PdfInvoiceService().generateInvoicePdf(
        business: data.business,
        customer: data.customer,
        invoice: invoice,
      );

      await const WhatsappService().shareInvoicePdf(
        invoice: invoice,
        customer: data.customer,
        pdfBytes: pdfBytes,
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to share invoice PDF.',
        type: AppSnackBarType.error,
      );
    }
  }

  Future<_InvoiceShareData?> _loadInvoiceShareData(
    BuildContext context,
    SalesInvoiceModel invoice,
  ) async {
    final businessId = context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) return null;

    final business = await BusinessService().getBusiness(businessId);
    final customer = await CustomerService().getCustomer(
      businessId: businessId,
      customerId: invoice.customerId,
    );

    if (!context.mounted) return null;
    if (business == null || customer == null) {
      SnackBarHelper.show(
        context,
        message: 'Business or customer details are missing.',
        type: AppSnackBarType.error,
      );
      return null;
    }

    return _InvoiceShareData(business: business, customer: customer);
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    if (businessId == null || businessId.isEmpty) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Business profile needed',
          message: 'Create a business profile before viewing invoices.',
          icon: Icons.storefront_outlined,
        ),
      );
    }

    return StreamBuilder<SalesInvoiceModel?>(
      initialData: invoice,
      stream: InvoiceService().watchInvoice(
        businessId: businessId,
        invoiceId: invoice.id,
      ),
      builder: (context, snapshot) {
        final currentInvoice = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invoice detail'),
            actions: [
              if (currentInvoice != null)
                IconButton(
                  tooltip: 'Print PDF',
                  onPressed: () => _printInvoice(context, currentInvoice),
                  icon: const Icon(Icons.print_outlined),
                ),
              if (currentInvoice != null)
                IconButton(
                  tooltip: 'Share invoice',
                  onPressed: () => _shareInvoice(context, currentInvoice),
                  icon: const Icon(Icons.share_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: currentInvoice == null
                ? const AppEmptyState(
                    title: 'Invoice not found',
                    message: 'This invoice may no longer exist.',
                    icon: Icons.receipt_long_outlined,
                  )
                : ListView(
                    padding: AppSpacing.responsiveScreenPadding(context),
                    children: [
                      _InvoiceHeader(invoice: currentInvoice),
                      const SizedBox(height: AppSpacing.lg),
                      _ItemsCard(invoice: currentInvoice),
                      const SizedBox(height: AppSpacing.md),
                      _SummaryCard(invoice: currentInvoice),
                      if (currentInvoice.notes.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Card(
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSectionTitle(title: 'Notes'),
                                const SizedBox(height: AppSpacing.sm),
                                Text(currentInvoice.notes),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSectionTitle(
                    title: invoice.invoiceNumber,
                    subtitle: invoice.customerName,
                  ),
                ),
                AppStatusChip(
                  label: invoice.paymentStatus.label,
                  type: _statusType(invoice.paymentStatus),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppFormatters.currency(invoice.totalAmount),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(title: 'Items'),
            const SizedBox(height: AppSpacing.md),
            ...invoice.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${item.quantity} ${item.unit} x ${AppFormatters.currency(item.rate)} | GST ${item.gstRate}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(AppFormatters.currency(item.lineTotal)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            _SummaryRow('Subtotal', AppFormatters.currency(invoice.subtotal)),
            _SummaryRow(
              'Discount',
              AppFormatters.currency(invoice.discountTotal),
            ),
            _SummaryRow('GST', AppFormatters.currency(invoice.gstTotal)),
            const Divider(height: AppSpacing.xl),
            _SummaryRow('Total', AppFormatters.currency(invoice.totalAmount)),
            _SummaryRow('Paid', AppFormatters.currency(invoice.paidAmount)),
            _SummaryRow(
              'Balance',
              AppFormatters.currency(invoice.balanceAmount),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

AppStatusType _statusType(PaymentStatus status) {
  return switch (status) {
    PaymentStatus.paid => AppStatusType.success,
    PaymentStatus.partial => AppStatusType.warning,
    PaymentStatus.unpaid => AppStatusType.danger,
  };
}

class _InvoiceShareData {
  const _InvoiceShareData({required this.business, required this.customer});

  final BusinessModel business;
  final CustomerModel customer;
}
