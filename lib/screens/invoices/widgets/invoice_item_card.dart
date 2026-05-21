import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../models/product_model.dart';
import '../../../models/sales_invoice_model.dart';
import '../../../widgets/widgets.dart';

class InvoiceItemDraft {
  const InvoiceItemDraft({
    required this.product,
    required this.quantity,
    required this.rate,
    required this.gstRate,
    required this.discount,
  });

  final ProductModel product;
  final int quantity;
  final double rate;
  final double gstRate;
  final double discount;

  double get taxableAmount {
    final amount = quantity * rate - discount;
    return amount < 0 ? 0 : amount;
  }

  double get gstAmount => taxableAmount * gstRate / 100;
  double get lineTotal => taxableAmount + gstAmount;

  factory InvoiceItemDraft.fromProduct(ProductModel product) {
    return InvoiceItemDraft(
      product: product,
      quantity: 1,
      rate: product.salePrice,
      gstRate: product.gstRate,
      discount: 0,
    );
  }

  InvoiceItemDraft copyWith({
    int? quantity,
    double? rate,
    double? gstRate,
    double? discount,
  }) {
    return InvoiceItemDraft(
      product: product,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      gstRate: gstRate ?? this.gstRate,
      discount: discount ?? this.discount,
    );
  }

  SalesInvoiceItem toInvoiceItem() {
    return SalesInvoiceItem(
      productId: product.id,
      productName: product.name,
      hsnCode: product.hsnCode,
      quantity: quantity,
      rate: rate,
      gstRate: gstRate,
      discount: discount,
      unit: product.unit,
    );
  }
}

class InvoiceItemCard extends StatelessWidget {
  const InvoiceItemCard({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
  });

  final InvoiceItemDraft item;
  final ValueChanged<InvoiceItemDraft> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.quantity > item.product.stockQuantity;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(
          color: lowStock
              ? AppColors.danger.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppSectionHeader(
                  title: item.product.name,
                  subtitle:
                      'Stock ${item.product.stockQuantity} ${item.product.unit} • HSN ${item.product.hsnCode}',
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(quantity: int.tryParse(value) ?? 0),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: item.rate.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rate'),
                  onChanged: (value) {
                    onChanged(item.copyWith(rate: double.tryParse(value) ?? 0));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: item.discount.toStringAsFixed(0),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount'),
                  onChanged: (value) {
                    onChanged(
                      item.copyWith(discount: double.tryParse(value) ?? 0),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusChip(
                label: 'GST ${AppFormatters.currency(item.gstAmount)}',
                type: AppStatusType.info,
              ),
              if (lowStock)
                const AppStatusChip(
                  label: 'Not enough stock',
                  type: AppStatusType.danger,
                ),
              AppStatusChip(
                label: 'Line ${AppFormatters.currency(item.lineTotal)}',
                type: AppStatusType.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
