import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/advanced_erp_models.dart';
import '../models/product_model.dart';
import '../models/purchase_invoice_model.dart';
import '../models/sales_invoice_model.dart';

class AdvancedErpService {
  AdvancedErpService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<WarehouseModel>> watchWarehouses(String businessId) {
    return _watchScoped(
      collection: FirestoreCollections.warehouses,
      businessId: businessId,
      fromDoc: WarehouseModel.fromDoc,
      sort: (items) => items
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  Stream<List<CrmLeadModel>> watchLeads(String businessId) {
    return _watchScoped(
      collection: FirestoreCollections.crmLeads,
      businessId: businessId,
      fromDoc: CrmLeadModel.fromDoc,
      sort: (items) => items
        ..sort(
          (a, b) =>
              _dateMillis(b.createdAt).compareTo(_dateMillis(a.createdAt)),
        ),
    );
  }

  Stream<List<ErpTaskModel>> watchTasks(String businessId) {
    return _watchScoped(
      collection: FirestoreCollections.tasks,
      businessId: businessId,
      fromDoc: ErpTaskModel.fromDoc,
      sort: (items) => items..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
    );
  }

  Stream<List<AppNotificationModel>> watchNotifications(String businessId) {
    return _watchScoped(
      collection: FirestoreCollections.notifications,
      businessId: businessId,
      fromDoc: AppNotificationModel.fromDoc,
      sort: (items) => items
        ..sort(
          (a, b) =>
              _dateMillis(b.createdAt).compareTo(_dateMillis(a.createdAt)),
        ),
    );
  }

  Stream<List<AuditLogModel>> watchAuditLogs(String businessId) {
    return _watchScoped(
      collection: FirestoreCollections.auditLogs,
      businessId: businessId,
      fromDoc: AuditLogModel.fromDoc,
      sort: (items) => items
        ..sort(
          (a, b) =>
              _dateMillis(b.createdAt).compareTo(_dateMillis(a.createdAt)),
        ),
      limit: 30,
    );
  }

  Future<ProductModel?> findProductByBarcode({
    required String businessId,
    required String barcode,
  }) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty) return null;

    final snapshot = await _firestore
        .collection(FirestoreCollections.products)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .where('barcode', isEqualTo: normalized)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return ProductModel.fromDoc(snapshot.docs.first);
  }

  Future<void> createWarehouse({
    required String businessId,
    required String actorId,
    required String name,
    required String address,
    required String managerName,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.warehouses).doc();
    final warehouse = WarehouseModel(
      id: doc.id,
      businessId: businessId,
      name: name.trim(),
      address: address.trim(),
      managerName: managerName.trim(),
      isActive: true,
    );
    await doc.set(warehouse.toCreateMap());
    await recordAuditLog(
      businessId: businessId,
      actorId: actorId,
      module: 'Multi warehouse',
      action: 'created',
      description: 'Warehouse ${warehouse.name} created.',
    );
  }

  Future<void> createLead({
    required String businessId,
    required String actorId,
    required String name,
    required String phone,
    required String stage,
    required String notes,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.crmLeads).doc();
    final lead = CrmLeadModel(
      id: doc.id,
      businessId: businessId,
      name: name.trim(),
      phone: phone.trim(),
      stage: stage,
      notes: notes.trim(),
    );
    await doc.set(lead.toCreateMap());
    await recordAuditLog(
      businessId: businessId,
      actorId: actorId,
      module: 'CRM',
      action: 'created',
      description: 'Lead ${lead.name} created.',
    );
  }

  Future<void> createTask({
    required String businessId,
    required String actorId,
    required String title,
    required String assignedTo,
    required DateTime dueDate,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.tasks).doc();
    final task = ErpTaskModel(
      id: doc.id,
      businessId: businessId,
      title: title.trim(),
      assignedTo: assignedTo.trim(),
      dueDate: dueDate,
      isDone: false,
    );
    await doc.set(task.toCreateMap());
    await recordAuditLog(
      businessId: businessId,
      actorId: actorId,
      module: 'Tasks',
      action: 'created',
      description: 'Task ${task.title} created.',
    );
  }

