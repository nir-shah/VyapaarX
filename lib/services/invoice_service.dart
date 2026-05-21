import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/customer_model.dart';
import '../models/sales_invoice_model.dart';

class InvoiceService {
  InvoiceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _invoiceCollection =>
      _firestore.collection(FirestoreCollections.salesInvoices);

  Stream<List<SalesInvoiceModel>> watchInvoices(String businessId) {
    return _invoiceCollection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final invoices = snapshot.docs.map(SalesInvoiceModel.fromDoc).toList()
            ..sort((a, b) {
              final aDate =
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });
          return invoices;
        });
  }

  Stream<SalesInvoiceModel?> watchInvoice({
    required String businessId,
    required String invoiceId,
  }) {
    return _invoiceCollection.doc(invoiceId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final invoice = SalesInvoiceModel.fromDoc(snapshot);
      if (invoice.businessId != businessId) return null;
      return invoice;
    });
  }

  String generateInvoiceNumber(String docId) {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'VX-$date-${docId.substring(0, 6).toUpperCase()}';
  }

  Future<String> createSalesInvoice({
    required String businessId,
    required CustomerModel customer,
    required List<SalesInvoiceItem> items,
    required double paidAmount,
    required String notes,
  }) async {
    if (businessId.isEmpty) {
      throw StateError('Business profile is required.');
    }
    if (customer.businessId != businessId) {
      throw StateError('Customer is outside the active business scope.');
    }
    if (items.isEmpty) {
      throw StateError('Add at least one product.');
    }

    final invoiceRef = _invoiceCollection.doc();
    final invoiceNumber = generateInvoiceNumber(invoiceRef.id);
    final totals = _calculateTotals(items, paidAmount);

    await _firestore.runTransaction((transaction) async {
      final customerRef = _firestore
          .collection(FirestoreCollections.customers)
          .doc(customer.id);
      final customerSnapshot = await transaction.get(customerRef);
      final customerData = customerSnapshot.data();
      if (customerData == null ||
          customerData[FirestoreFields.businessId] != businessId) {
        throw StateError('Customer is outside the active business scope.');
      }

      for (final item in items) {
        final productRef = _firestore
            .collection(FirestoreCollections.products)
            .doc(item.productId);
        final productSnapshot = await transaction.get(productRef);
        final productData = productSnapshot.data();
        if (productData == null ||
            productData[FirestoreFields.businessId] != businessId) {
          throw StateError('${item.productName} is outside this business.');
        }

        final currentStock = _readInt(
          productData['stockQuantity'] ??
              productData['stock'] ??
              productData['quantity'],
        );
        if (currentStock < item.quantity) {
          throw StateError('Not enough stock for ${item.productName}.');
        }

        transaction.update(productRef, {
          'stockQuantity': FieldValue.increment(-item.quantity),
          'stock': FieldValue.increment(-item.quantity),
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }

      final invoice = SalesInvoiceModel(
        id: invoiceRef.id,
        businessId: businessId,
        invoiceNumber: invoiceNumber,
        customerId: customer.id,
        customerName: customer.name,
        items: items,
        subtotal: totals.subtotal,
        discountTotal: totals.discountTotal,
        gstTotal: totals.gstTotal,
        totalAmount: totals.totalAmount,
        paidAmount: totals.paidAmount,
        balanceAmount: totals.balanceAmount,
        paymentStatus: PaymentStatus.fromAmounts(
          totalAmount: totals.totalAmount,
          paidAmount: totals.paidAmount,
        ),
        notes: notes.trim(),
      );

      transaction.set(invoiceRef, invoice.toCreateMap());
      transaction.update(customerRef, {
        'outstanding': FieldValue.increment(totals.balanceAmount),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return invoiceRef.id;
  }

  _InvoiceTotals _calculateTotals(
    List<SalesInvoiceItem> items,
    double paidAmount,
  ) {
    final subtotal = items.fold<double>(
      0,
      (total, item) => total + item.quantity * item.rate,
    );
    final discountTotal = items.fold<double>(
      0,
      (total, item) => total + item.discount,
    );
    final gstTotal = items.fold<double>(
      0,
      (total, item) => total + item.gstAmount,
    );
    final totalAmount = items.fold<double>(
      0,
      (total, item) => total + item.lineTotal,
    );
    final normalizedPaid = paidAmount.clamp(0, totalAmount).toDouble();

    return _InvoiceTotals(
      subtotal: subtotal,
      discountTotal: discountTotal,
      gstTotal: gstTotal,
      totalAmount: totalAmount,
      paidAmount: normalizedPaid,
      balanceAmount: totalAmount - normalizedPaid,
    );
  }

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class _InvoiceTotals {
  const _InvoiceTotals({
    required this.subtotal,
    required this.discountTotal,
    required this.gstTotal,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceAmount,
  });

  final double subtotal;
  final double discountTotal;
  final double gstTotal;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
}
