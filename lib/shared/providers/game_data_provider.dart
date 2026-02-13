import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/game_data_model.dart';
import '../../shared/models/player_model.dart';
import 'app_providers.dart';

/// 게임 데이터 Provider (Firestore에서 실시간 스트림)
/// 모든 게임 데이터의 단일 진실 공급원(SSOT)
final gameDataProvider = StreamProvider<GameDataModel?>((ref) {
  final authState = ref.watch(authProvider);

  if (!authState.isLoggedIn || authState.user == null) {
    return Stream.value(null);
  }

  final uid = authState.user!.uid;
  final firestoreService = ref.watch(firestoreServiceProvider);

  return firestoreService.watchGameData(uid);
});

/// 코덱스 보너스 반영된 플레이어 상태
/// gameDataProvider를 select로 구독해서 필요한 부분만 추출 (리빌드 최소화)
final effectivePlayerProvider = Provider<AsyncValue<PlayerModel?>>((ref) {
  return ref.watch(
    gameDataProvider.select(
      (value) => value.whenData(
        (data) => data?.playerWithCodexBonus,
      ),
    ),
  );
});
