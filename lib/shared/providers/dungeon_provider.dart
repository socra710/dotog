import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dungeon/domain/models/combat_log_model.dart';
import '../../features/dungeon/domain/models/dungeon_state_model.dart';
import '../../features/dungeon/domain/models/log_type.dart';
import '../models/codex_bonus_model.dart';
import '../models/item_model.dart';
import '../models/rarity.dart';
import 'app_providers.dart';

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

    // 초기화 + 코덱스 보너스 적용
    final bonusState = ref.read(gameDataProvider).value?.codexBonusState ??
        CodexBonusState.initial();
    final bonusPlayer = state.player.applyCodexBonus(bonusState).copyWith(
          currentHp: state.player.maxHp,
        );
    state = DungeonStateModel.initial()
        .copyWith(isActive: false, player: bonusPlayer);
    _isGenerating = true;

    // AI 던전 생성 시뮬레이션 (2-4초)
    // 이 시간 동안 새로운 아이템을 Firestore에 추가
    await Future.delayed(const Duration(milliseconds: 500));

    // AI 아이템 생성 (50% 확률)
    await _generateAndAddRandomItem();

    await Future.delayed(const Duration(milliseconds: 2000));

    _isGenerating = false;

    // 토큰 소비 & 던전 시작
    final newTokens = state.player.tokens - dungeonTokenCost;
    final newCooldown = newTokens < maxTokens && state.tokenCooldownSeconds == 0
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

  /// AI 아이템 생성 및 Firestore 추가
  ///
  /// 등급별 확률:
  /// - common: 50%
  /// - rare: 30%
  /// - epic: 15%
  /// - legendary: 5%
  Future<void> _generateAndAddRandomItem() async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final random = Random();

      // 50% 확률로 아이템 생성
      if (random.nextDouble() > 0.5) {
        return;
      }

      // 등급 결정 (확률 기반)
      final rarity = _selectRandomRarity(random);

      // 랜덤 아이템 생성
      final item = _createRandomItem(rarity, random);

      // Firestore에 추가 (중복 체크)
      await firestoreService.addItemIfNotExists(item);
    } catch (e) {
      // 에러 무시 (던전 생성은 계속 진행)
    }
  }

  /// 등급별 확률로 랜덤 선택
  Rarity _selectRandomRarity(Random random) {
    final roll = random.nextDouble() * 100;
    if (roll < 50) return Rarity.common; // 0-50: 50%
    if (roll < 80) return Rarity.rare; // 50-80: 30%
    if (roll < 95) return Rarity.epic; // 80-95: 15%
    return Rarity.legendary; // 95-100: 5%
  }

  /// 랜덤 아이템 생성
  ItemModel _createRandomItem(Rarity rarity, Random random) {
    final adjectives = [
      '고대의',
      '잊혀진',
      '어둠의',
      '빛나는',
      '부서진',
      '저주받은',
      '축복받은',
      '불타는',
      '얼어붙은',
      '번개의',
      '그림자',
      '신성한',
      '악마의',
      '영원한',
      '순간의',
      '떠도는',
      '침묵의',
      '울부짖는',
      '잠든',
      '깨어난',
    ];

    final nouns = [
      '검',
      '방패',
      '등불',
      '반지',
      '목걸이',
      '투구',
      '망토',
      '갑옷',
      '장화',
      '장갑',
      '지팡이',
      '책',
      '수정',
      '유물',
      '인장',
      '부적',
      '주사위',
      '나침반',
      '모래시계',
      '거울',
    ];

    final descriptions = [
      '오래된 힘이 깃들어 있다',
      '미약하게 빛을 발한다',
      '차가운 기운이 느껴진다',
      '따뜻한 온기가 감돈다',
      '알 수 없는 문자가 새겨져 있다',
      '마법의 기운이 흐른다',
      '시간의 흔적이 남아있다',
      '어딘가 익숙한 느낌이다',
      '강력한 힘이 봉인되어 있다',
      '부서질 것 같지만 견고하다',
    ];

    final id =
        'ai_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(9999)}';
    final name =
        '${adjectives[random.nextInt(adjectives.length)]} ${nouns[random.nextInt(nouns.length)]}';
    final description = descriptions[random.nextInt(descriptions.length)];

    // 등급에 따른 스탯 범위
    final statRange = switch (rarity) {
      Rarity.common => (min: 0, max: 2),
      Rarity.rare => (min: 1, max: 4),
      Rarity.epic => (min: 3, max: 7),
      Rarity.legendary => (min: 5, max: 12),
    };

    // 랜덤 스탯 생성 (1-2개의 스탯만 보너스)
    final statCount = random.nextInt(2) + 1;
    var attackBonus = 0;
    var defenseBonus = 0;
    var hpBonus = 0;
    var luckBonus = 0;

    for (var i = 0; i < statCount; i++) {
      final statType = random.nextInt(4);
      final value =
          statRange.min + random.nextInt(statRange.max - statRange.min + 1);

      switch (statType) {
        case 0:
          attackBonus += value;
        case 1:
          defenseBonus += value;
        case 2:
          hpBonus += value;
        case 3:
          luckBonus += value;
      }
    }

    return ItemModel(
      id: id,
      name: name,
      description: description,
      rarity: rarity,
      attackBonus: attackBonus,
      defenseBonus: defenseBonus,
      hpBonus: hpBonus,
      luckBonus: luckBonus,
    );
  }
}
