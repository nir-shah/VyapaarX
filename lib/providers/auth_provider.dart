import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_session.dart';
import '../models/phone_otp_result.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  checking,
  unauthenticated,
  authenticated,
  needsBusinessSetup,
  disabled,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen(_handleAuthChange);
  }

  final AuthService _authService;
  StreamSubscription<User?>? _authSubscription;

  AuthStatus _status = AuthStatus.checking;
  AuthSession? _session;
  String? _errorMessage;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _session != null;
  bool get hasBusinessProfile => _session?.hasBusinessProfile ?? false;
  bool get isDisabled => _session?.isDisabled ?? false;
  String? get businessId => _session?.businessId;
  String get role => _session?.role ?? 'guest';
  String? get verificationId => _verificationId;

  Future<void> initializeSession() async {
    await _runWithLoading(() async {
      final session = await _authService.loadCurrentSession();
      _applySession(session);
    });
  }

  Future<void> refreshSession() => initializeSession();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _runWithLoading(() async {
      final credential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Unable to load the signed-in account.',
        );
      }
      final session = await _authService.loadSessionForUser(user);
      _applySession(session);
    });
  }

  Future<PhoneOtpResult> sendPhoneOtp({
    required String phoneNumber,
    bool forceResend = false,
  }) async {
    late PhoneOtpResult result;
    await _runWithLoading(() async {
      result = await _authService.sendPhoneOtp(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResend ? _resendToken : null,
      );
      _verificationId = result.verificationId;
      _resendToken = result.resendToken;

      if (result.isAutoVerified) {
        final session = await _authService.loadCurrentSession();
        _applySession(session);
      }
    });
    return result;
  }

  Future<void> verifyPhoneOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null || verificationId.isEmpty) {
      _setError('Please request a new OTP before verifying.');
      return;
    }

    await _runWithLoading(() async {
      final credential = await _authService.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Unable to load the verified account.',
        );
      }
      final session = await _authService.loadSessionForUser(user);
      _applySession(session);
    });
  }

  Future<void> signOut() async {
    await _runWithLoading(() async {
      await _authService.signOut();
      _verificationId = null;
      _resendToken = null;
      _applySession(null);
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthChange(User? user) async {
    if (_isLoading) return;
    if (user == null) {
      _applySession(null);
      return;
    }

    try {
      final session = await _authService.loadSessionForUser(user);
      _applySession(session);
    } on Object catch (error) {
      _setError(_friendlyError(error));
    }
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on Object catch (error) {
      _setError(_friendlyError(error), notify: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applySession(AuthSession? session) {
    _session = session;
    if (session == null) {
      _status = AuthStatus.unauthenticated;
    } else if (session.isDisabled) {
      _status = AuthStatus.disabled;
    } else if (session.needsBusinessSetup) {
      _status = AuthStatus.needsBusinessSetup;
    } else {
      _status = AuthStatus.authenticated;
    }
  }

  void _setError(String message, {bool notify = true}) {
    _errorMessage = message;
    if (notify) notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        'user-not-found' => 'No account found for this email.',
        'wrong-password' => 'Incorrect password. Please try again.',
        'invalid-credential' => 'Invalid login details. Please try again.',
        'invalid-phone-number' =>
          'Enter a valid phone number with country code.',
        'invalid-verification-code' => 'The OTP is incorrect or expired.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        _ => error.message ?? 'Authentication failed. Please try again.',
      };
    }

    if (error is FirebaseException) {
      return error.message ?? 'Firebase request failed. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