  Future<void> setTaskDone({
    required String businessId,
    required String actorId,
    required ErpTaskModel task,
    required bool isDone,
  }) async {
    _ensureBusinessScope(task.businessId, businessId);
    await _firestore
        .collection(FirestoreCollections.tasks)
        .doc(task.id)
        .update({
          FirestoreFields.businessId: businessId,
          'isDone': isDone,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
    await recordAuditLog(
      businessId: businessId,
      actorId: actorId,
      module: 'Tasks',
      action: isDone ? 'completed' : 'reopened',
      description: 'Task ${task.title} ${isDone ? 'completed' : 'reopened'}.',
    );
  }

  Future<void> createNotification({
    required String businessId,
    required String actorId,
    required String title,
    required String message,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.notifications).doc();
    final notification = AppNotificationModel(
      id: doc.id,
      businessId: businessId,
      title: title.trim(),
      message: message.trim(),
      isRead: false,
    );
    await doc.set(notification.toCreateMap());
    await recordAuditLog(
      businessId: businessId,
      actorId: actorId,
      module: 'Notifications',
      action: 'created',
      description: 'Notification ${notification.title} created.',
    );
  }

  Future<void> markNotificationRead({
    required String businessId,
    required AppNotificationModel notification,
  }) async {
    _ensureBusinessScope(notification.businessId, businessId);
    await _firestore
        .collection(FirestoreCollections.notifications)
        .doc(notification.id)
        .update({FirestoreFields.businessId: businessId, 'isRead': true});
  }

  Future<void> recordAuditLog({
    required String businessId,
    required String actorId,
    required String module,
    required String action,
    required String description,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.auditLogs).doc();
    final log = AuditLogModel(
      id: doc.id,
      businessId: businessId,
      action: action,
      module: module,
      actorId: actorId,
      description: description,
    );
    await doc.set(log.toCreateMap());
  }

  Future<String> buildGstExportCsv(String businessId) async {
    final salesSnapshot = await _scopedCollection(
      FirestoreCollections.salesInvoices,
      businessId,
    ).get();
    final purchaseSnapshot = await _scopedCollection(
      FirestoreCollections.purchaseInvoices,
      businessId,
    ).get();

    final rows = <List<String>>[
      [
        'type',
        'invoiceNumber',
        'party',
        'taxableAmount',
        'gstAmount',
        'totalAmount',
        'paidAmount',
        'balanceAmount',
      ],
    ];

    for (final doc in salesSnapshot.docs) {
      final invoice = SalesInvoiceModel.fromDoc(doc);
      rows.add([
        'sales',
        invoice.invoiceNumber,
        invoice.customerName,
        invoice.subtotal.toStringAsFixed(2),
        invoice.gstTotal.toStringAsFixed(2),
        invoice.totalAmount.toStringAsFixed(2),
        invoice.paidAmount.toStringAsFixed(2),
        invoice.balanceAmount.toStringAsFixed(2),
      ]);
    }

    for (final doc in purchaseSnapshot.docs) {
      final invoice = PurchaseInvoiceModel.fromDoc(doc);
      rows.add([
        'purchase',
        invoice.invoiceNumber,
        invoice.vendorName,
        invoice.subtotal.toStringAsFixed(2),
        invoice.gstTotal.toStringAsFixed(2),
        invoice.totalAmount.toStringAsFixed(2),
        invoice.paidAmount.toStringAsFixed(2),
        invoice.balanceAmount.toStringAsFixed(2),
      ]);
    }

    return rows.map((row) => row.map(_csvCell).join(',')).join('\n');
  }

  Future<String> buildBackupJson(String businessId) async {
    final collections = [
      FirestoreCollections.businesses,
      FirestoreCollections.customers,
      FirestoreCollections.vendors,
      FirestoreCollections.products,
      FirestoreCollections.salesInvoices,
      FirestoreCollections.purchaseInvoices,
      FirestoreCollections.expenses,
      FirestoreCollections.warehouses,
      FirestoreCollections.crmLeads,
      FirestoreCollections.tasks,
      FirestoreCollections.notifications,
    ];

    final backup = <String, Object?>{
      'businessId': businessId,
      'exportedAt': DateTime.now().toIso8601String(),
      'collections': <String, Object?>{},
    };
    final collectionData = backup['collections']! as Map<String, Object?>;

    for (final collection in collections) {
      final snapshot = collection == FirestoreCollections.businesses
          ? await _firestore
                .collection(collection)
                .where(FirestoreFields.businessId, isEqualTo: businessId)
                .get()
          : await _scopedCollection(collection, businessId).get();
      collectionData[collection] = snapshot.docs
          .map((doc) => {'id': doc.id, 'data': _jsonSafe(doc.data())})
          .toList();
    }

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> printThermalTestReceipt({
    required String businessName,
    required String businessId,
  }) async {
    final bytes = await _buildThermalReceiptPdf(
      businessName: businessName,
      businessId: businessId,
    );
    await Printing.layoutPdf(
      name: 'thermal-test-receipt.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Stream<List<T>> _watchScoped<T>({
    required String collection,
    required String businessId,
    required T Function(DocumentSnapshot<Map<String, dynamic>>) fromDoc,
    List<T> Function(List<T>)? sort,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _scopedCollection(
      collection,
      businessId,
    );
    if (limit != null) query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(fromDoc).toList();
      return sort == null ? items : sort(items);
    });
  }

  Query<Map<String, dynamic>> _scopedCollection(
    String collection,
    String businessId,
  ) {
    return _firestore
        .collection(collection)
        .where(FirestoreFields.businessId, isEqualTo: businessId);
  }

  void _ensureBusinessScope(String targetBusinessId, String activeBusinessId) {
    if (targetBusinessId != activeBusinessId) {
      throw StateError('Data is outside the active business scope.');
    }
  }

  int _dateMillis(DateTime? date) {
    return date?.millisecondsSinceEpoch ?? 0;
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Object? _jsonSafe(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), _jsonSafe(mapValue)),
      );
    }
    if (value is Iterable) return value.map(_jsonSafe).toList();
    return value;
  }

  Future<Uint8List> _buildThermalReceiptPdf({
    required String businessName,
    required String businessId,
  }) async {
    final document = pw.Document(
      title: 'Thermal Test Receipt',
      author: businessName,
      creator: 'VyapaarX',
    );

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              businessName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'VyapaarX thermal test',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.Divider(),
            _thermalRow('Business ID', businessId),
            _thermalRow('Date', DateTime.now().toString().substring(0, 16)),
            _thermalRow('Status', 'Printer ready'),
            pw.Divider(),
            pw.Text(
              'Use this for 80mm printers. Bluetooth/USB device binding can be added after selecting printer hardware.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _thermalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}
