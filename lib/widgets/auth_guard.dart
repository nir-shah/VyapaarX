import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../providers/auth_provider.dart';
import 'loading/app_loading_indicator.dart';

class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.checking || auth.isLoading) {
      return const Scaffold(
        body: AppLoadingIndicator(message: 'Checking your session...'),
      );
    }

    if (auth.status == AuthStatus.unauthenticated) {
      _redirect(context, AppRoutes.login);
      return const Scaffold(body: SizedBox.shrink());
    }

    if (auth.status == AuthStatus.disabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account disabled')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Your account has been disabled. Please contact the business owner or admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (auth.status == AuthStatus.needsBusinessSetup) {
      final currentRoute = ModalRoute.of(context)?.settings.name;
      if (currentRoute != AppRoutes.businessSetup) {
        _redirect(context, AppRoutes.businessSetup);
        return const Scaffold(body: SizedBox.shrink());
      }
    }

    return child;
  }

  void _redirect(BuildContext context, String routeName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
    });
  }
}
