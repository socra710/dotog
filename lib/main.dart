import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // FCM 초기화
  if (!kIsWeb) {
    // 모바일: 포그라운드 알림 설정 (iOS)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // 알림 권한 요청 (웹 + 모바일)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const ProviderScope(child: DotogApp()));
}
