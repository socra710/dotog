import 'log_type.dart';

/// 전투 로그 모델
class CombatLogModel {
  const CombatLogModel({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    this.damage,
    this.critical = false,
  });

  final String id;
  final DateTime timestamp;
  final LogType type;
  final String message;
  final int? damage;
  final bool critical;

  /// 로그 생성 헬퍼 메서드
  factory CombatLogModel.combat(String message,
      {int? damage, bool critical = false}) {
    return CombatLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.combat,
      message: message,
      damage: damage,
      critical: critical,
    );
  }

  factory CombatLogModel.loot(String message) {
    return CombatLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.loot,
      message: message,
    );
  }

  factory CombatLogModel.event(String message) {
    return CombatLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.event,
      message: message,
    );
  }

  factory CombatLogModel.system(String message) {
    return CombatLogModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      type: LogType.system,
      message: message,
    );
  }
}
