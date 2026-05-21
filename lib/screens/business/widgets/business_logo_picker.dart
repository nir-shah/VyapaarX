import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class BusinessLogoPicker extends StatelessWidget {
  const BusinessLogoPicker({
    super.key,
    required this.logoBytes,
    required this.logoName,
    required this.onPickLogo,
  });

  final Uint8List? logoBytes;
  final String? logoName;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickLogo,
      borderRadius: AppRadius.xlRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.xlRadius,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: AppRadius.xlRadius,
              child: Container(
                width: 96,
                height: 96,
                color: AppColors.primaryLight,
                child: logoBytes == null
                    ? const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 38,
                      )
                    : Image.memory(logoBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              logoName ?? 'Upload business logo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PNG or JPG works best. You can skip this for now.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
