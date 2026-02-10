import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class DotogApp extends StatelessWidget {
  const DotogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
