import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/widgets.dart';

class LogoUploadCard extends StatelessWidget {
  const LogoUploadCard({
    super.key,
    required this.businessName,
    required this.logoBytes,
    required this.logoUrl,
    required this.onPickLogo,
    this.logoName,
  });

  final String businessName;
  final Uint8List? logoBytes;
  final String? logoUrl;
  final String? logoName;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      showShadow: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: isWide
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.xlRadius,
                child: Container(
                  width: 96,
                  height: 96,
                  color: AppColors.primaryLight,
                  child: _LogoPreview(logoBytes: logoBytes, logoUrl: logoUrl),
                ),
              ),
              SizedBox(
                width: isWide ? AppSpacing.lg : 0,
                height: isWide ? 0 : AppSpacing.md,
              ),
              if (isWide)
                Expanded(
                  child: _LogoCopy(
                    businessName: businessName,
                    logoName: logoName,
                  ),
                )
              else
                _LogoCopy(businessName: businessName, logoName: logoName),
              SizedBox(
                width: isWide ? AppSpacing.md : 0,
                height: isWide ? 0 : AppSpacing.md,
              ),
              AppSecondaryButton(
                label: 'Upload',
                icon: Icons.upload_rounded,
                fullWidth: !isWide,
                onPressed: onPickLogo,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LogoCopy extends StatelessWidget {
  const _LogoCopy({required this.businessName, required this.logoName});

  final String businessName;
  final String? logoName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business logo', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          logoName == null
              ? 'Used on invoices, PDF exports, and business profile.'
              : 'Selected: $logoName',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppStatusChip(
          label: businessName.isEmpty ? 'VyapaarX' : businessName,
          type: AppStatusType.info,
          icon: Icons.storefront_outlined,
        ),
      ],
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
        errorBuilder: (_, _, _) => const _FallbackLogo(),
      );
    }

    return const _FallbackLogo();
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.add_photo_alternate_outlined,
      color: AppColors.primary,
      size: 34,
    );
  }
}
