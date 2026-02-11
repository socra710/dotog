import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/codex_bonus_model.dart';
import '../../../shared/models/codex_entry_data_model.dart';
import '../../../shared/models/codex_entry_model.dart';
import '../../../shared/models/item_model.dart';
import '../../../shared/models/rarity.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/game_data_provider.dart';
import '../domain/codex_mapper.dart';

// Rarity 필터링을 위한 간단한 notifier
class CodexRarityFilterNotifier extends Notifier<Rarity?> {
  @override
  Rarity? build() => null;

  void setFilter(Rarity? rarity) {
    state = rarity;
  }

  void clearFilter() {
    state = null;
  }
}

final codexRarityFilterProvider =
    NotifierProvider<CodexRarityFilterNotifier, Rarity?>(
  () => CodexRarityFilterNotifier(),
);

/// Firestore items 컬렉션에서 전체 아이템 목록 조회
final globalItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getAllItems();
});

final codexEntriesProvider = Provider<AsyncValue<List<CodexEntryModel>>>((ref) {
  final codexEntriesAsync = ref.watch(
    gameDataProvider.select(
      (value) => value.whenData(
        (data) => data?.codexEntries ?? const <CodexEntryDataModel>[],
      ),
    ),
  );

  final globalItemsAsync = ref.watch(globalItemsProvider);

  // 두 AsyncValue를 결합
  return codexEntriesAsync.when(
    data: (entries) {
      return globalItemsAsync.when(
        data: (items) {
          return AsyncValue.data(
            buildCodexEntries(
              items: items,
              dataEntries: entries,
            ),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final codexBonusStateProvider = Provider<AsyncValue<CodexBonusState>>((ref) {
  final bonusAsync = ref.watch(
    gameDataProvider.select(
      (value) => value.whenData(
        (data) => data?.codexBonusState ?? CodexBonusState.initial(),
      ),
    ),
  );

  return bonusAsync;
});
