import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_formatters.dart';
import '../../models/purchase_invoice_model.dart';
import '../../models/sales_invoice_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/purchase_invoice_service.dart';
import '../../widgets/widgets.dart';

class PurchaseInvoiceListScreen extends StatelessWidget {
  const PurchaseInvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase invoices')),
      body: SafeArea(
        child: businessId == null || businessId.isEmpty
            ? const AppEmptyState(
                title: 'Business profile needed',
                message: 'Create a business profile before purchases.',
                icon: Icons.storefront_outlined,
              )
            : StreamBuilder<List<PurchaseInvoiceModel>>(
                stream: PurchaseInvoiceService().watchPurchaseInvoices(
                  businessId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingIndicator(
                      message: 'Loading purchases...',
                    );
                  }

                  if (snapshot.hasError) {
                    return const AppEmptyState(
                      title: 'Unable to load purchases',
                      message: 'Please check your connection and try again.',
                      icon: Icons.error_outline_rounded,
                    );
                  }

                  final invoices = snapshot.data ?? [];
                  if (invoices.isEmpty) {
                    return ListView(
                      padding: AppSpacing.responsiveScreenPadding(context),
                      children: [
                        AppEmptyState(
                          title: 'No purchase invoices yet',
                          message:
                              'Create a purchase invoice to add stock and track vendor payable.',
                          icon: Icons.shopping_bag_outlined,
                          actionLabel: 'Create purchase',
                          onActionPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.purchaseCreate),
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
                        return _PurchaseCard(invoice: invoices[index]);
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.purchaseCreate),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Purchase'),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.invoice});

  final PurchaseInvoiceModel invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.purchaseDetail, arguments: invoice),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
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
                      invoice.vendorName,
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
