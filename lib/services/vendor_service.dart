import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/vendor_model.dart';

class VendorService {
  VendorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.vendors);

  Stream<List<VendorModel>> watchVendors(String businessId) {
    return _collection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final vendors = snapshot.docs.map(VendorModel.fromDoc).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return vendors;
        });
  }

  Stream<VendorModel?> watchVendor({
    required String businessId,
    required String vendorId,
  }) {
    return _collection.doc(vendorId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final vendor = VendorModel.fromDoc(snapshot);
      if (vendor.businessId != businessId) return null;
      return vendor;
    });
  }

  Future<String> addVendor(VendorModel vendor) async {
    final docRef = _collection.doc();
    await docRef.set(vendor.copyWith(id: docRef.id).toCreateMap());
    return docRef.id;
  }

  Future<void> updateVendor(VendorModel vendor) async {
    await _collection.doc(vendor.id).update(vendor.toUpdateMap());
  }

  Future<void> deleteVendor({
    required String vendorId,
    required String businessId,
  }) async {
    final docRef = _collection.doc(vendorId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null || data[FirestoreFields.businessId] != businessId) {
      throw StateError('Vendor is outside the active business scope.');
    }
    await docRef.delete();
  }
}
