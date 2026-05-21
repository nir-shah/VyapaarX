import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/firestore_fields.dart';

class BusinessDataGuard {
  const BusinessDataGuard._();

  static Map<String, Object?> withBusinessId({
    required String businessId,
    required Map<String, Object?> data,
  }) {
    return {...data, FirestoreFields.businessId: businessId};
  }

  static bool belongsToBusiness({
    required Map<String, dynamic>? data,
    required String businessId,
  }) {
    return data?[FirestoreFields.businessId] == businessId;
  }

  static Query<Map<String, dynamic>> scopedQuery({
    required CollectionReference<Map<String, dynamic>> collection,
    required String businessId,
  }) {
    return collection.where(FirestoreFields.businessId, isEqualTo: businessId);
  }

  static void ensureScoped({
    required Map<String, dynamic>? data,
    required String businessId,
  }) {
    if (!belongsToBusiness(data: data, businessId: businessId)) {
      throw StateError('Document is outside the active business scope.');
    }
  }
}
