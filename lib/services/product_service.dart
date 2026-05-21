import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.products);

  Stream<List<ProductModel>> watchProducts(String businessId) {
    return _collection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs.map(ProductModel.fromDoc).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
          return products;
        });
  }

  Stream<ProductModel?> watchProduct({
    required String businessId,
    required String productId,
  }) {
    return _collection.doc(productId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final product = ProductModel.fromDoc(snapshot);
      if (product.businessId != businessId) return null;
      return product;
    });
  }

  Future<String> addProduct(ProductModel product) async {
    final docRef = _collection.doc();
    await docRef.set(product.copyWith(id: docRef.id).toCreateMap());
    return docRef.id;
  }

  Future<void> updateProduct(ProductModel product) async {
    await _collection.doc(product.id).update(product.toUpdateMap());
  }

  Future<void> deleteProduct({
    required String productId,
    required String businessId,
  }) async {
    final docRef = _collection.doc(productId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null || data[FirestoreFields.businessId] != businessId) {
      throw StateError('Product is outside the active business scope.');
    }
    await docRef.delete();
  }
}
