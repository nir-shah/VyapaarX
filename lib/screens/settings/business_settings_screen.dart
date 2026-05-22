import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/business_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/logo_upload_card.dart';
import 'widgets/settings_section_card.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key});

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BusinessService _businessService = BusinessService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _alternatePhoneController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();

  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoContentType;
  String? _loadedBusinessId;
  bool _isSaving = false;
  bool _whatsappQuickActions = true;
  bool _lowStockAlerts = true;
  bool _compactDashboard = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  void _fillForm(BusinessModel business) {
    if (_loadedBusinessId == business.businessId) return;

    _loadedBusinessId = business.businessId;
    _addressController.text = business.address;
    _phoneController.text = _displayIndianPhone(business.phone);
    _alternatePhoneController.text = _displayIndianPhone(
      business.alternatePhone,
    );
    _emailController.text = business.email;
    _gstinController.text = business.gstin;
    _whatsappQuickActions = _preference(
      business,
      'whatsappQuickActions',
      fallback: true,
    );
    _lowStockAlerts = _preference(business, 'lowStockAlerts', fallback: true);
    _compactDashboard = _preference(business, 'compactDashboard');
  }

  bool _preference(
    BusinessModel business,
    String key, {
    bool fallback = false,
  }) {
    return business.preferences[key] ?? fallback;
  }

  Future<void> _pickLogo() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 82,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _logoBytes = bytes;
      _logoName = image.name;
      _logoContentType = image.mimeType;
    });
  }

  Future<void> _save(BusinessModel business) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final gstin = _gstinController.text.trim().toUpperCase();
      debugPrint('Business settings save started.');
      debugPrint('Current businessId: ${business.businessId}');
      debugPrint(
        'Business settings values: phone=${_normalizeIndianPhone(_phoneController.text)}, '
        'email=${_emailController.text.trim()}, gstin=${gstin.isEmpty ? '(empty)' : gstin}, '
        'address=${_addressController.text.trim()}',
      );
      debugPrint(
        _logoBytes == null
            ? 'Business settings logo upload skipped: no logo selected.'
            : 'Business settings logo will upload. file=$_logoName bytes=${_logoBytes!.length}',
      );
      final updatedBusiness = business.copyWith(
        address: _addressController.text.trim(),
        phone: _normalizeIndianPhone(_phoneController.text),
        alternatePhone: _optionalPhone(_alternatePhoneController.text),
        clearAlternatePhone: _alternatePhoneController.text.trim().isEmpty,
        email: _emailController.text.trim(),
        gstin: gstin,
        preferences: {
          ...business.preferences,
          'whatsappQuickActions': _whatsappQuickActions,
          'lowStockAlerts': _lowStockAlerts,
          'compactDashboard': _compactDashboard,
        },
      );

      await _businessService.updateBusinessSettings(
        business: updatedBusiness,
        logoBytes: _logoBytes,
        logoFileName: _logoName,
        logoContentType: _logoContentType,
      );

      if (!mounted) return;
      setState(() {
        _logoBytes = null;
        _logoName = null;
        _logoContentType = null;
        _loadedBusinessId = null;
      });
      SnackBarHelper.show(
        context,
        message: 'Business settings updated.',
        type: AppSnackBarType.success,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Business settings save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to update business settings. Please try again.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _displayIndianPhone(String? value) {
    if (value == null || value.isEmpty) return '';
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return digits.substring(2);
    }
    return digits;
  }

  String _normalizeIndianPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) return '+$digits';
    return '+91$digits';
  }

  String? _optionalPhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return _normalizeIndianPhone(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.businessId;

    return AppResponsiveShell(
      title: 'Settings',
      currentRoute: AppRoutes.settings,
      currentRole: auth.role,
      child: businessId == null || businessId.isEmpty
          ? const AppEmptyState(
              title: 'Business profile needed',
              message: 'Complete business setup before changing settings.',
              icon: Icons.settings_outlined,
            )
          : StreamBuilder<BusinessModel?>(
              stream: _businessService.watchBusiness(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const _SettingsSkeleton();
                }

                final business = snapshot.data;
                if (snapshot.hasError || business == null) {
                  return const AppEmptyState(
                    title: 'Settings unavailable',
                    message: 'Unable to load your business profile.',
                    icon: Icons.error_outline_rounded,
                  );
                }

                _fillForm(business);
                return _BusinessSettingsForm(
                  formKey: _formKey,
                  business: business,
                  logoBytes: _logoBytes,
                  logoName: _logoName,
                  addressController: _addressController,
                  phoneController: _phoneController,
                  alternatePhoneController: _alternatePhoneController,
                  emailController: _emailController,
                  gstinController: _gstinController,
                  whatsappQuickActions: _whatsappQuickActions,
                  lowStockAlerts: _lowStockAlerts,
                  compactDashboard: _compactDashboard,
                  isSaving: _isSaving,
                  onPickLogo: _pickLogo,
                  onSave: () => _save(business),
                  onWhatsappChanged: (value) =>
                      setState(() => _whatsappQuickActions = value),
                  onLowStockChanged: (value) =>
                      setState(() => _lowStockAlerts = value),
                  onCompactChanged: (value) =>
                      setState(() => _compactDashboard = value),
                );
              },
            ),
    );
  }
}

