import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/dashboard_models.dart';

class DashboardService {
  DashboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<DashboardData> fetchDashboardData({required String businessId}) async {
    if (businessId.isEmpty) return DashboardData.empty;

    final results = await Future.wait([
      _fetchBusinessDocs(FirestoreCollections.salesInvoices, businessId),
      _fetchBusinessDocs(FirestoreCollections.customers, businessId),
      _fetchBusinessDocs(FirestoreCollections.products, businessId),
      _fetchBusinessDocs(FirestoreCollections.expenses, businessId),
    ]);

    final invoiceDocs = results[0];
    final customerDocs = results[1];
    final productDocs = results[2];
    final expenseDocs = results[3];

    final invoices = invoiceDocs.map(DashboardInvoice.fromDoc).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final products = productDocs.map(DashboardProduct.fromDoc).toList();
    final lowStockProducts =
        products.where((product) => product.isLowStock).toList()
          ..sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));

    return DashboardData(
      todaySales: _todaySales(invoices),
      outstandingAmount: invoices.fold<double>(
        0,
        (total, invoice) => total + invoice.outstandingAmount,
      ),
      totalCustomers: customerDocs.length,
      totalProducts: productDocs.length,
      lowStockCount: lowStockProducts.length,
      expenseSummary: _thisMonthExpenses(expenseDocs),
      recentInvoices: invoices.take(5).toList(),
      lowStockProducts: lowStockProducts.take(5).toList(),
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchBusinessDocs(
    String collection,
    String businessId,
  ) async {
    final snapshot = await _firestore
        .collection(collection)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .get();
    return snapshot.docs;
  }

  double _todaySales(List<DashboardInvoice> invoices) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return invoices
        .where((invoice) {
          final createdAt = invoice.createdAt;
          if (createdAt == null) return false;
          return !createdAt.isBefore(todayStart) &&
              createdAt.isBefore(tomorrowStart);
        })
        .fold<double>(0, (total, invoice) => total + invoice.totalAmount);
  }

  double _thisMonthExpenses(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> expenseDocs,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    return expenseDocs
        .where((doc) {
          final createdAt = _readDate(doc.data()[FirestoreFields.createdAt]);
          return createdAt == null || !createdAt.isBefore(monthStart);
        })
        .fold<double>(0, (total, doc) {
          final data = doc.data();
          final amount = data['amount'] ?? data['totalAmount'] ?? data['value'];
          if (amount is num) return total + amount.toDouble();
          if (amount is String) return total + (double.tryParse(amount) ?? 0);
          return total;
        });
  }

  DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
