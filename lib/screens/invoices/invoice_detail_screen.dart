import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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
import 'widgets/invoice_summary_card.dart';

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

  Future<void> _sharePdf(
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

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${invoice.invoiceNumber}.pdf',
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

  Future<void> _shareWhatsApp(
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
        message: 'Unable to share invoice on WhatsApp.',
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
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

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

        return AppResponsiveShell(
          title: 'Invoice detail',
          currentRoute: AppRoutes.invoiceDetail,
          currentRole: auth.role,
          actions: [
            if (currentInvoice != null)
              IconButton(
                tooltip: 'Print',
                onPressed: () => _printInvoice(context, currentInvoice),
                icon: const Icon(Icons.print_outlined),
              ),
            if (currentInvoice != null)
              IconButton(
                tooltip: 'Share PDF',
                onPressed: () => _sharePdf(context, currentInvoice),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
            if (currentInvoice != null)
              IconButton(
                tooltip: 'WhatsApp',
                onPressed: () => _shareWhatsApp(context, currentInvoice),
                icon: const Icon(Icons.chat_outlined),
              ),
          ],
          child: currentInvoice == null
              ? const AppEmptyState(
                  title: 'Invoice not found',
                  message: 'This invoice may no longer exist.',
                  icon: Icons.receipt_long_outlined,
                )
              : ListView(
                  padding: AppSpacing.responsiveScreenPadding(context),
                  children: [
                    _InvoicePreview(invoice: currentInvoice),
                    const SizedBox(height: AppSpacing.md),
                    _ActionBar(
                      onPrint: () => _printInvoice(context, currentInvoice),
                      onPdf: () => _sharePdf(context, currentInvoice),
                      onWhatsApp: () => _shareWhatsApp(context, currentInvoice),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InvoiceSummaryCard(
                      subtotal: currentInvoice.subtotal,
                      discountTotal: currentInvoice.discountTotal,
                      gstTotal: currentInvoice.gstTotal,
                      totalAmount: currentInvoice.totalAmount,
                      paidAmount: currentInvoice.paidAmount,
                      balanceAmount: currentInvoice.balanceAmount,
                      paymentStatus: currentInvoice.paymentStatus,
                    ),
                    if (currentInvoice.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _NotesCard(notes: currentInvoice.notes),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
        );
      },
    );
  }
}

class _InvoicePreview extends StatelessWidget {
  const _InvoicePreview({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xxlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppSectionHeader(
                  title: invoice.invoiceNumber,
                  subtitle: 'GST Invoice • ${invoice.customerName}',
                ),
              ),
              AppStatusChip(
                label: invoice.paymentStatus.label,
                type: invoiceStatusType(invoice.paymentStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.xlRadius,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _PreviewMetric(
                    label: 'Total',
                    value: AppFormatters.currency(invoice.totalAmount),
                  ),
                ),
                Expanded(
                  child: _PreviewMetric(
                    label: 'Paid',
                    value: AppFormatters.currency(invoice.paidAmount),
                  ),
                ),
                Expanded(
                  child: _PreviewMetric(
                    label: 'Balance',
                    value: AppFormatters.currency(invoice.balanceAmount),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(title: 'Items'),
          const SizedBox(height: AppSpacing.md),
          ...invoice.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InvoiceLine(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine({required this.item});

  final SalesInvoiceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.border),
      ),
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
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit} x ${AppFormatters.currency(item.rate)} • GST ${item.gstRate.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            AppFormatters.currency(item.lineTotal),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onPrint,
    required this.onPdf,
    required this.onWhatsApp,
  });

  final VoidCallback onPrint;
  final VoidCallback onPdf;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSecondaryButton(
            label: 'Print',
            icon: Icons.print_outlined,
            onPressed: onPrint,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppSecondaryButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: onPdf,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: AppSecondaryButton(
            label: 'WhatsApp',
            icon: Icons.chat_outlined,
            onPressed: onWhatsApp,
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: 'Notes'),
          const SizedBox(height: AppSpacing.sm),
          Text(notes),
        ],
      ),
    );
  }
}

class _InvoiceShareData {
  const _InvoiceShareData({required this.business, required this.customer});

  final BusinessModel business;
  final CustomerModel customer;
}
