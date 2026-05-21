import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_brand_panel.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_input.dart';
import 'widgets/auth_tab_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _usePhone = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (_usePhone) {
      final phoneNumber = _normalizeIndianPhone(_phoneController.text);
      final result = await auth.sendPhoneOtp(phoneNumber: phoneNumber);
      if (!mounted) return;

      if (auth.errorMessage != null) {
        SnackBarHelper.show(
          context,
          message: auth.errorMessage!,
          type: AppSnackBarType.error,
        );
        return;
      }

      if (result.isAutoVerified) {
        _redirectAfterAuth(auth);
        return;
      }

      Navigator.of(context).pushNamed(AppRoutes.otp, arguments: phoneNumber);
      return;
    }

    await auth.signInWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (auth.errorMessage != null) {
      SnackBarHelper.show(
        context,
        message: auth.errorMessage!,
        type: AppSnackBarType.error,
      );
      return;
    }

    _redirectAfterAuth(auth);
  }

  void _redirectAfterAuth(AuthProvider auth) {
    final routeName = switch (auth.status) {
      AuthStatus.authenticated || AuthStatus.disabled => AppRoutes.dashboard,
      AuthStatus.needsBusinessSetup => AppRoutes.businessSetup,
      AuthStatus.checking || AuthStatus.unauthenticated => AppRoutes.login,
    };
    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
  }

  String _normalizeIndianPhone(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    final digits = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _setMode(bool usePhone) {
    if (_usePhone == usePhone) return;
    setState(() => _usePhone = usePhone);
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 920;
              return isDesktop
                  ? _DesktopLoginLayout(
                      child: _LoginCardContent(
                        formKey: _formKey,
                        usePhone: _usePhone,
                        isLoading: auth.isLoading,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onModeChanged: _setMode,
                        onSubmit: _submit,
                        onTogglePassword: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    )
                  : _MobileLoginLayout(
                      child: _LoginCardContent(
                        formKey: _formKey,
                        usePhone: _usePhone,
                        isLoading: auth.isLoading,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        obscurePassword: _obscurePassword,
                        onModeChanged: _setMode,
                        onSubmit: _submit,
                        onTogglePassword: () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                      ),
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _DesktopLoginLayout extends StatelessWidget {
  const _DesktopLoginLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180, minHeight: 660),
          child: Row(
            children: [
              const Expanded(child: AuthBrandPanel()),
              const SizedBox(width: 56),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileLoginLayout extends StatelessWidget {
  const _MobileLoginLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          width < 380 ? AppSpacing.md : AppSpacing.xl,
          AppSpacing.xl,
          width < 380 ? AppSpacing.md : AppSpacing.xl,
          AppSpacing.xl + viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: child,
        ),
      ),
    );
  }
}

class _LoginCardContent extends StatelessWidget {
  const _LoginCardContent({
    required this.formKey,
    required this.usePhone,
    required this.isLoading,
    required this.phoneController,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onTogglePassword,
  });

  final GlobalKey<FormState> formKey;
  final bool usePhone;
  final bool isLoading;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: _AuthLogo()),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Continue to your VyapaarX workspace.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthTabSelector(
              usePhone: usePhone,
              enabled: !isLoading,
              onChanged: onModeChanged,
            ),
            const SizedBox(height: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: usePhone
                  ? _PhoneLoginFields(controller: phoneController)
                  : _EmailLoginFields(
                      emailController: emailController,
                      passwordController: passwordController,
                      obscurePassword: obscurePassword,
                      onTogglePassword: onTogglePassword,
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthButton(
              label: 'Continue',
              icon: usePhone
                  ? Icons.arrow_forward_rounded
                  : Icons.lock_open_rounded,
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _FirebaseBadge(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'By continuing, you agree to secure Firebase authentication and VyapaarX business access policies.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneLoginFields extends StatelessWidget {
  const _PhoneLoginFields({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('phone-login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInput(
          label: 'Mobile number',
          controller: controller,
          hintText: '98765 43210',
          prefixIcon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            final digits = value?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
            if (digits.length != 10 && digits.length != 12) {
              return 'Enter a valid 10 digit mobile number.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'OTP will be sent with India country code +91.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _EmailLoginFields extends StatelessWidget {
  const _EmailLoginFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('email-login'),
      children: [
        AuthInput(
          label: 'Email address',
          controller: emailController,
          hintText: 'owner@business.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final email = value?.trim() ?? '';
            if (!email.contains('@') || !email.contains('.')) {
              return 'Enter a valid email address.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AuthInput(
          label: 'Password',
          controller: passwordController,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            tooltip: obscurePassword ? 'Show password' : 'Hide password',
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
          validator: (value) {
            if ((value ?? '').length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'VyapaarX',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FirebaseBadge extends StatelessWidget {
  const _FirebaseBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              'Secured by Firebase Auth',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
