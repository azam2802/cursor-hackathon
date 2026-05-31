import 'package:flutter/material.dart';
import 'package:summer_activity/core/firebase/firebase_initializer.dart';

import 'screens/home_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const SummerDriftApp());
}

class SummerDriftApp extends StatelessWidget {
  const SummerDriftApp({super.key});

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
      home: const HomeShell(),
    );
  }
}
