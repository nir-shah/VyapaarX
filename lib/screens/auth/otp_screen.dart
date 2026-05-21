import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_button.dart';
import 'widgets/otp_input_field.dart';
import 'widgets/otp_timer.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      SnackBarHelper.show(
        context,
        message: 'Enter the 6 digit OTP.',
        type: AppSnackBarType.warning,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.verifyPhoneOtp(otp);
    if (!mounted) return;

    if (auth.errorMessage != null) {
      SnackBarHelper.show(
        context,
        message: auth.errorMessage!,
        type: AppSnackBarType.error,
      );
      return;
    }

    SnackBarHelper.show(
      context,
      message: 'Phone number verified successfully.',
      type: AppSnackBarType.success,
    );

    final routeName = switch (auth.status) {
      AuthStatus.authenticated || AuthStatus.disabled => AppRoutes.dashboard,
      AuthStatus.needsBusinessSetup => AppRoutes.businessSetup,
      AuthStatus.checking || AuthStatus.unauthenticated => AppRoutes.login,
    };
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
  }

  Future<void> _resendOtp() async {
    final auth = context.read<AuthProvider>();
    await auth.sendPhoneOtp(phoneNumber: widget.phoneNumber, forceResend: true);
    if (!mounted) return;

    SnackBarHelper.show(
      context,
      message: auth.errorMessage ?? 'OTP sent again.',
      type: auth.errorMessage == null
          ? AppSnackBarType.success
          : AppSnackBarType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFFDF8), Color(0xFFF8FAFC), Color(0xFFEAF2FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _OtpVerificationCard(
                  phoneNumber: widget.phoneNumber,
                  controller: _otpController,
                  isLoading: auth.isLoading,
                  onVerify: _verifyOtp,
                  onResend: _resendOtp,
                  onChangeNumber: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpVerificationCard extends StatelessWidget {
  const _OtpVerificationCard({
    required this.phoneNumber,
    required this.controller,
    required this.isLoading,
    required this.onVerify,
    required this.onResend,
    required this.onChangeNumber,
  });

  final String phoneNumber;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onVerify;
  final Future<void> Function() onResend;
  final VoidCallback onChangeNumber;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xxlRadius,
        boxShadow: AppShadows.card,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: AppRadius.xxlRadius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Verify your number',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We sent a 6-digit code to ${_formatPhone(phoneNumber)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            OtpInputField(
              controller: controller,
              enabled: !isLoading,
              onCompleted: (_) => onVerify(),
            ),
            const SizedBox(height: AppSpacing.lg),
            OtpTimer(onResend: onResend, enabled: !isLoading),
            const SizedBox(height: AppSpacing.lg),
            AuthButton(
              label: 'Verify and continue',
              icon: Icons.verified_user_outlined,
              isLoading: isLoading,
              onPressed: onVerify,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: isLoading ? null : onChangeNumber,
              child: const Text('Change number'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPhone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final lastTen = digits.substring(digits.length - 10);
      return '+91 ${lastTen.substring(0, 5)} ${lastTen.substring(5)}';
    }
    return phoneNumber;
  }
}
