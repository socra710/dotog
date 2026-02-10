import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_service.dart';

// Dungeon provider는 dungeon_provider.dart에 분리되어 있습니다
export 'dungeon_provider.dart';
export 'auth_provider.dart';
export 'game_data_provider.dart';

final appNameProvider = Provider<String>((ref) => 'DOTOG');

/// FirestoreService 싱글톤 Provider
/// 모든 Firestore 작업에 이 인스턴스를 재사용하여 중복 생성 방지
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
