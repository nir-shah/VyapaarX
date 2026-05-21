import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Please login before creating a business profile.',
      );
    }

    String? logoUrl;
    if (logoBytes != null) {
      logoUrl = await _uploadLogo(
        businessId: business.businessId,
        bytes: logoBytes,
        fileName: logoFileName,
        contentType: logoContentType,
      );
    }

    final businessData = BusinessModel(
      businessId: business.businessId,
      ownerUid: user.uid,
      name: business.name,
      address: business.address,
      phone: business.phone,
      alternatePhone: business.alternatePhone,
      email: business.email,
      businessType: business.businessType,
      gstin: business.gstin,
      logoUrl: logoUrl,
    ).toFirestore(includeServerTimestamps: true);

    final businessRef = _firestore
        .collection(FirestoreCollections.businesses)
        .doc(business.businessId);
    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid);

    final batch = _firestore.batch();
    batch.set(businessRef, businessData);
    batch.set(userRef, {
      FirestoreFields.businessId: business.businessId,
      FirestoreFields.role: 'owner',
      FirestoreFields.status: 'active',
      FirestoreFields.displayName: user.displayName ?? business.name,
      FirestoreFields.email: user.email ?? business.email,
      FirestoreFields.phoneNumber: user.phoneNumber ?? business.phone,
      FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreFields.createdAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return business.businessId;
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
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'Please login before updating business settings.',
      );
    }

    var logoUrl = business.logoUrl;
    if (logoBytes != null) {
      logoUrl = await _uploadLogo(
        businessId: business.businessId,
        bytes: logoBytes,
        fileName: logoFileName,
        contentType: logoContentType,
      );
    }

    await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(business.businessId)
        .update({
          FirestoreFields.businessId: business.businessId,
          'ownerUid': business.ownerUid,
          'name': business.name,
          'address': business.address,
          'phone': business.phone,
          'alternatePhone': business.alternatePhone,
          FirestoreFields.email: business.email,
          'businessType': business.businessType,
          'gstin': business.gstin,
          'logoUrl': logoUrl,
          'preferences': business.preferences,
          FirestoreFields.updatedAt: FieldValue.serverTimestamp(),
        });
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
