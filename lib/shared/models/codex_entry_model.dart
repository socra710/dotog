import 'item_model.dart';

/// 코덱스 항목 모델
class CodexEntryModel {
  const CodexEntryModel({
    required this.item,
    required this.collected,
    required this.discoveredAt,
    required this.encounterCount,
  });

  final ItemModel item;
  final bool collected;
  final DateTime? discoveredAt;
  final int encounterCount;

  CodexEntryModel copyWith({
    ItemModel? item,
    bool? collected,
    DateTime? discoveredAt,
    int? encounterCount,
  }) {
    return CodexEntryModel(
      item: item ?? this.item,
      collected: collected ?? this.collected,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      encounterCount: encounterCount ?? this.encounterCount,
    );
  }

  /// 미수집 항목 생성
  factory CodexEntryModel.undiscovered(ItemModel item) {
    return CodexEntryModel(
      item: item,
      collected: false,
      discoveredAt: null,
      encounterCount: 0,
    );
  }
}
