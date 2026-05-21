import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/utils/app_formatters.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/validators.dart';
import '../../models/vendor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/vendor_service.dart';
import '../../widgets/widgets.dart';

class AddEditVendorScreen extends StatefulWidget {
  const AddEditVendorScreen({super.key, this.vendor});

  final VendorModel? vendor;

  @override
  State<AddEditVendorScreen> createState() => _AddEditVendorScreenState();
}

class _AddEditVendorScreenState extends State<AddEditVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();

  final _nameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _villageCityController = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _openingPayableController = TextEditingController(text: '0');
  final _outstandingPayableController = TextEditingController(text: '0');

  bool _isSaving = false;

  bool get _isEditing => widget.vendor != null;

  @override
  void initState() {
    super.initState();
    final vendor = widget.vendor;
    if (vendor == null) return;

    _nameController.text = vendor.name;
    _addressLine1Controller.text = vendor.addressLine1;
    _villageCityController.text = vendor.villageCity;
    _talukaController.text = vendor.taluka;
    _districtController.text = vendor.district;
    _stateController.text = vendor.state;
    _pinCodeController.text = vendor.pinCode;
    _phoneController.text = _phoneForInput(vendor.phone);
    _alternatePhoneController.text = _phoneForInput(vendor.alternatePhone);
    _emailController.text = vendor.email ?? '';
    _gstinController.text = vendor.gstin ?? '';
    _openingPayableController.text = vendor.openingPayable.toStringAsFixed(0);
    _outstandingPayableController.text = vendor.outstandingPayable
        .toStringAsFixed(0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressLine1Controller.dispose();
    _villageCityController.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _openingPayableController.dispose();
    _outstandingPayableController.dispose();
    super.dispose();
  }

  Future<void> _saveVendor() async {
    if (!_formKey.currentState!.validate()) return;

    final businessId =
        widget.vendor?.businessId ?? context.read<AuthProvider>().businessId;
    if (businessId == null || businessId.isEmpty) {
      SnackBarHelper.show(
        context,
        message: 'Business profile is required before adding vendors.',
        type: AppSnackBarType.error,
      );
      return;
    }

    setState(() => _isSaving = true);

    final vendor = VendorModel(
      id: widget.vendor?.id ?? '',
      businessId: businessId,
      name: _nameController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      villageCity: _villageCityController.text.trim(),
      taluka: _talukaController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      phone: AppFormatters.normalizeIndianPhone(_phoneController.text),
      alternatePhone: AppFormatters.optionalIndianPhone(
        _alternatePhoneController.text,
      ),
      email: _optionalText(_emailController.text),
      gstin: _optionalText(_gstinController.text)?.toUpperCase(),
      openingPayable: double.parse(_openingPayableController.text.trim()),
      outstandingPayable: double.parse(
        _outstandingPayableController.text.trim(),
      ),
      createdAt: widget.vendor?.createdAt,
      updatedAt: widget.vendor?.updatedAt,
    );

    try {
      if (_isEditing) {
        await _vendorService.updateVendor(vendor);
      } else {
        await _vendorService.addVendor(vendor);
      }

      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: _isEditing ? 'Vendor updated.' : 'Vendor added.',
        type: AppSnackBarType.success,
      );
      Navigator.of(context).pop();
    } on Object catch (_) {
      if (!mounted) return;
      SnackBarHelper.show(
        context,
        message: 'Unable to save vendor.',
        type: AppSnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _phoneForInput(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      return digits.substring(2);
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit vendor' : 'Add vendor')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.responsiveScreenPadding(context),
            children: [
              AppSectionTitle(
                title: _isEditing ? 'Vendor details' : 'New vendor',
                subtitle:
                    'Vendor records are saved only inside the active business.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _VendorFormSection(
                title: 'Basic information',
                children: [
                  AppTextField(
                    label: 'Name',
                    controller: _nameController,
                    prefixIcon: Icons.local_shipping_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'Name'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Phone',
                    controller: _phoneController,
                    prefixIcon: Icons.phone_iphone_rounded,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 10,
                    validator: Validators.indianPhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Alternate phone',
                    controller: _alternatePhoneController,
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
                    controller: _emailController,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.optionalEmail,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _VendorFormSection(
                title: 'Address',
                children: [
                  AppTextField(
                    label: 'Address line 1',
                    controller: _addressLine1Controller,
                    prefixIcon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) => Validators.requiredText(
                      value,
                      fieldName: 'Address line 1',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Village / City',
                    controller: _villageCityController,
                    prefixIcon: Icons.location_city_outlined,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => Validators.requiredText(
                      value,
                      fieldName: 'Village / City',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Taluka',
                    controller: _talukaController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'Taluka'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'District',
                    controller: _districtController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'District'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'State',
                    controller: _stateController,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) =>
                        Validators.requiredText(value, fieldName: 'State'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Pin code',
                    controller: _pinCodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    validator: Validators.pinCode,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _VendorFormSection(
                title: 'Tax and payable',
                children: [
                  AppTextField(
                    label: 'GSTIN',
                    controller: _gstinController,
                    hintText: 'Optional',
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
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Opening payable',
                    controller: _openingPayableController,
                    prefixIcon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                    validator: Validators.amount,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Outstanding payable',
                    controller: _outstandingPayableController,
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    validator: Validators.amount,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: AppSpacing.screenPadding,
        child: AppPrimaryButton(
          label: _isEditing ? 'Update vendor' : 'Save vendor',
          icon: Icons.check_circle_outline_rounded,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _saveVendor,
        ),
      ),
    );
  }
}

class _VendorFormSection extends StatelessWidget {
  const _VendorFormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(title: title),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}
