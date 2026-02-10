import '../domain/models/combat_log_model.dart';
import '../domain/models/log_type.dart';

/// Mock 전투 로그 데이터
class MockCombatLogs {
  static List<CombatLogModel> get sampleLogs {
    final now = DateTime.now();
    return [
      CombatLogModel(
        id: '1',
        timestamp: now.subtract(const Duration(seconds: 50)),
        type: LogType.combat,
        message: '망령이 안개 속을 떠돈다. 피해: 6',
        damage: 6,
      ),
      CombatLogModel(
        id: '2',
        timestamp: now.subtract(const Duration(seconds: 42)),
        type: LogType.combat,
        message: '자동 반격: 14 피해. 망령이 약화됨.',
        damage: 14,
      ),
      CombatLogModel(
        id: '3',
        timestamp: now.subtract(const Duration(seconds: 35)),
        type: LogType.loot,
        message: '전리품 획득: 룬 조각 x1',
      ),
      CombatLogModel(
        id: '4',
        timestamp: now.subtract(const Duration(seconds: 28)),
        type: LogType.event,
        message: '방이 변함! 새 특성: 유령의, 부서지기 쉬운.',
      ),
      CombatLogModel(
        id: '5',
        timestamp: now.subtract(const Duration(seconds: 20)),
        type: LogType.combat,
        message: '골렘이 지면을 내려친다. 피해: 9',
        damage: 9,
      ),
      CombatLogModel(
        id: '6',
        timestamp: now.subtract(const Duration(seconds: 12)),
        type: LogType.combat,
        message: '치명타! 골렘 격파.',
        critical: true,
      ),
      CombatLogModel(
        id: '7',
        timestamp: now.subtract(const Duration(seconds: 6)),
        type: LogType.loot,
        message: '새로운 유물 발견: 구리 등불.',
      ),
      CombatLogModel(
        id: '8',
        timestamp: now.subtract(const Duration(seconds: 1)),
        type: LogType.system,
        message: '코덱스 업데이트: 27% 완료.',
      ),
    ];
  }
}
