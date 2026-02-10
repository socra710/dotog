import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/game_data_model.dart';
import 'app_providers.dart';
import 'auth_provider.dart';

/// 게임 데이터 Provider (Firestore에서 실시간 가져오기)
/// FirestoreService를 Provider에서 가져와서 재사용
final gameDataProvider = StreamProvider<GameDataModel?>((ref) {
  final authState = ref.watch(authProvider);
  
  if (!authState.isLoggedIn || authState.user == null) {
    return Stream.value(null);
  }

  final uid = authState.user!.uid;
  final firestoreService = ref.watch(firestoreServiceProvider);
  
  return firestoreService.watchGameData(uid);
});
