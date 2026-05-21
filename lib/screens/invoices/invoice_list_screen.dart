import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';
import '../../widgets/widgets.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Sales invoices')),
      body: SafeArea(
        child: businessId == null || businessId.isEmpty
            ? const AppEmptyState(
                title: 'Business profile needed',
                message: 'Create a business profile before making invoices.',
                icon: Icons.storefront_outlined,
              )
            : StreamBuilder<List<SalesInvoiceModel>>(
                stream: InvoiceService().watchInvoices(businessId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(
                      message: 'Loading invoices...',
                    );
                  }

                  if (snapshot.hasError) {
                    return AppEmptyState(
                      title: 'Unable to load invoices',
                      message: 'Please check your connection and try again.',
                      icon: Icons.error_outline_rounded,
                      actionLabel: 'Retry',
                      onActionPressed: () {},
                    );
                  }

                  final invoices = snapshot.data ?? [];
                  if (invoices.isEmpty) {
                    return ListView(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      children: [
                        AppEmptyState(
                          title: 'No invoices yet',
                          message:
                              'Create your first sales invoice to start billing.',
                          icon: Icons.receipt_long_outlined,
                          actionLabel: 'Create invoice',
                          onActionPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.invoiceCreate),
                        ),
                      ],
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {},
                    child: ListView.separated(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      itemCount: invoices.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return _InvoiceCard(invoice: invoice);
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.invoiceCreate),
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text('Create'),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final SalesInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.invoiceDetail, arguments: invoice),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.customerName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppStatusChip(
                      label: invoice.paymentStatus.label,
                      type: _statusType(invoice.paymentStatus),
                    ),
                  ],
                ),
              ),
              Text(
                AppFormatters.currency(invoice.totalAmount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
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
