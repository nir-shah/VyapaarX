import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';
import 'sales_invoice_model.dart';

class PurchaseInvoiceItem {
  const PurchaseInvoiceItem({
    required this.productId,
    required this.productName,
    required this.hsnCode,
    required this.quantity,
    required this.rate,
    required this.gstRate,
    required this.discount,
    required this.unit,
  });

  final String productId;
  final String productName;
  final String hsnCode;
  final int quantity;
  final double rate;
  final double gstRate;
  final double discount;
  final String unit;

  double get taxableAmount {
    final amount = quantity * rate - discount;
    return amount < 0 ? 0 : amount;
  }

  double get gstAmount => taxableAmount * gstRate / 100;
  double get lineTotal => taxableAmount + gstAmount;

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'rate': rate,
      'gstRate': gstRate,
      'discount': discount,
      'taxableAmount': taxableAmount,
      'gstAmount': gstAmount,
      'lineTotal': lineTotal,
      'unit': unit,
    };
  }

  factory PurchaseInvoiceItem.fromMap(Map<String, dynamic> data) {
    return PurchaseInvoiceItem(
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      hsnCode: data['hsnCode'] as String? ?? '',
      quantity: _readInt(data['quantity']),
      rate: _readDouble(data['rate']),
      gstRate: _readDouble(data['gstRate']),
      discount: _readDouble(data['discount']),
      unit: data['unit'] as String? ?? 'pcs',
    );
  }
}

class PurchaseInvoiceModel {
  const PurchaseInvoiceModel({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.subtotal,
    required this.discountTotal,
    required this.gstTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
    required this.paymentStatus,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String invoiceNumber;
  final String vendorId;
  final String vendorName;
  final List<PurchaseInvoiceItem> items;
  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final PaymentStatus paymentStatus;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'invoiceNumber': invoiceNumber,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discountTotal': discountTotal,
      'gstTotal': gstTotal,
      'totalAmount': totalAmount,
      'grandTotal': totalAmount,
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'payableAmount': balanceAmount,
      'paymentStatus': paymentStatus.label,
      'status': paymentStatus.label,
      'notes': notes,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  factory PurchaseInvoiceModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawItems = data['items'] as List<dynamic>? ?? [];

    return PurchaseInvoiceModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      invoiceNumber: data['invoiceNumber'] as String? ?? doc.id,
      vendorId: data['vendorId'] as String? ?? '',
      vendorName: data['vendorName'] as String? ?? '',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PurchaseInvoiceItem.fromMap)
          .toList(),
      subtotal: _readDouble(data['subtotal']),
      discountTotal: _readDouble(data['discountTotal']),
      gstTotal: _readDouble(data['gstTotal']),
      totalAmount: _readDouble(data['totalAmount']),
      paidAmount: _readDouble(data['paidAmount']),
      balanceAmount: _readDouble(
        data['balanceAmount'] ?? data['payableAmount'],
      ),
      paymentStatus: PaymentStatus.fromString(
        data['paymentStatus'] as String? ?? '',
      ),
      notes: data['notes'] as String? ?? '',
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
