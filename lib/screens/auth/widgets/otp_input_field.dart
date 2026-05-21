import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    this.length = 6,
    this.enabled = true,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _syncFromParent();
  }

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncFromParent();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _syncFromParent() {
    final digits = _digitsOnly(widget.controller.text);
    for (var index = 0; index < widget.length; index++) {
      _controllers[index].text = index < digits.length ? digits[index] : '';
    }
  }

  void _syncToParent() {
    final value = _controllers.map((controller) => controller.text).join();
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '').take(widget.length);
  }

  void _handleChanged(String value, int index) {
    final digits = _digitsOnly(value);
    if (digits.length > 1) {
      _applyPastedCode(digits, startIndex: index);
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.collapsed(
      offset: digits.length,
    );
    _syncToParent();

    if (digits.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _applyPastedCode(String digits, {int startIndex = 0}) {
    var cursor = startIndex;
    for (final digit in digits.characters) {
      if (cursor >= widget.length) break;
      _controllers[cursor].text = digit;
      cursor++;
    }
    _syncToParent();

    final nextIndex = cursor >= widget.length ? widget.length - 1 : cursor;
    _focusNodes[nextIndex].requestFocus();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event, int index) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _syncToParent();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 360 ? AppSpacing.xs : AppSpacing.sm;
        final boxSize =
            ((constraints.maxWidth - gap * (widget.length - 1)) / widget.length)
                .clamp(42.0, 56.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < widget.length; index++) ...[
              SizedBox.square(
                dimension: boxSize,
                child: Focus(
                  onKeyEvent: (_, event) => _handleKeyEvent(event, index),
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: index == widget.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    textAlign: TextAlign.center,
                    maxLength: widget.length,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: _border(AppColors.border),
                      enabledBorder: _border(AppColors.border),
                      focusedBorder: _border(AppColors.primary, width: 1.6),
                    ),
                    onChanged: (value) => _handleChanged(value, index),
                    onTap: () {
                      _controllers[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _controllers[index].text.length,
                      );
                    },
                  ),
                ),
              ),
              if (index != widget.length - 1) SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

extension on String {
  String take(int count) {
    if (length <= count) return this;
    return substring(0, count);
  }
}
