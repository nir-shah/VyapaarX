import 'package:firebase_auth/firebase_auth.dart';

class AuthSession {
  const AuthSession({
    required this.uid,
    required this.email,
    required this.phoneNumber,
    required this.displayName,
    required this.role,
    required this.isDisabled,
    required this.businessId,
    required this.hasBusinessProfile,
  });

  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String role;
  final bool isDisabled;
  final String? businessId;
  final bool hasBusinessProfile;

  bool get needsBusinessSetup => !hasBusinessProfile;

  factory AuthSession.fromFirebaseUser({
    required User user,
    required Map<String, dynamic>? profile,
    required bool hasBusinessProfile,
  }) {
    final role = profile?['role'] as String?;
    final status = profile?['status'] as String?;
    final businessId =
        profile?['businessId'] as String? ?? profile?['business_id'] as String?;

    return AuthSession(
      uid: user.uid,
      email: user.email ?? profile?['email'] as String?,
      phoneNumber: user.phoneNumber ?? profile?['phoneNumber'] as String?,
      displayName: user.displayName ?? profile?['displayName'] as String?,
      role: role == null || role.isEmpty ? 'owner' : role,
      isDisabled: status?.toLowerCase() == 'disabled',
      businessId: businessId == null || businessId.isEmpty ? null : businessId,
      hasBusinessProfile: hasBusinessProfile,
    );
  }
}
