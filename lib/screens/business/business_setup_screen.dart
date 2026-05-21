import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/business_service.dart';
import '../../widgets/widgets.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  static const List<String> _businessTypes = [
    'Retail store',
    'Wholesale',
    'Manufacturing',
    'Services',
    'Restaurant',
    'Pharmacy',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();

  String _businessType = _businessTypes.first;
  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoContentType;
  bool _isSaving = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final session = context.read<AuthProvider>().session;
    _phoneController.text = _displayIndianPhone(session?.phoneNumber);
    _emailController.text = session?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    super.dispose();
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

  Future<void> _saveBusiness() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _currentStep = 0);
      return;
    }

    final auth = context.read<AuthProvider>();
    final session = auth.session;
    if (session == null) {
      SnackBarHelper.show(
        context,
        message: 'Please login again before creating a business.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final businessId = _businessService.createBusinessId();
      final business = BusinessModel(
        businessId: businessId,
        ownerUid: session.uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _normalizeIndianPhone(_phoneController.text),
        alternatePhone: _optionalPhone(_alternatePhoneController.text),
        email: _emailController.text.trim(),
        businessType: _businessType,
        gstin: _gstinController.text.trim().toUpperCase(),
      );

      await _businessService.createBusiness(
        business: business,
        logoBytes: _logoBytes,
        logoFileName: _logoName,
        logoContentType: _logoContentType,
      );
      await auth.refreshSession();

      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to save business profile. Please try again.',
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
    final canSave = !_isSaving && !auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business setup'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: canSave
                ? () async {
                    await context.read<AuthProvider>().signOut();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
                  }
                : null,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.responsiveScreenPadding(context),
            children: [
              const AppSectionTitle(
                title: 'Create your business profile',
                subtitle:
                    'This profile becomes the business workspace for invoices, inventory, customers, and payments.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _StepProgress(currentStep: _currentStep),
              const SizedBox(height: AppSpacing.lg),
              _SetupStepCard(
                step: 0,
                currentStep: _currentStep,
                title: 'Brand',
                subtitle: 'Add the logo and business identity customers see.',
                child: _BrandStep(
                  logoBytes: _logoBytes,
                  logoName: _logoName,
                  nameController: _nameController,
                  onPickLogo: _pickLogo,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SetupStepCard(
                step: 1,
                currentStep: _currentStep,
                title: 'Contact',
                subtitle: 'Keep invoices and WhatsApp actions accurate.',
                child: _ContactStep(
                  addressController: _addressController,
                  phoneController: _phoneController,
                  alternatePhoneController: _alternatePhoneController,
                  emailController: _emailController,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SetupStepCard(
                step: 2,
                currentStep: _currentStep,
                title: 'Tax details',
                subtitle: 'GSTIN and business type for compliant records.',
                child: _TaxStep(
                  gstinController: _gstinController,
                  businessType: _businessType,
                  businessTypes: _businessTypes,
                  onBusinessTypeChanged: (value) {
                    if (value == null) return;
                    setState(() => _businessType = value);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: 'Save and open dashboard',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isSaving || auth.isLoading,
          onPressed: canSave ? _saveBusiness : null,
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final labels = ['Brand', 'Contact', 'GST'];

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= currentStep
                        ? AppColors.primary
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[index],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: index <= currentStep
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (index != labels.length - 1) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _SetupStepCard extends StatelessWidget {
  const _SetupStepCard({
    required this.step,
    required this.currentStep,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int step;
  final int currentStep;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isActive = step == currentStep;

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isActive
                      ? AppColors.primary
                      : AppColors.primaryLight,
                  child: Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSectionTitle(title: title, subtitle: subtitle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _BrandStep extends StatelessWidget {
  const _BrandStep({
    required this.logoBytes,
    required this.logoName,
    required this.nameController,
    required this.onPickLogo,
  });

  final Uint8List? logoBytes;
  final String? logoName;
  final TextEditingController nameController;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPickLogo,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.primaryLight,
                    child: logoBytes == null
                        ? const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: AppColors.primary,
                            size: 30,
                          )
                        : Image.memory(logoBytes!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logoName ?? 'Upload business logo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG or JPG works best.',
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
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Business name',
          controller: nameController,
          hintText: 'Shah Traders',
          prefixIcon: Icons.storefront_rounded,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              Validators.requiredText(value, fieldName: 'Business name'),
        ),
      ],
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.addressController,
    required this.phoneController,
    required this.alternatePhoneController,
    required this.emailController,
  });

  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController alternatePhoneController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Address',
          controller: addressController,
          hintText: 'Shop no, street, city, state',
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
          hintText: '98765 43210',
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
          hintText: 'Optional',
          prefixIcon: Icons.call_outlined,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 10,
          validator: (value) => Validators.indianPhone(value, optional: true),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Email',
          controller: emailController,
          hintText: 'billing@business.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.email,
        ),
      ],
    );
  }
}

class _TaxStep extends StatelessWidget {
  const _TaxStep({
    required this.gstinController,
    required this.businessType,
    required this.businessTypes,
    required this.onBusinessTypeChanged,
  });

  final TextEditingController gstinController;
  final String businessType;
  final List<String> businessTypes;
  final ValueChanged<String?> onBusinessTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: businessType,
          items: businessTypes
              .map(
                (type) =>
                    DropdownMenuItem<String>(value: type, child: Text(type)),
              )
              .toList(),
          onChanged: onBusinessTypeChanged,
          decoration: const InputDecoration(
            labelText: 'Business type',
            prefixIcon: Icon(Icons.category_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'GSTIN',
          controller: gstinController,
          hintText: '24ABCDE1234F1Z5',
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
    );
  }
}
