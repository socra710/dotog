import '../../../../shared/models/codex_bonus_model.dart';
import '../../../../shared/models/codex_entry_model.dart';
import '../../../../shared/models/rarity.dart';

/// 코덱스 상태 모델
class CodexStateModel {
  const CodexStateModel({
    required this.entries,
    required this.selectedRarity,
    required this.bonusState,
  });

  final List<CodexEntryModel> entries;
  final Rarity? selectedRarity; // null이면 '전체' 필터
  final CodexBonusState bonusState;

  /// 수집률 계산
  double get completionRate {
    if (entries.isEmpty) return 0.0;
    final collected = entries.where((e) => e.collected).length;
    return collected / entries.length;
  }

  /// 수집된 항목 수
  int get collectedCount => entries.where((e) => e.collected).length;

  /// 전체 항목 수
  int get totalCount => entries.length;

  /// 다음 보너스까지 남은 수집률
  double get nextBonusThreshold {
    final current = completionRate;
    const thresholds = [0.3, 0.5, 0.7, 0.9, 1.0];
    for (final threshold in thresholds) {
      if (current < threshold) return threshold;
    }
    return 1.0;
  }

  /// 등급별 수집률 계산 (0-100 퍼센트)
  int getCollectionRateByRarity(Rarity rarity) {
    final rarityEntries = entries.where((e) => e.item.rarity == rarity).toList();
    if (rarityEntries.isEmpty) return 0;
    final collected = rarityEntries.where((e) => e.collected).length;
    return ((collected / rarityEntries.length) * 100).round();
  }

  /// 등급별 수집 아이템 수 / 전체 수
  ({int collected, int total}) getCollectionByRarity(Rarity rarity) {
    final rarityEntries = entries.where((e) => e.item.rarity == rarity).toList();
    final collected = rarityEntries.where((e) => e.collected).length;
    return (collected: collected, total: rarityEntries.length);
  }

  /// 필터링된 항목 반환
  List<CodexEntryModel> get filteredEntries {
    if (selectedRarity == null) return entries;
    return entries.where((e) => e.item.rarity == selectedRarity).toList();
  }

  CodexStateModel copyWith({
    List<CodexEntryModel>? entries,
    Rarity? selectedRarity,
    CodexBonusState? bonusState,
    bool clearRarity = false,
  }) {
    return CodexStateModel(
      entries: entries ?? this.entries,
      selectedRarity:
          clearRarity ? null : (selectedRarity ?? this.selectedRarity),
      bonusState: bonusState ?? this.bonusState,
    );
  }

  /// 항목 수집 처리
  CodexStateModel collectEntry(String itemId) {
    final updatedEntries = entries.map((entry) {
      if (entry.item.id == itemId && !entry.collected) {
        return entry.copyWith(
          collected: true,
          discoveredAt: DateTime.now(),
          encounterCount: entry.encounterCount + 1,
        );
      }
      return entry;
    }).toList();

    return copyWith(entries: updatedEntries);
  }

  /// 조우 횟수 증가
  CodexStateModel incrementEncounter(String itemId) {
    final updatedEntries = entries.map((entry) {
      if (entry.item.id == itemId) {
        return entry.copyWith(encounterCount: entry.encounterCount + 1);
      }
      return entry;
    }).toList();

    return copyWith(entries: updatedEntries);
  }

  /// 등급별 보너스 업그레이드
  CodexStateModel upgradeBonus(Rarity rarity) {
    final collectionRate = getCollectionRateByRarity(rarity);
    final newBonusState = bonusState.upgradeRarity(rarity, collectionRate);
    return copyWith(bonusState: newBonusState);
  }
}
