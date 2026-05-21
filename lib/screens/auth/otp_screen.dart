import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

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
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.responsiveScreenPadding(context),
          children: [
            Card(
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Enter verification code',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'We sent a 6 digit OTP to ${widget.phoneNumber}.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(letterSpacing: 8),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '000000',
                      ),
                      onSubmitted: (_) => _verifyOtp(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: auth.isLoading ? null : _resendOtp,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: 'Verify and continue',
          icon: Icons.verified_user_outlined,
          isLoading: auth.isLoading,
          onPressed: _verifyOtp,
        ),
      ),
    );
  }
}
