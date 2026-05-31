import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';
import '../theme/app_colors.dart';

/// Routes between auth UI and the main app based on Firebase auth state.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return HomeShell(authService: authService);
        }

        return AuthScreen(authService: authService);
      },
    );
  }
}
