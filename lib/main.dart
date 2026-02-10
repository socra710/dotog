import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 (모든 플랫폼)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Analytics 설정 (웹 제외)
  if (!kIsWeb) {
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  }

  runApp(const ProviderScope(child: DotogApp()));
}
