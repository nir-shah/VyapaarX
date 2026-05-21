import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/business_service.dart';
import '../../widgets/widgets.dart';

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
      final updatedBusiness = business.copyWith(
        address: _addressController.text.trim(),
        phone: _normalizeIndianPhone(_phoneController.text),
        alternatePhone: _optionalPhone(_alternatePhoneController.text),
        clearAlternatePhone: _alternatePhoneController.text.trim().isEmpty,
        email: _emailController.text.trim(),
        gstin: _gstinController.text.trim().toUpperCase(),
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
    } on Object catch (_) {
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
    final businessId = context.watch<AuthProvider>().businessId;

    return Scaffold(
      appBar: AppBar(title: const Text('Business settings')),
      body: SafeArea(
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
                    return const AppLoadingIndicator(
                      message: 'Loading settings...',
                    );
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
                    onPickLogo: _pickLogo,
                    onWhatsappChanged: (value) =>
                        setState(() => _whatsappQuickActions = value),
                    onLowStockChanged: (value) =>
                        setState(() => _lowStockAlerts = value),
                    onCompactChanged: (value) =>
                        setState(() => _compactDashboard = value),
                  );
                },
              ),
      ),
      bottomNavigationBar: businessId == null || businessId.isEmpty
          ? null
          : StreamBuilder<BusinessModel?>(
              stream: _businessService.watchBusiness(businessId),
              builder: (context, snapshot) {
                final business = snapshot.data;
                return SafeArea(
                  minimum: AppSpacing.screenPadding,
                  child: AppPrimaryButton(
                    label: 'Save settings',
                    icon: Icons.save_outlined,
                    isLoading: _isSaving,
                    onPressed: business == null || _isSaving
                        ? null
                        : () => _save(business),
                  ),
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
    required this.onPickLogo,
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
  final VoidCallback onPickLogo;
  final ValueChanged<bool> onWhatsappChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<bool> onCompactChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: AppSpacing.responsiveScreenPadding(context),
        children: [
          AppSectionTitle(
            title: business.name,
            subtitle: 'Keep invoice, GST, and contact details up to date.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _LogoCard(
            business: business,
            logoBytes: logoBytes,
            logoName: logoName,
            onPickLogo: onPickLogo,
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Address',
                    controller: addressController,
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'Address'),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    validator: Validators.gstin,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _PreferencesCard(
            whatsappQuickActions: whatsappQuickActions,
            lowStockAlerts: lowStockAlerts,
            compactDashboard: compactDashboard,
            onWhatsappChanged: onWhatsappChanged,
            onLowStockChanged: onLowStockChanged,
            onCompactChanged: onCompactChanged,
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  const _LogoCard({
    required this.business,
    required this.logoBytes,
    required this.logoName,
    required this.onPickLogo,
  });

  final BusinessModel business;
  final Uint8List? logoBytes;
  final String? logoName;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPickLogo,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 72,
                  height: 72,
                  color: AppColors.primaryLight,
                  child: _LogoPreview(
                    logoBytes: logoBytes,
                    logoUrl: business.logoUrl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      logoName ?? 'Update business logo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used on invoices and business profile.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.upload_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.logoBytes, required this.logoUrl});

  final Uint8List? logoBytes;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final selectedLogo = logoBytes;
    if (selectedLogo != null) {
      return Image.memory(selectedLogo, fit: BoxFit.cover);
    }

    final currentLogo = logoUrl;
    if (currentLogo != null && currentLogo.isNotEmpty) {
      return Image.network(
        currentLogo,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) {
          return const Icon(
            Icons.storefront_rounded,
            color: AppColors.primary,
            size: 32,
          );
        },
      );
    }

    return const Icon(
      Icons.add_photo_alternate_outlined,
      color: AppColors.primary,
      size: 32,
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.whatsappQuickActions,
    required this.lowStockAlerts,
    required this.compactDashboard,
    required this.onWhatsappChanged,
    required this.onLowStockChanged,
    required this.onCompactChanged,
  });

  final bool whatsappQuickActions;
  final bool lowStockAlerts;
  final bool compactDashboard;
  final ValueChanged<bool> onWhatsappChanged;
  final ValueChanged<bool> onLowStockChanged;
  final ValueChanged<bool> onCompactChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'App preferences',
              subtitle: 'Business-level preferences saved with this workspace.',
            ),
            const SizedBox(height: AppSpacing.sm),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('WhatsApp quick actions'),
              subtitle: const Text('Show WhatsApp shortcuts on records.'),
              value: whatsappQuickActions,
              onChanged: onWhatsappChanged,
            ),
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Low stock alerts'),
              subtitle: const Text('Highlight products below reorder level.'),
              value: lowStockAlerts,
              onChanged: onLowStockChanged,
            ),
            const Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Compact dashboard'),
              subtitle: const Text('Prefer denser dashboard cards.'),
              value: compactDashboard,
              onChanged: onCompactChanged,
            ),
          ],
        ),
      ),
    );
  }
}
