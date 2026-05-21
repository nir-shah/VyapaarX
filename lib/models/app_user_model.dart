import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_roles.dart';
import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.businessId,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String businessId;
  final String displayName;
  final String email;
  final String phoneNumber;
  final AppRole role;
  final AppUserStatus status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDisabled => status == AppUserStatus.disabled;

  bool matchesSearch(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    return [
      uid,
      displayName,
      email,
      phoneNumber,
      role.label,
      status.label,
    ].any((value) => value.toLowerCase().contains(normalized));
  }

  Map<String, Object?> toCreateMap({required String createdByUid}) {
    return {
      FirestoreFields.businessId: businessId,
      FirestoreFields.displayName: displayName,
      FirestoreFields.email: email,
      FirestoreFields.phoneNumber: phoneNumber,
      FirestoreFields.role: role.value,
      FirestoreFields.status: status.value,
      'createdBy': createdByUid,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  factory AppUserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUserModel(
      uid: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      displayName: data[FirestoreFields.displayName] as String? ?? '',
      email: data[FirestoreFields.email] as String? ?? '',
      phoneNumber: data[FirestoreFields.phoneNumber] as String? ?? '',
      role: AppRole.fromValue(data[FirestoreFields.role] as String?),
      status: AppUserStatus.fromValue(data[FirestoreFields.status] as String?),
      createdBy: data['createdBy'] as String?,
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }
}
