import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/customer_model.dart';

class CustomerService {
  CustomerService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.customers);

  Stream<List<CustomerModel>> watchCustomers(String businessId) {
    return _collection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final customers = snapshot.docs.map(CustomerModel.fromDoc).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return customers;
        });
  }

  Stream<CustomerModel?> watchCustomer({
    required String businessId,
    required String customerId,
  }) {
    return _collection.doc(customerId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final customer = CustomerModel.fromDoc(snapshot);
      if (customer.businessId != businessId) return null;
      return customer;
    });
  }

  Future<CustomerModel?> getCustomer({
    required String businessId,
    required String customerId,
  }) async {
    final snapshot = await _collection.doc(customerId).get();
    if (!snapshot.exists) return null;

    final customer = CustomerModel.fromDoc(snapshot);
    if (customer.businessId != businessId) return null;
    return customer;
  }

  Future<String> addCustomer(CustomerModel customer) async {
    final docRef = _collection.doc();
    await docRef.set(customer.copyWith(id: docRef.id).toCreateMap());
    return docRef.id;
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _collection.doc(customer.id).update(customer.toUpdateMap());
  }

  Future<void> deleteCustomer({
    required String customerId,
    required String businessId,
  }) async {
    final docRef = _collection.doc(customerId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null || data[FirestoreFields.businessId] != businessId) {
      throw StateError('Customer is outside the active business scope.');
    }
    await docRef.delete();
  }
}
