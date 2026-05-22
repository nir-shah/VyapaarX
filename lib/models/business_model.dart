import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';

class BusinessModel {
  const BusinessModel({
    required this.businessId,
    required this.ownerUid,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.businessType,
    required this.gstin,
    this.city = '',
    this.state = '',
    this.pinCode = '',
    this.alternatePhone,
    this.logoUrl,
    this.preferences = const <String, bool>{},
    this.createdAt,
    this.updatedAt,
  });

  final String businessId;
  final String ownerUid;
  final String name;
  final String address;
  final String phone;
  final String? alternatePhone;
  final String email;
  final String businessType;
  final String gstin;
  final String city;
  final String state;
  final String pinCode;
  final String? logoUrl;
  final Map<String, bool> preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toFirestore({bool includeServerTimestamps = false}) {
    return {
      FirestoreFields.businessId: businessId,
      'ownerId': ownerUid,
      'ownerUid': ownerUid,
      'businessName': name,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pinCode,
      'pinCode': pinCode,
      'phone': phone,
      'alternatePhone': alternatePhone,
      FirestoreFields.email: email,
      'businessType': businessType,
      'gstin': gstin,
      'logoUrl': logoUrl,
      'preferences': preferences,
      FirestoreFields.createdAt: includeServerTimestamps
          ? FieldValue.serverTimestamp()
          : createdAt,
      FirestoreFields.updatedAt: includeServerTimestamps
          ? FieldValue.serverTimestamp()
          : updatedAt,
    };
  }

  factory BusinessModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? <String, dynamic>{};
    return BusinessModel(
      businessId: data[FirestoreFields.businessId] as String? ?? snapshot.id,
      ownerUid: data['ownerId'] as String? ?? data['ownerUid'] as String? ?? '',
      name: data['name'] as String? ?? data['businessName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      pinCode: data['pinCode'] as String? ?? data['pincode'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      alternatePhone: data['alternatePhone'] as String?,
      email: data[FirestoreFields.email] as String? ?? '',
      businessType: data['businessType'] as String? ?? '',
      gstin: data['gstin'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      preferences: _readPreferences(data['preferences']),
      createdAt: _readDate(data[FirestoreFields.createdAt]),
      updatedAt: _readDate(data[FirestoreFields.updatedAt]),
    );
  }

  BusinessModel copyWith({
    String? businessId,
    String? ownerUid,
    String? name,
    String? address,
    String? phone,
    String? alternatePhone,
    bool clearAlternatePhone = false,
    String? email,
    String? businessType,
    String? gstin,
    String? city,
    String? state,
    String? pinCode,
    String? logoUrl,
    bool clearLogo = false,
    Map<String, bool>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      businessId: businessId ?? this.businessId,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      alternatePhone: clearAlternatePhone
          ? null
          : alternatePhone ?? this.alternatePhone,
      email: email ?? this.email,
      businessType: businessType ?? this.businessType,
      gstin: gstin ?? this.gstin,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      logoUrl: clearLogo ? null : logoUrl ?? this.logoUrl,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static Map<String, bool> _readPreferences(Object? value) {
    if (value is! Map) return const <String, bool>{};

    return value.map((key, value) {
      return MapEntry(key.toString(), value == true);
    });
  }
}
