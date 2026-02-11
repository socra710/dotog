import '../../../shared/models/codex_entry_data_model.dart';
import '../../../shared/models/codex_entry_model.dart';
import '../../../shared/models/item_model.dart';

List<CodexEntryModel> buildCodexEntries({
  required List<ItemModel> items,
  required List<CodexEntryDataModel> dataEntries,
}) {
  final itemsById = {
    for (final item in items) item.id: item,
  };

  // 수집한 아이템만 표시 (Firestore에 있는 것만)
  return dataEntries
      .where((entry) => entry.collected)
      .map((dataEntry) {
        final item = itemsById[dataEntry.itemId];
        if (item == null) {
          return null;
        }

        return CodexEntryModel(
          item: item,
          collected: dataEntry.collected,
          discoveredAt: dataEntry.discoveredAt,
          encounterCount: dataEntry.encounterCount,
        );
      })
      .whereType<CodexEntryModel>()
      .toList();
}
