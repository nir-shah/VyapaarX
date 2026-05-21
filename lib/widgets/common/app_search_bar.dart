import 'package:flutter/material.dart';

import 'app_input.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return AppInput(
          label: hintText,
          controller: controller,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear ?? controller.clear,
                  icon: const Icon(Icons.close_rounded),
                ),
        );
      },
    );
  }
}
