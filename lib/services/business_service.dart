import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/business_model.dart';

class BusinessService {
  BusinessService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<String> createBusiness({
    required BusinessModel business,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Please login before creating a business profile.',
        );
      }

      debugPrint('BusinessService.createBusiness current user id: ${user.uid}');
      debugPrint(
        'BusinessService.createBusiness businessId: ${business.businessId}',
      );
      debugPrint(
        'BusinessService.createBusiness form values: '
        'name=${business.name}, phone=${business.phone}, '
        'email=${business.email}, gstin=${business.gstin.isEmpty ? '(empty)' : business.gstin}, '
        'address=${business.address}, city=${business.city}, '
        'state=${business.state}, pincode=${business.pinCode}',
      );

      final businessRef = _firestore
          .collection(FirestoreCollections.businesses)
          .doc(business.businessId);
      final userRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid);
      debugPrint(
        'BusinessService.createBusiness Firestore path: ${businessRef.path}',
      );
      debugPrint('BusinessService.createBusiness user path: ${userRef.path}');

      final businessData = BusinessModel(
        businessId: business.businessId,
        ownerUid: user.uid,
        name: business.name,
        address: business.address,
        city: business.city,
        state: business.state,
        pinCode: business.pinCode,
        phone: business.phone,
        alternatePhone: business.alternatePhone,
        email: business.email,
        businessType: business.businessType,
        gstin: business.gstin,
      ).toFirestore(includeServerTimestamps: true);

      final batch = _firestore.batch();
      batch.set(businessRef, businessData);
      batch.set(userRef, {
        FirestoreFields.businessId: business.businessId,
        FirestoreFields.role: 'owner',
        FirestoreFields.status: 'active',
        'isActive': true,
        FirestoreFields.displayName: user.displayName ?? business.name,
        FirestoreFields.email: user.email ?? business.email,
        FirestoreFields.phoneNumber: user.phoneNumber ?? business.phone,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        FirestoreFields.createdAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      debugPrint('Created businessId: ${business.businessId}');
      debugPrint('Updated user businessId: ${business.businessId}');

      if (logoBytes == null) {
        debugPrint('BusinessService.createBusiness logo upload skipped.');
        return business.businessId;
      }

      debugPrint(
        'BusinessService.createBusiness uploading logo: '
        'businesses/${business.businessId}/logo/${logoFileName ?? 'logo.jpg'}',
      );
      final logoUrl = await _uploadLogo(
        businessId: business.businessId,
        bytes: logoBytes,
        fileName: logoFileName,
        contentType: logoContentType,
      );
      debugPrint('BusinessService.createBusiness logo uploaded.');

      await businessRef.update({
        'logoUrl': logoUrl,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });

      return business.businessId;
    } catch (e, st) {
      debugPrint('Business save failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  String createBusinessId() {
    return _firestore.collection(FirestoreCollections.businesses).doc().id;
  }

  Stream<BusinessModel?> watchBusiness(String businessId) {
    if (businessId.isEmpty) return Stream.value(null);

    return _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          final business = BusinessModel.fromFirestore(snapshot);
          if (business.businessId != businessId) return null;
          return business;
        });
  }

  Future<BusinessModel?> getBusiness(String businessId) async {
    if (businessId.isEmpty) return null;

    final snapshot = await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .get();
    if (!snapshot.exists) return null;
    return BusinessModel.fromFirestore(snapshot);
  }

  Future<void> updateBusinessSettings({
    required BusinessModel business,
    Uint8List? logoBytes,
    String? logoFileName,
    String? logoContentType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'Please login before updating business settings.',
        );
      }

      debugPrint(
        'BusinessService.updateBusinessSettings current user id: ${user.uid}',
      );
      debugPrint(
        'BusinessService.updateBusinessSettings businessId: ${business.businessId}',
      );
      debugPrint(
        'BusinessService.updateBusinessSettings values: '
        'name=${business.name}, phone=${business.phone}, '
        'email=${business.email}, gstin=${business.gstin.isEmpty ? '(empty)' : business.gstin}, '
        'address=${business.address}',
      );

      var logoUrl = business.logoUrl;
      if (logoBytes != null) {
        debugPrint('BusinessService.updateBusinessSettings uploading logo.');
        logoUrl = await _uploadLogo(
          businessId: business.businessId,
          bytes: logoBytes,
          fileName: logoFileName,
          contentType: logoContentType,
        );
      } else {
        debugPrint(
          'BusinessService.updateBusinessSettings logo upload skipped.',
        );
      }

      final businessRef = _firestore
          .collection(FirestoreCollections.businesses)
          .doc(business.businessId);
      debugPrint(
        'BusinessService.updateBusinessSettings Firestore path: ${businessRef.path}',
      );

      await businessRef.update({
        FirestoreFields.businessId: business.businessId,
        'ownerId': business.ownerUid,
        'ownerUid': business.ownerUid,
        'businessName': business.name,
        'name': business.name,
        'address': business.address,
        'city': business.city,
        'state': business.state,
        'pincode': business.pinCode,
        'pinCode': business.pinCode,
        'phone': business.phone,
        'alternatePhone': business.alternatePhone,
        FirestoreFields.email: business.email,
        'businessType': business.businessType,
        'gstin': business.gstin,
        'logoUrl': logoUrl,
        'preferences': business.preferences,
        FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('Business settings save failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<String> _uploadLogo({
    required String businessId,
    required Uint8List bytes,
    String? fileName,
    String? contentType,
  }) async {
    final normalizedName = _normalizeFileName(fileName ?? 'logo.jpg');
    final ref = _storage.ref('businesses/$businessId/logo/$normalizedName');
    final metadata = SettableMetadata(
      contentType: contentType ?? _contentTypeFor(normalizedName),
      customMetadata: {FirestoreFields.businessId: businessId},
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  String _normalizeFileName(String fileName) {
    final safeName = fileName.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9._-]'),
      '-',
    );
    if (safeName.isEmpty) return 'logo.jpg';
    return safeName;
  }

  String _contentTypeFor(String fileName) {
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
