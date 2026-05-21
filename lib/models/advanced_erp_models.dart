import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_fields.dart';
import '../core/utils/firestore_timestamp_helper.dart';

class WarehouseModel {
  const WarehouseModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.address,
    required this.managerName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String address;
  final String managerName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'address': address,
      'managerName': managerName,
      'isActive': isActive,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  factory WarehouseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WarehouseModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      managerName: data['managerName'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }
}

class CrmLeadModel {
  const CrmLeadModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    required this.stage,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String stage;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'name': name,
      'phone': phone,
      'stage': stage,
      'notes': notes,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  factory CrmLeadModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CrmLeadModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      stage: data['stage'] as String? ?? 'New',
      notes: data['notes'] as String? ?? '',
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }
}

class ErpTaskModel {
  const ErpTaskModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.assignedTo,
    required this.dueDate,
    required this.isDone,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final String assignedTo;
  final DateTime dueDate;
  final bool isDone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'title': title,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'isDone': isDone,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  factory ErpTaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ErpTaskModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      title: data['title'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      dueDate:
          FirestoreTimestampHelper.tryRead(data['dueDate']) ?? DateTime.now(),
      isDone: data['isDone'] as bool? ?? false,
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
      updatedAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.updatedAt],
      ),
    );
  }
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'title': title,
      'message': message,
      'isRead': isRead,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
    };
  }

  factory AppNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppNotificationModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
    );
  }
}

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.businessId,
    required this.action,
    required this.module,
    required this.actorId,
    required this.description,
    this.createdAt,
  });

  final String id;
  final String businessId;
  final String action;
  final String module;
  final String actorId;
  final String description;
  final DateTime? createdAt;

  Map<String, Object?> toCreateMap() {
    return {
      FirestoreFields.businessId: businessId,
      'action': action,
      'module': module,
      'actorId': actorId,
      'description': description,
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
    };
  }

  factory AuditLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AuditLogModel(
      id: doc.id,
      businessId: data[FirestoreFields.businessId] as String? ?? '',
      action: data['action'] as String? ?? '',
      module: data['module'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: FirestoreTimestampHelper.tryRead(
        data[FirestoreFields.createdAt],
      ),
    );
  }
}
