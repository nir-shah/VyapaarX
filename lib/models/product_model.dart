import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.category,
    required this.barcode,
    required this.hsnCode,
    required this.gstRate,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.lowStockLimit,
    this.unit = 'pcs',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String category;
  final String barcode;
  final String hsnCode;
  final double gstRate;
  final double purchasePrice;
  final double salePrice;
  final int stockQuantity;
  final int lowStockLimit;
  final String unit;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isLowStock => stockQuantity <= lowStockLimit;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return [
      name,
      category,
      barcode,
      hsnCode,
      unit,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'category': category,
      'barcode': barcode,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stockQuantity': stockQuantity,
      'stock': stockQuantity,
      'lowStockLimit': lowStockLimit,
      'unit': unit,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'category': category,
      'barcode': barcode,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'stockQuantity': stockQuantity,
      'stock': stockQuantity,
      'lowStockLimit': lowStockLimit,
      'unit': unit,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? category,
    String? barcode,
    String? hsnCode,
    double? gstRate,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? lowStockLimit,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      hsnCode: hsnCode ?? this.hsnCode,
      gstRate: gstRate ?? this.gstRate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockLimit: lowStockLimit ?? this.lowStockLimit,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      name: data['name'] as String? ?? data['productName'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      barcode: data['barcode'] as String? ?? '',
      hsnCode: data['hsnCode'] as String? ?? data['hsn'] as String? ?? '',
      gstRate: _readDouble(data['gstRate']),
      purchasePrice: _readDouble(data['purchasePrice']),
      salePrice: _readDouble(data['salePrice']),
      stockQuantity: _readInt(
        data['stockQuantity'] ?? data['stock'] ?? data['quantity'],
      ),
      lowStockLimit: _readInt(
        data['lowStockLimit'] ?? data['minStock'] ?? data['reorderLevel'],
        fallback: 5,
      ),
      unit: data['unit'] as String? ?? 'pcs',
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
