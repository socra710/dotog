import '../../../../shared/models/player_model.dart';
import 'combat_log_model.dart';

/// 던전 상태 모델
class DungeonStateModel {
  const DungeonStateModel({
    required this.floor,
    required this.isActive,
    required this.isPaused,
    required this.player,
    required this.logs,
    required this.ontologies,
  });

  final int floor;
  final bool isActive;
  final bool isPaused;
  final PlayerModel player;
  final List<CombatLogModel> logs;
  final List<String> ontologies; // 특성 태그 (예: '유령의', '부서지기 쉬운')

  DungeonStateModel copyWith({
    int? floor,
    bool? isActive,
    bool? isPaused,
    PlayerModel? player,
    List<CombatLogModel>? logs,
    List<String>? ontologies,
  }) {
    return DungeonStateModel(
      floor: floor ?? this.floor,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      player: player ?? this.player,
      logs: logs ?? this.logs,
      ontologies: ontologies ?? this.ontologies,
    );
  }

  /// 초기 던전 상태
  factory DungeonStateModel.initial() {
    return DungeonStateModel(
      floor: 1,
      isActive: false,
      isPaused: false,
      player: PlayerModel.initial(),
      logs: const [],
      ontologies: const [],
    );
  }

  /// 로그 추가
  DungeonStateModel addLog(CombatLogModel log) {
    final newLogs = [...logs, log];
    // 최근 50개 로그만 유지
    if (newLogs.length > 50) {
      newLogs.removeRange(0, newLogs.length - 50);
    }
    return copyWith(logs: newLogs);
  }

  /// 특성 추가
  DungeonStateModel addOntology(String ontology) {
    if (ontologies.contains(ontology)) return this;
    return copyWith(ontologies: [...ontologies, ontology]);
  }

  /// 다음 층으로 이동
  DungeonStateModel nextFloor() {
    return copyWith(
      floor: floor + 1,
      ontologies: [], // 새 층에서는 특성 초기화
    );
  }
}
