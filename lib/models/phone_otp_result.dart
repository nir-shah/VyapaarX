class PhoneOtpResult {
  const PhoneOtpResult({
    required this.verificationId,
    this.resendToken,
    this.isAutoVerified = false,
  });

  final String verificationId;
  final int? resendToken;
  final bool isAutoVerified;
}
