import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firestore_collections.dart';
import '../core/constants/firestore_fields.dart';
import '../models/auth_session.dart';
import '../models/phone_otp_result.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthSession?> loadCurrentSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return loadSessionForUser(user);
  }

  Future<AuthSession> loadSessionForUser(User user) async {
    final profileSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .get();
    final profile = profileSnapshot.data();
    final businessId = profile?[FirestoreFields.businessId] as String?;
    final hasBusinessProfile = await _hasValidBusinessProfile(businessId);

    return AuthSession.fromFirebaseUser(
      user: user,
      profile: profile,
      hasBusinessProfile: hasBusinessProfile,
    );
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<PhoneOtpResult> sendPhoneOtp({
    required String phoneNumber,
    int? forceResendingToken,
  }) {
    final completer = Completer<PhoneOtpResult>();

    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        if (!completer.isCompleted) {
          await _auth.signInWithCredential(credential);
          completer.complete(
            const PhoneOtpResult(verificationId: '', isAutoVerified: true),
          );
        }
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneOtpResult(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() => _auth.signOut();

  Future<bool> _hasValidBusinessProfile(String? businessId) async {
    if (businessId == null || businessId.isEmpty) return false;

    final businessSnapshot = await _firestore
        .collection(FirestoreCollections.businesses)
        .doc(businessId)
        .get();
    final data = businessSnapshot.data();
    if (data == null) return false;

    return data[FirestoreFields.businessId] == businessId;
  }
}
