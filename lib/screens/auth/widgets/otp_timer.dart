import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../widgets/widgets.dart';

class OtpTimer extends StatefulWidget {
  const OtpTimer({
    super.key,
    required this.onResend,
    this.seconds = 30,
    this.enabled = true,
  });

  final Future<void> Function() onResend;
  final int seconds;
  final bool enabled;

  @override
  State<OtpTimer> createState() => _OtpTimerState();
}

class _OtpTimerState extends State<OtpTimer> {
  Timer? _timer;
  late int _remaining;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining <= 1) {
        timer.cancel();
        setState(() => _remaining = 0);
        return;
      }
      setState(() => _remaining--);
    });
  }

  Future<void> _resend() async {
    if (!widget.enabled || _remaining > 0 || _isResending) return;
    setState(() => _isResending = true);
    await widget.onResend();
    if (!mounted) return;
    setState(() {
      _isResending = false;
      _remaining = widget.seconds;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining > 0) {
      return Text(
        'Resend code in 0:${_remaining.toString().padLeft(2, '0')}',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    return TextButton.icon(
      onPressed: widget.enabled && !_isResending ? _resend : null,
      icon: _isResending
          ? const SizedBox(
              width: 22,
              child: LoadingSkeleton(height: 8, radius: AppRadius.pill),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(_isResending ? 'Sending OTP' : 'Resend OTP'),
    );
  }
}
