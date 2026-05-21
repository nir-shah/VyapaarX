import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_input.dart';

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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1FBF7), Color(0xFFEAF2FF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final horizontalPadding = isDesktop
                  ? AppSpacing.xxxl
                  : size.width < 380
                  ? AppSpacing.md
                  : AppSpacing.xl;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isDesktop ? AppSpacing.xxl : AppSpacing.xl,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: isDesktop
                        ? Row(
                            children: [
                              const Expanded(child: _BrandPanel()),
                              const SizedBox(width: 56),
                              SizedBox(
                                width: 450,
                                child: _LoginPanel(
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
                              ),
                            ],
                          )
                        : _MobileLayout(
                            child: _LoginPanel(
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
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CompactBrandHeader(),
        const SizedBox(height: AppSpacing.xl),
        child,
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in to continue managing billing, stock, and business operations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _AuthTabs(
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
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
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
              label: usePhone ? 'Send secure OTP' : 'Login securely',
              icon: usePhone ? Icons.sms_outlined : Icons.lock_open_rounded,
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _TrustRow(),
          ],
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.usePhone,
    required this.enabled,
    required this.onChanged,
  });

  final bool usePhone;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeOutCubic,
            alignment: usePhone ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _AuthTabButton(
                label: 'Phone',
                icon: Icons.phone_android_rounded,
                selected: usePhone,
                enabled: enabled,
                onTap: () => onChanged(true),
              ),
              _AuthTabButton(
                label: 'Email',
                icon: Icons.mail_outline_rounded,
                selected: !usePhone,
                enabled: enabled,
                onTap: () => onChanged(false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
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
          style: Theme.of(context).textTheme.bodyMedium,
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

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'Protected by Firebase Auth and business-scoped access.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _CompactBrandHeader extends StatelessWidget {
  const _CompactBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _BrandMark(size: 64),
        const SizedBox(height: AppSpacing.md),
        Text(
          'VyapaarX',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Smart ERP for growing Indian businesses',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 660),
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF075E54), Color(0xFF0E7C66), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -38,
            child: _DecorativeCircle(
              size: 180,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: -36,
            bottom: -52,
            child: _DecorativeCircle(
              size: 220,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(size: 70, light: true),
              const SizedBox(height: 42),
              Text(
                'Run billing, stock, GST, and teams from one calm workspace.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'VyapaarX brings invoices, inventory, customers, vendors, reports, and ERP controls into a premium mobile-first dashboard.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 36),
              const _FeatureList(),
              const Spacer(),
              const _IllustrationPanel(),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: light ? Colors.white : AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: light ? AppColors.primary : Colors.white,
            size: size * 0.52,
          ),
        ),
        if (light) ...[
          const SizedBox(width: AppSpacing.md),
          Text(
            'VyapaarX',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    final features = [
      'GST-ready invoices and WhatsApp sharing',
      'Real-time stock, purchase, and vendor payable',
      'Role-based access for sales, accounts, and warehouse',
    ];

    return Column(
      children: [
        for (final feature in features) ...[
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: _MetricPill(
                  label: 'Today sales',
                  value: 'Rs 48.2k',
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Container(
                  height: 118,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 84,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: 94,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
