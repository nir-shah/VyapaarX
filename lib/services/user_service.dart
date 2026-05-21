import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_roles.dart';
import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/app_user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<AppUserModel>> watchBusinessUsers(String businessId) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map(AppUserModel.fromDoc).toList();
          users.sort((left, right) {
            final roleCompare = left.role.index.compareTo(right.role.index);
            if (roleCompare != 0) return roleCompare;
            return left.displayName.toLowerCase().compareTo(
              right.displayName.toLowerCase(),
            );
          });
          return users;
        });
  }

  Future<void> createUserProfile({
    required String businessId,
    required String uid,
    required String displayName,
    required String email,
    required String phoneNumber,
    required AppRole role,
  }) async {
    final manager = await _loadCurrentManager(businessId);
    _validateManageableRole(manager.role, role);

    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Firebase UID is required.',
      );
    }

    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(normalizedUid);
    final existing = await userRef.get();
    if (existing.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'A user profile already exists for this UID.',
      );
    }

    final user = AppUserModel(
      uid: normalizedUid,
      businessId: businessId,
      displayName: displayName.trim(),
      email: email.trim().toLowerCase(),
      phoneNumber: phoneNumber.trim(),
      role: role,
      status: AppUserStatus.active,
    );

    await userRef.set(user.toCreateMap(createdByUid: manager.uid));
  }

  Future<void> updateUserRole({
    required String businessId,
    required AppUserModel user,
    required AppRole role,
  }) async {
    final manager = await _loadCurrentManager(businessId);
    _validateTargetBusiness(user.businessId, businessId);
    _validateManageableRole(manager.role, role);
    _validateManageableRole(manager.role, user.role);

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .update({
          FirestoreFields.businessId: businessId,
          FirestoreFields.role: role.value,
          FirestoreFields.status: user.status.value,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
  }

  Future<void> setUserDisabled({
    required String businessId,
    required AppUserModel user,
    required bool disabled,
  }) async {
    final manager = await _loadCurrentManager(businessId);
    _validateTargetBusiness(user.businessId, businessId);
    _validateManageableRole(manager.role, user.role);

    if (manager.uid == user.uid && disabled) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'You cannot disable your own account.',
      );
    }

    if (user.role == AppRole.owner && disabled) {
      await _ensureAnotherActiveOwner(businessId, user.uid);
    }

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .update({
          FirestoreFields.businessId: businessId,
          FirestoreFields.status: disabled
              ? AppUserStatus.disabled.value
              : AppUserStatus.active.value,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
  }

  Future<AppUserModel> _loadCurrentManager(String businessId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseException(
        plugin: 'firebase_auth',
        message: 'Please sign in again.',
      );
    }

    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(currentUser.uid)
        .get();
    if (!snapshot.exists) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Your user profile was not found.',
      );
    }

    final manager = AppUserModel.fromDoc(snapshot);
    _validateTargetBusiness(manager.businessId, businessId);
    if (manager.isDisabled) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Your account is disabled.',
      );
    }
    if (!RolePermissions.canManageUsers(manager.role.value)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only owners and admins can manage users.',
      );
    }
    return manager;
  }

  void _validateTargetBusiness(
    String targetBusinessId,
    String activeBusinessId,
  ) {
    if (targetBusinessId != activeBusinessId) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'You cannot manage another business data.',
      );
    }
  }

  void _validateManageableRole(AppRole managerRole, AppRole targetRole) {
    if (managerRole == AppRole.owner) return;
    if (targetRole == AppRole.owner) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only owners can manage owner access.',
      );
    }
  }

  Future<void> _ensureAnotherActiveOwner(
    String businessId,
    String disabledUid,
  ) async {
    final owners = await _firestore
        .collection(FirestoreCollections.users)
        .where(FirestoreFields.businessId, isEqualTo: businessId)
        .where(FirestoreFields.role, isEqualTo: AppRole.owner.value)
        .get();

    final hasAnotherActiveOwner = owners.docs
        .map(AppUserModel.fromDoc)
        .any(
          (owner) =>
              owner.uid != disabledUid && owner.status == AppUserStatus.active,
        );
    if (!hasAnotherActiveOwner) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'At least one active owner is required.',
      );
    }
  }
}