class _BusinessSettingsForm extends StatelessWidget {
  const _BusinessSettingsForm({
    required this.formKey,
    required this.business,
    required this.logoBytes,
    required this.logoName,
    required this.addressController,
    required this.phoneController,
    required this.alternatePhoneController,
    required this.emailController,
    required this.gstinController,
    required this.whatsappQuickActions,
    required this.lowStockAlerts,
    required this.compactDashboard,
    required this.isSaving,
    required this.onPickLogo,
    required this.onSave,
    required this.onWhatsappChanged,
    required this.onLowStockChanged,
    required this.onCompactChanged,
  });

  final GlobalKey<FormState> formKey;
  final BusinessModel business;
  final Uint8List? logoBytes;
  final String? logoName;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController alternatePhoneController;
  final TextEditingController emailController;
  final TextEditingController gstinController;
  final bool whatsappQuickActions;
  final bool lowStockAlerts;
  final bool compactDashboard;
  final bool isSaving;
  final VoidCallback onPickLogo;
  final VoidCallback onSave;
  final ValueChanged<bool> onWhatsappChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<bool> onCompactChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              _BusinessProfileCard(business: business),
              const SizedBox(height: AppSpacing.lg),
              const _AppearanceCard(),
              const SizedBox(height: AppSpacing.lg),
              LogoUploadCard(
                businessName: business.name,
                logoBytes: logoBytes,
                logoUrl: business.logoUrl,
                logoName: logoName,
                onPickLogo: onPickLogo,
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSectionCard(
                title: 'GST details',
                subtitle: 'Used for GST invoices and business documents.',
                icon: Icons.badge_outlined,
                children: [
                  AppTextField(
                    label: 'GSTIN',
                    controller: gstinController,
                    prefixIcon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 15,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
                    validator: Validators.optionalGstin,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSectionCard(
                title: 'Address',
                subtitle: 'Printed on invoices and shared with customers.',
                icon: Icons.location_on_outlined,
                children: [
                  AppTextField(
                    label: 'Business address',
                    controller: addressController,
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    validator: _validateAddress,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSectionCard(
                title: 'Contact',
                subtitle: 'Primary phone and email used across invoices.',
                icon: Icons.contact_phone_outlined,
                children: [
                  AppTextField(
                    label: 'Phone',
                    controller: phoneController,
                    prefixIcon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    validator: Validators.indianPhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Alternate phone',
                    controller: alternatePhoneController,
                    prefixIcon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    validator: (value) =>
                        Validators.indianPhone(value, optional: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Email',
                    controller: emailController,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    validator: Validators.email,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SettingsSectionCard(
                title: 'App preferences',
                subtitle: 'Workspace-level preferences for daily operations.',
                icon: Icons.tune_rounded,
                children: [
                  _PreferenceSwitch(
                    title: 'WhatsApp quick actions',
                    subtitle: 'Show WhatsApp shortcuts on records.',
                    icon: Icons.chat_outlined,
                    value: whatsappQuickActions,
                    onChanged: onWhatsappChanged,
                  ),
                  const Divider(height: AppSpacing.xl),
                  _PreferenceSwitch(
                    title: 'Low stock alerts',
                    subtitle: 'Highlight products below reorder level.',
                    icon: Icons.notifications_active_outlined,
                    value: lowStockAlerts,
                    onChanged: onLowStockChanged,
                  ),
                  const Divider(height: AppSpacing.xl),
                  _PreferenceSwitch(
                    title: 'Compact dashboard',
                    subtitle: 'Prefer denser dashboard cards.',
                    icon: Icons.dashboard_customize_outlined,
                    value: compactDashboard,
                    onChanged: onCompactChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _StickySaveBar(isSaving: isSaving, onSave: onSave),
        ),
      ],
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    return SettingsSectionCard(
      title: 'Appearance',
      subtitle: 'Selected Theme: ${tokens.name}',
      icon: Icons.palette_outlined,
      trailing: TextButton.icon(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.themeSelection),
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Change Theme'),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: tokens.cardGradient),
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: tokens.textPrimary.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: tokens.buttonGradient),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tokens.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      tokens.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BusinessProfileCard extends StatelessWidget {
  const _BusinessProfileCard({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tokens.buttonGradient),
        borderRadius: AppRadius.xlRadius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final stats = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ProfilePill(
                label: business.businessType.isEmpty
                    ? 'Business'
                    : business.businessType,
                icon: Icons.category_outlined,
              ),
              _ProfilePill(label: 'Owner workspace', icon: Icons.verified_user),
            ],
          );

          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              if (isWide)
                Expanded(child: _ProfileCopy(business: business))
              else
                _ProfileCopy(business: business),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.md,
              ),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _ProfileCopy extends StatelessWidget {
  const _ProfileCopy({required this.business});

  final BusinessModel business;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          business.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Manage invoice identity, contact details, GST data, and app preferences.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.themeTokens;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: tokens.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({required this.isSaving, required this.onSave});

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0),
            AppColors.background,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: ModernCard(
          showShadow: true,
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text('Changes are saved to your business profile.'),
                ),
              ),
              SizedBox(
                width: 180,
                child: AppPrimaryButton(
                  label: 'Save',
                  icon: Icons.save_outlined,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : onSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSkeleton extends StatelessWidget {
  const _SettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: const [
        LoadingSkeleton(height: 132),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 132),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 154),
        SizedBox(height: AppSpacing.lg),
        LoadingSkeleton(height: 220),
      ],
    );
  }
}

String? _validateAddress(String? value) {
  final address = (value ?? '').trim();
  if (address.isEmpty) return 'Address is required.';
  if (address.length < 8) return 'Enter a complete business address.';
  return null;
}
