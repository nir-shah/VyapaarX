import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/expense_model.dart';

class ExpenseService {
  ExpenseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.expenses);

  Stream<List<ExpenseModel>> watchExpenses(String businessId) {
    return _collection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map(ExpenseModel.fromDoc).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return expenses;
        });
  }

  Future<String> addExpense(ExpenseModel expense) async {
    final docRef = _collection.doc();
    await docRef.set(expense.copyWith(id: docRef.id).toCreateMap());
    return docRef.id;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _collection.doc(expense.id).update(expense.toUpdateMap());
  }

  Future<void> deleteExpense({
    required String expenseId,
    required String businessId,
  }) async {
    final docRef = _collection.doc(expenseId);
    final snapshot = await docRef.get();
    final data = snapshot.data();
    if (data == null || data[FirestoreFields.businessId] != businessId) {
      throw StateError('Expense is outside the active business scope.');
    }
    await docRef.delete();
  }
}
