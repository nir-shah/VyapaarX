import 'package:flutter/material.dart';

import '../common/loading_skeleton.dart';
import '../common/modern_card.dart';

class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.18),
              child: const Center(
                child: ModernCard(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: 160,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoadingSkeleton(height: 14),
                        SizedBox(height: 12),
                        LoadingSkeleton(width: 110, height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
