import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';

class DashboardData {
  const DashboardData({
    required this.todaySales,
    required this.outstandingAmount,
    required this.totalCustomers,
    required this.totalProducts,
    required this.lowStockCount,
    required this.expenseSummary,
    required this.recentInvoices,
    required this.lowStockProducts,
  });

  final double todaySales;
  final double outstandingAmount;
  final int totalCustomers;
  final int totalProducts;
  final int lowStockCount;
  final double expenseSummary;
  final List<DashboardInvoice> recentInvoices;
  final List<DashboardProduct> lowStockProducts;

  static const empty = DashboardData(
    todaySales: 0,
    outstandingAmount: 0,
    totalCustomers: 0,
    totalProducts: 0,
    lowStockCount: 0,
    expenseSummary: 0,
    recentInvoices: [],
    lowStockProducts: [],
  );
}

class DashboardInvoice {
  const DashboardInvoice({
    required this.id,
    required this.businessId,
    required this.invoiceNumber,
    required this.customerName,
    required this.totalAmount,
    required this.outstandingAmount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String businessId;
  final String invoiceNumber;
  final String customerName;
  final double totalAmount;
  final double outstandingAmount;
  final String status;
  final DateTime? createdAt;

  factory DashboardInvoice.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return DashboardInvoice(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      invoiceNumber: _readString(data, ['invoiceNumber', 'number'], doc.id),
      customerName: _readString(data, ['customerName', 'customer'], 'Customer'),
      totalAmount: _readDouble(data, ['totalAmount', 'grandTotal', 'amount']),
      outstandingAmount: _readDouble(data, [
        'outstandingAmount',
        'balanceDue',
        'dueAmount',
      ]),
      status: _readString(data, ['status', 'paymentStatus'], 'draft'),
      createdAt: _readDate(data[FirestoreFields.createdAt]),
    );
  }
}

class DashboardProduct {
  const DashboardProduct({
    required this.id,
    required this.businessId,
    required this.name,
    required this.stockQuantity,
    required this.lowStockLimit,
  });

  final String id;
  final String businessId;
  final String name;
  final int stockQuantity;
  final int lowStockLimit;

  bool get isLowStock => stockQuantity <= lowStockLimit;

  factory DashboardProduct.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return DashboardProduct(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      name: _readString(data, ['name', 'productName'], 'Product'),
      stockQuantity: _readInt(data, ['stockQuantity', 'stock', 'quantity']),
      lowStockLimit: _readInt(data, [
        'lowStockLimit',
        'minStock',
        'reorderLevel',
      ], fallback: 5),
    );
  }
}

String _readString(
  Map<String, dynamic> data,
  List<String> keys,
  String fallback,
) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}

double _readDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
  }
  return 0;
}

int _readInt(Map<String, dynamic> data, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
