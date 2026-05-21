import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/purchase_invoice_model.dart';
import '../models/sales_invoice_model.dart';
import '../models/vendor_model.dart';

class PurchaseInvoiceService {
  PurchaseInvoiceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _purchaseCollection =>
      _firestore.collection(FirestoreCollections.purchaseInvoices);

  Stream<List<PurchaseInvoiceModel>> watchPurchaseInvoices(String businessId) {
    return _purchaseCollection
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final invoices =
              snapshot.docs.map(PurchaseInvoiceModel.fromDoc).toList()
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

  Stream<PurchaseInvoiceModel?> watchPurchaseInvoice({
    required String businessId,
    required String invoiceId,
  }) {
    return _purchaseCollection.doc(invoiceId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final invoice = PurchaseInvoiceModel.fromDoc(snapshot);
      if (invoice.businessId != businessId) return null;
      return invoice;
    });
  }

  String generatePurchaseNumber(String docId) {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'PX-$date-${docId.substring(0, 6).toUpperCase()}';
  }

  Future<String> createPurchaseInvoice({
    required String businessId,
    required VendorModel vendor,
    required List<PurchaseInvoiceItem> items,
    required double paidAmount,
    required String notes,
  }) async {
    if (businessId.isEmpty) {
      throw StateError('Business profile is required.');
    }
    if (vendor.businessId != businessId) {
      throw StateError('Vendor is outside the active business scope.');
    }
    if (items.isEmpty) {
      throw StateError('Add at least one product.');
    }

    final invoiceRef = _purchaseCollection.doc();
    final invoiceNumber = generatePurchaseNumber(invoiceRef.id);
    final totals = _calculateTotals(items, paidAmount);

    await _firestore.runTransaction((transaction) async {
      final vendorRef = _firestore
          .collection(FirestoreCollections.vendors)
          .doc(vendor.id);
      final vendorSnapshot = await transaction.get(vendorRef);
      final vendorData = vendorSnapshot.data();
      if (vendorData == null ||
          vendorData[FirestoreFields.businessId] != businessId) {
        throw StateError('Vendor is outside the active business scope.');
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

        transaction.update(productRef, {
          'stockQuantity': FieldValue.increment(item.quantity),
          'stock': FieldValue.increment(item.quantity),
          'purchasePrice': item.rate,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
      }

      final invoice = PurchaseInvoiceModel(
        id: invoiceRef.id,
        businessId: businessId,
        invoiceNumber: invoiceNumber,
        vendorId: vendor.id,
        vendorName: vendor.name,
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
      transaction.update(vendorRef, {
        'outstandingPayable': FieldValue.increment(totals.balanceAmount),
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
    });

    return invoiceRef.id;
  }

  _PurchaseTotals _calculateTotals(
    List<PurchaseInvoiceItem> items,
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

    return _PurchaseTotals(
      subtotal: subtotal,
      discountTotal: discountTotal,
      gstTotal: gstTotal,
      totalAmount: totalAmount,
      paidAmount: normalizedPaid,
      balanceAmount: totalAmount - normalizedPaid,
    );
  }
}

class _PurchaseTotals {
  const _PurchaseTotals({
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
