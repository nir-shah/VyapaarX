import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/business_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/business_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/business_logo_picker.dart';
import 'widgets/business_setup_stepper.dart';
import 'widgets/business_type_selector.dart';

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

  static const List<String> _stepLabels = ['Basics', 'GST', 'Address', 'Logo'];

  final _stepKeys = List.generate(4, (_) => GlobalKey<FormState>());
  final _businessService = BusinessService();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  String _businessType = _businessTypes.first;
  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoContentType;
  bool _isSaving = false;
  bool _setupComplete = false;
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
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
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

  void _continue() {
    final form = _stepKeys[_currentStep].currentState;
    if (form != null && !form.validate()) return;

    if (_currentStep == _stepLabels.length - 1) {
      _saveBusiness();
      return;
    }

    setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  Future<void> _saveBusiness() async {
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
      final gstin = _gstinController.text.trim().toUpperCase();
      debugPrint('Business setup save started.');
      debugPrint('Current user id: ${session.uid}');
      debugPrint('Generated businessId: $businessId');
      debugPrint(
        'Business form values: name=${_nameController.text.trim()}, '
        'phone=${_normalizeIndianPhone(_phoneController.text)}, '
        'email=${_emailController.text.trim()}, type=$_businessType, '
        'gstin=${gstin.isEmpty ? '(empty)' : gstin}, '
        'address=${_addressController.text.trim()}, '
        'city=${_cityController.text.trim()}, '
        'state=${_stateController.text.trim()}, '
        'pincode=${_pinCodeController.text.trim()}',
      );
      debugPrint(
        _logoBytes == null
            ? 'Business logo upload skipped: no logo selected.'
            : 'Business logo will upload after Firestore profile link. file=$_logoName bytes=${_logoBytes!.length}',
      );
      final business = BusinessModel(
        businessId: businessId,
        ownerUid: session.uid,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinCodeController.text.trim(),
        phone: _normalizeIndianPhone(_phoneController.text),
        email: _emailController.text.trim(),
        businessType: _businessType,
        gstin: gstin,
      );

      debugPrint('Firestore business path: businesses/$businessId');
      debugPrint('Firestore user path: users/${session.uid}');
      final createdBusinessId = await _businessService.createBusiness(
        business: business,
        logoBytes: _logoBytes,
        logoFileName: _logoName,
        logoContentType: _logoContentType,
      );
      debugPrint('Created businessId: $createdBusinessId');

      final reloadedSession = await auth.refreshSession();
      final reloadedBusinessId = reloadedSession?.businessId;
      debugPrint('Reloaded user businessId: $reloadedBusinessId');

      if (reloadedBusinessId == null ||
          reloadedBusinessId.isEmpty ||
          reloadedBusinessId != createdBusinessId ||
          reloadedSession?.hasBusinessProfile != true) {
        debugPrint(
          'Business setup link verification failed. '
          'createdBusinessId=$createdBusinessId, '
          'reloadedBusinessId=$reloadedBusinessId, '
          'hasBusinessProfile=${reloadedSession?.hasBusinessProfile}',
        );
        if (!mounted) return;
        SnackBarHelper.show(
          context,
          message:
              'Business saved, but user profile was not linked. Please try again.',
          type: AppSnackBarType.error,
        );
        return;
      }

      if (!mounted) return;
      setState(() => _setupComplete = true);
      SnackBarHelper.show(
        context,
        message: 'Business profile created successfully.',
        type: AppSnackBarType.success,
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (_) => false);
    } on Object catch (error, stackTrace) {
      debugPrint('Business save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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

  String get _fullAddress {
    final address = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final pinCode = _pinCodeController.text.trim();
    return '$address, $city, $state - $pinCode';
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canNavigate = !_isSaving && !auth.isLoading && !_setupComplete;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business setup'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: canNavigate
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
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.responsiveScreenPadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _setupComplete
                    ? const _SetupSuccessCard()
                    : Column(
                        key: const ValueKey('setup-form'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppSectionHeader(
                            title: 'Create your business profile',
                            subtitle:
                                'Set up the workspace used for invoices, inventory, customers, vendors, and reports.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          BusinessSetupStepper(
                            currentStep: _currentStep,
                            steps: _stepLabels,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _WizardCard(
                            stepNumber: _currentStep + 1,
                            title: _titleForStep(_currentStep),
                            subtitle: _subtitleForStep(_currentStep),
                            child: Form(
                              key: _stepKeys[_currentStep],
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _stepContent(_currentStep),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _setupComplete
          ? null
          : SafeArea(
              minimum: AppSpacing.screenPadding,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Row(
                    children: [
                      if (_currentStep > 0) ...[
                        Expanded(
                          child: AppSecondaryButton(
                            label: 'Back',
                            icon: Icons.arrow_back_rounded,
                            onPressed: canNavigate ? _back : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                      ],
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          label: _currentStep == _stepLabels.length - 1
                              ? 'Save and open dashboard'
                              : 'Continue',
                          icon: _currentStep == _stepLabels.length - 1
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          isLoading: _isSaving || auth.isLoading,
                          onPressed: canNavigate ? _continue : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String _titleForStep(int step) {
    return switch (step) {
      0 => 'Business basics',
      1 => 'GST and type',
      2 => 'Business address',
      _ => 'Logo and confirmation',
    };
  }

  String _subtitleForStep(int step) {
    return switch (step) {
      0 => 'Add the primary identity and contact details.',
      1 => 'Choose your business category and GSTIN.',
      2 => 'This address appears on invoices and records.',
      _ => 'Upload a logo and review your setup.',
    };
  }

  Widget _stepContent(int step) {
    return switch (step) {
      0 => _BasicsStep(
        key: const ValueKey('basics'),
        nameController: _nameController,
        phoneController: _phoneController,
        emailController: _emailController,
      ),
      1 => _TaxStep(
        key: const ValueKey('tax'),
        gstinController: _gstinController,
        businessType: _businessType,
        businessTypes: _businessTypes,
        onBusinessTypeChanged: (value) => setState(() => _businessType = value),
      ),
      2 => _AddressStep(
        key: const ValueKey('address'),
        addressController: _addressController,
        cityController: _cityController,
        stateController: _stateController,
        pinCodeController: _pinCodeController,
      ),
      _ => _ConfirmationStep(
        key: const ValueKey('confirm'),
        logoBytes: _logoBytes,
        logoName: _logoName,
        onPickLogo: _pickLogo,
        businessName: _nameController.text.trim(),
        phone: _normalizeIndianPhone(_phoneController.text),
        email: _emailController.text.trim(),
        businessType: _businessType,
        gstin: _gstinController.text.trim().toUpperCase(),
        address: _fullAddress,
      ),
    };
  }
}

class _WizardCard extends StatelessWidget {
  const _WizardCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int stepNumber;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.xxlRadius,
        boxShadow: AppShadows.soft,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xxlRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '$stepNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppSectionHeader(title: title, subtitle: subtitle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

class _BasicsStep extends StatelessWidget {
  const _BasicsStep({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Business name',
          controller: nameController,
          hintText: 'Shah Traders',
          prefixIcon: Icons.storefront_rounded,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              Validators.requiredText(value, fieldName: 'Business name'),
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
    super.key,
    required this.gstinController,
    required this.businessType,
    required this.businessTypes,
    required this.onBusinessTypeChanged,
  });

  final TextEditingController gstinController;
  final String businessType;
  final List<String> businessTypes;
  final ValueChanged<String> onBusinessTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        BusinessTypeSelector(
          value: businessType,
          types: businessTypes,
          onChanged: onBusinessTypeChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
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
          validator: Validators.optionalGstin,
        ),
      ],
    );
  }
}

class _AddressStep extends StatelessWidget {
  const _AddressStep({
    super.key,
    required this.addressController,
    required this.cityController,
    required this.stateController,
    required this.pinCodeController,
  });

  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController pinCodeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Address',
          controller: addressController,
          hintText: 'Shop no, building, street',
          prefixIcon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          validator: (value) =>
              Validators.requiredText(value, fieldName: 'Address'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'City',
          controller: cityController,
          hintText: 'Surat',
          prefixIcon: Icons.location_city_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              Validators.requiredText(value, fieldName: 'City'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'State',
          controller: stateController,
          hintText: 'Gujarat',
          prefixIcon: Icons.map_outlined,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              Validators.requiredText(value, fieldName: 'State'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Pin code',
          controller: pinCodeController,
          hintText: '395006',
          prefixIcon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          validator: Validators.pinCode,
        ),
      ],
    );
  }
}

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep({
    super.key,
    required this.logoBytes,
    required this.logoName,
    required this.onPickLogo,
    required this.businessName,
    required this.phone,
    required this.email,
    required this.businessType,
    required this.gstin,
    required this.address,
  });

  final Uint8List? logoBytes;
  final String? logoName;
  final VoidCallback onPickLogo;
  final String businessName;
  final String phone;
  final String email;
  final String businessType;
  final String gstin;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BusinessLogoPicker(
          logoBytes: logoBytes,
          logoName: logoName,
          onPickLogo: onPickLogo,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: AppRadius.xlRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _ReviewRow(label: 'Business', value: businessName),
              _ReviewRow(label: 'Phone', value: phone),
              _ReviewRow(label: 'Email', value: email),
              _ReviewRow(label: 'Type', value: businessType),
              _ReviewRow(label: 'GSTIN', value: gstin),
              _ReviewRow(label: 'Address', value: address, isLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupSuccessCard extends StatelessWidget {
  const _SetupSuccessCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('setup-success'),
      decoration: BoxDecoration(
        borderRadius: AppRadius.xxlRadius,
        boxShadow: AppShadows.soft,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xxlRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Business setup complete',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Opening your dashboard now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
