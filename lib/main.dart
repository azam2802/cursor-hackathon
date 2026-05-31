import 'package:flutter/material.dart';
import 'package:summer_activity/core/auth/auth_service.dart';
import 'package:summer_activity/core/firebase/firebase_initializer.dart';

import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'widgets/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(SummerDriftApp(authService: AuthService()));
}

class SummerDriftApp extends StatelessWidget {
  const SummerDriftApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SummerDrift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.coral,
          primary: AppColors.coral,
          surface: AppColors.cream,
        ),
        textTheme: TextTheme(
          bodyMedium: AppTextStyles.body(),
        ),
      ),
      home: AuthWrapper(authService: authService),
    );
  }
}
