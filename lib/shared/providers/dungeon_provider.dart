import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dungeon/domain/models/combat_log_model.dart';
import '../../features/dungeon/domain/models/dungeon_state_model.dart';
import '../../features/dungeon/domain/models/log_type.dart';

/// 던전 생성에 필요한 토큰 비용
const int dungeonTokenCost = 1;

/// 최대 토큰 보유량
const int maxTokens = 10;

/// 토큰 자동 재생 간격 (초)
const int tokenRespawnIntervalSeconds = 3600;

/// 던전 상태 Provider
final dungeonProvider =
    NotifierProvider<DungeonNotifier, DungeonStateModel>(DungeonNotifier.new);

class DungeonNotifier extends Notifier<DungeonStateModel> {
  Timer? _combatTimer;
  Timer? _tokenTimer;
  bool _isGenerating = false;

  @override
  DungeonStateModel build() {
    ref.onDispose(() {
      _combatTimer?.cancel();
      _tokenTimer?.cancel();
    });
    _startTokenTimer();
    return DungeonStateModel.initial();
  }

  /// 토큰 자동 재생 타이머 시작
  void _startTokenTimer() {
    _tokenTimer?.cancel();
    _tokenTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _handleTokenTick();
    });
  }

  void _handleTokenTick() {
    final tokens = state.player.tokens;
    final cooldown = state.tokenCooldownSeconds;

    if (tokens >= maxTokens) {
      if (cooldown != 0) {
        state = state.copyWith(tokenCooldownSeconds: 0);
      }
      return;
    }

    if (cooldown <= 0) {
      state = state.copyWith(
        tokenCooldownSeconds: tokenRespawnIntervalSeconds,
      );
      return;
    }

    if (cooldown <= 1) {
      final newTokens = (tokens + 1).clamp(0, maxTokens);
      final nextCooldown =
          newTokens >= maxTokens ? 0 : tokenRespawnIntervalSeconds;
      state = state.copyWith(
        player: state.player.copyWith(tokens: newTokens),
        tokenCooldownSeconds: nextCooldown,
      );
      return;
    }

    state = state.copyWith(tokenCooldownSeconds: cooldown - 1);
  }

  /// 던전 입장 시작
  Future<void> startDungeon() async {
    if (state.isActive || _isGenerating) return;

    // 토큰 확인
    if (state.player.tokens < dungeonTokenCost) {
      return; // 토큰 부족
    }

    // 초기화
    state = DungeonStateModel.initial().copyWith(isActive: false);
    _isGenerating = true;

    // AI 던전 생성 시뮬레이션 (2-4초)
    await Future.delayed(const Duration(milliseconds: 2500));

    _isGenerating = false;

    // 토큰 소비 & 던전 시작
    final newTokens = state.player.tokens - dungeonTokenCost;
    final newCooldown = newTokens < maxTokens &&
            state.tokenCooldownSeconds == 0
        ? tokenRespawnIntervalSeconds
        : state.tokenCooldownSeconds;
    state = state.copyWith(
      isActive: true,
      isPaused: false,
      player: state.player.copyWith(tokens: newTokens),
      tokenCooldownSeconds: newCooldown,
    );

    // 전투 로그 스트림 시작
    _startCombatStream();
  }

  /// 던전 생성 중 여부
  bool get isGenerating => _isGenerating;

  /// 던전 생성 진행률 (0.0 ~ 1.0)
  double get generationProgress {
    if (!_isGenerating) return state.isActive ? 1.0 : 0.0;
    // 실제로는 타이머로 진행률을 추적해야 하지만, 간단하게 구현
    return 0.5;
  }

  /// 전투 로그 스트림 시작
  void _startCombatStream() {
    _combatTimer?.cancel();

    // 1-2초마다 새 로그 추가
    var logIndex = 0;
    final mockLogs = _generateMockCombatLogs();

    _combatTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!state.isActive || state.isPaused) {
        timer.cancel();
        return;
      }

      if (logIndex < mockLogs.length) {
        final log = mockLogs[logIndex];
        state = state.addLog(log);

        // 플레이어 HP 업데이트 시뮬레이션
        if (log.damage != null && log.type == LogType.combat) {
          final newHp = (state.player.currentHp - (log.damage! ~/ 2))
              .clamp(0, state.player.maxHp);
          state = state.copyWith(
            player: state.player.copyWith(currentHp: newHp),
          );
        }

        logIndex++;
      } else {
        // 다음 층으로
        _nextFloor();
        logIndex = 0;
      }
    });
  }

  /// 다음 층으로 이동
  void _nextFloor() {
    state = state.nextFloor();
    state = state.addLog(
      CombatLogModel.system('${state.floor}층 도달. 새로운 적 생성 중...'),
    );
  }

  /// 일시정지/재개
  void togglePause() {
    if (!state.isActive) return;

    state = state.copyWith(isPaused: !state.isPaused);

    if (!state.isPaused) {
      _startCombatStream();
    } else {
      _combatTimer?.cancel();
    }
  }

  /// 던전 종료
  void stopDungeon() {
    _combatTimer?.cancel();
    _isGenerating = false;
    state = DungeonStateModel.initial();
  }

  /// Mock 전투 로그 생성
  List<CombatLogModel> _generateMockCombatLogs() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return [
      CombatLogModel.system('토큰 $dungeonTokenCost개를 소비해 던전을 생성했습니다.'),
      CombatLogModel.combat('망령이 안개 속을 떠돈다. 피해: 6', damage: 6),
      CombatLogModel.combat('자동 반격: 14 피해. 망령이 약화됨.', damage: 14),
      // 10% 확률로 룬 드롭
      if (random % 10 < 1)
        CombatLogModel.loot('전리품 획득: 룬 x1')
      else
        CombatLogModel.loot('전리품 획득: 룬 조각 x1'),
      CombatLogModel.event('방이 변함! 새 특성: 유령의, 부서지기 쉬운.'),
      CombatLogModel.combat('골렘이 지면을 내려친다. 피해: 9', damage: 9),
      CombatLogModel.combat('치명타! 골렘 격파.', critical: true),
      // 10% 확률로 룬 드롭
      if (random % 10 < 2)
        CombatLogModel.loot('새로운 유물 발견: 구리 등불 + 룬 x1')
      else
        CombatLogModel.loot('새로운 유물 발견: 구리 등불.'),
      CombatLogModel.system('코덱스 업데이트: 27% 완료.'),
    ];
  }
}
