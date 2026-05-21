import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMode,
    required this.date,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final double amount;
  final String category;
  final String paymentMode;
  final DateTime date;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return [
      title,
      category,
      paymentMode,
      notes,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  bool isInMonth(DateTime month) {
    return date.year == month.year && date.month == month.month;
  }

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'title': title,
      'amount': amount,
      'category': category,
      'paymentMode': paymentMode,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'title': title,
      'amount': amount,
      'category': category,
      'paymentMode': paymentMode,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? businessId,
    String? title,
    double? amount,
    String? category,
    String? paymentMode,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ExpenseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ExpenseModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      title: data['title'] as String? ?? '',
      amount: _readDouble(data['amount']),
      category: data['category'] as String? ?? 'General',
      paymentMode: data['paymentMode'] as String? ?? 'Cash',
      date: FirestoreTimestampHelper.tryRead(data['date']) ?? DateTime.now(),
      notes: data['notes'] as String? ?? '',
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
}
