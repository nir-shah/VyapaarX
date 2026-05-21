import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';

class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.addressLine1,
    required this.villageCity,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pinCode,
    required this.phone,
    required this.openingBalance,
    required this.outstanding,
    this.alternatePhone,
    this.email,
    this.gstin,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String addressLine1;
  final String villageCity;
  final String taluka;
  final String district;
  final String state;
  final String pinCode;
  final String phone;
  final String? alternatePhone;
  final String? email;
  final String? gstin;
  final double openingBalance;
  final double outstanding;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasOutstanding => outstanding > 0;

  String get fullAddress {
    return [
      addressLine1,
      villageCity,
      taluka,
      district,
      state,
      pinCode,
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return [
      name,
      phone,
      alternatePhone ?? '',
      email ?? '',
      gstin ?? '',
      villageCity,
      taluka,
      district,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'addressLine1': addressLine1,
      'villageCity': villageCity,
      'taluka': taluka,
      'district': district,
      'state': state,
      'pinCode': pinCode,
      'phone': phone,
      'alternatePhone': alternatePhone,
      FirestoreFields.email: email,
      'gstin': gstin,
      'openingBalance': openingBalance,
      'outstanding': outstanding,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  Map<String, Object?> toUpdateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'addressLine1': addressLine1,
      'villageCity': villageCity,
      'taluka': taluka,
      'district': district,
      'state': state,
      'pinCode': pinCode,
      'phone': phone,
      'alternatePhone': alternatePhone,
      FirestoreFields.email: email,
      'gstin': gstin,
      'openingBalance': openingBalance,
      'outstanding': outstanding,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  CustomerModel copyWith({
    String? id,
    String? businessId,
    String? name,
    String? addressLine1,
    String? villageCity,
    String? taluka,
    String? district,
    String? state,
    String? pinCode,
    String? phone,
    String? alternatePhone,
    String? email,
    String? gstin,
    double? openingBalance,
    double? outstanding,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      villageCity: villageCity ?? this.villageCity,
      taluka: taluka ?? this.taluka,
      district: district ?? this.district,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      openingBalance: openingBalance ?? this.openingBalance,
      outstanding: outstanding ?? this.outstanding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomerModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CustomerModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      name: data['name'] as String? ?? '',
      addressLine1: data['addressLine1'] as String? ?? '',
      villageCity: data['villageCity'] as String? ?? '',
      taluka: data['taluka'] as String? ?? '',
      district: data['district'] as String? ?? '',
      state: data['state'] as String? ?? '',
      pinCode: data['pinCode'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      alternatePhone: data['alternatePhone'] as String?,
      email: data[FirestoreFields.email] as String?,
      gstin: data['gstin'] as String?,
      openingBalance: _readDouble(data['openingBalance']),
      outstanding: _readDouble(data['outstanding']),
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
