import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/codex_bonus_model.dart';
import '../../../shared/models/codex_entry_model.dart';
import '../../../shared/models/rarity.dart';
import '../../../shared/widgets/atmospheric_scaffold.dart';
import '../domain/models/codex_state_model.dart';
import 'codex_providers.dart';

class CodexScreen extends ConsumerWidget {
  const CodexScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codexEntriesAsync = ref.watch(codexEntriesProvider);
    final codexBonusAsync = ref.watch(codexBonusStateProvider);
    final globalItemsAsync = ref.watch(globalItemsProvider);
    final selectedRarity = ref.watch(codexRarityFilterProvider);

    return codexEntriesAsync.when(
      data: (entries) {
        final bonusState = codexBonusAsync.value ?? CodexBonusState.initial();
        final totalItemsCount = globalItemsAsync.value?.length ?? 0;
        final state = CodexStateModel(
          entries: entries,
          selectedRarity: selectedRarity,
          bonusState: bonusState,
          totalItemsCount: totalItemsCount,
        );
        final completionPercent = (state.completionRate * 100).round();
        final nextThresholdPercent = (state.nextBonusThreshold * 100).round();
        final filteredEntries = state.filteredEntries;

        return AtmosphericScaffold(
          title: '코덱스 기록',
          subtitle: '수집률로 잠금 해제된 영구 보너스.',
          badge: const _Badge(label: '수집'),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressCard(
                  percent: state.completionRate,
                  label: '$completionPercent% 완료',
                  subtitle: '$nextThresholdPercent%에서 다음 보너스',
                ),
                const SizedBox(height: 14),
                _BonusGrid(state: state),
                const SizedBox(height: 18),
                const Text(
                  '수집한 아이템',
                  style: TextStyle(
                    color: Color(0xFFF3F8F2),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _FilterChip(
                      label: '전체',
                      isActive: selectedRarity == null,
                      onTap: () {
                        ref
                            .read(codexRarityFilterProvider.notifier)
                            .clearFilter();
                      },
                    ),
                    _FilterChip(
                      label: '일반',
                      isActive: selectedRarity == Rarity.common,
                      onTap: () {
                        ref
                            .read(codexRarityFilterProvider.notifier)
                            .setFilter(Rarity.common);
                      },
                    ),
                    _FilterChip(
                      label: '희귀',
                      isActive: selectedRarity == Rarity.rare,
                      onTap: () {
                        ref
                            .read(codexRarityFilterProvider.notifier)
                            .setFilter(Rarity.rare);
                      },
                    ),
                    _FilterChip(
                      label: '에픽',
                      isActive: selectedRarity == Rarity.epic,
                      onTap: () {
                        ref
                            .read(codexRarityFilterProvider.notifier)
                            .setFilter(Rarity.epic);
                      },
                    ),
                    _FilterChip(
                      label: '전설',
                      isActive: selectedRarity == Rarity.legendary,
                      onTap: () {
                        ref
                            .read(codexRarityFilterProvider.notifier)
                            .setFilter(Rarity.legendary);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                filteredEntries.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              size: 48,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '아직 수집한 아이템이 없습니다.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                                fontFamily: 'Galmuri11',
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '던전을 탐험하여 아이템을 획득하세요!',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                                fontFamily: 'Galmuri11',
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _CodexCard(entry: entry);
                        },
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      loading: () => const AtmosphericScaffold(
        title: '코덱스 기록',
        subtitle: '수집률로 잠금 해제된 영구 보너스.',
        badge: _Badge(label: '수집'),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE7C46A)),
          ),
        ),
      ),
      error: (error, stackTrace) => const AtmosphericScaffold(
        title: '코덱스 기록',
        subtitle: '수집률로 잠금 해제된 영구 보너스.',
        badge: _Badge(label: '수집'),
        body: Center(
          child: Text(
            '코덱스 데이터를 불러오지 못했습니다.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.percent,
    required this.label,
    required this.subtitle,
  });

  final double percent;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE7C46A),
              fontWeight: FontWeight.w700,
              fontFamily: 'Galmuri11',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: 'Galmuri11',
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF162019),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF5FD1B7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFE7C46A).withOpacity(0.2)
              : const Color(0xFF0E1512).withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color(0xFFE7C46A) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFE7C46A) : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CodexCard extends StatelessWidget {
  const _CodexCard({required this.entry});

  final CodexEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.collected ? const Color(0xFF5FD1B7) : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF162019),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Icon(
                entry.collected ? Icons.auto_awesome : Icons.lock_outline,
                color:
                    entry.collected ? const Color(0xFFE7C46A) : Colors.white38,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.collected ? entry.item.name : '???',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: entry.collected ? const Color(0xFFF3F8F2) : Colors.white38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.item.rarity.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: entry.collected ? Colors.white60 : Colors.white38,
            ),
          ),
          const Spacer(),
          Text(
            entry.collected ? entry.item.bonusSummary : '미발견',
            style: TextStyle(
              fontSize: 12,
              color: entry.collected ? const Color(0xFF5FD1B7) : Colors.white38,
              fontFamily: 'Galmuri11',
            ),
          ),
        ],
      ),
    );
  }
}

class _BonusGrid extends StatelessWidget {
  const _BonusGrid({required this.state});

  final CodexStateModel state;

  Color _rarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return Colors.white70;
      case Rarity.rare:
        return const Color(0xFF5FD1B7);
      case Rarity.epic:
        return const Color(0xFFE7C46A);
      case Rarity.legendary:
        return const Color(0xFFE7C46A);
    }
  }

  String _bonusLabel(CodexBonusConfig config) {
    return config.isActive ? config.bonusSummary : '미활성화';
  }

  @override
  Widget build(BuildContext context) {
    final bonusState = state.bonusState;
    final common = bonusState.common;
    final rare = bonusState.rare;
    final epic = bonusState.epic;
    final legendary = bonusState.legendary;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _BonusCard(
                rarity: common.rarity.label,
                level: common.level,
                collectionRate: state.getCollectionRateByRarity(common.rarity),
                bonus: _bonusLabel(common),
                cost: common.upgradeCost,
                rarityColor: _rarityColor(common.rarity),
                isActive: common.isActive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BonusCard(
                rarity: rare.rarity.label,
                level: rare.level,
                collectionRate: state.getCollectionRateByRarity(rare.rarity),
                bonus: _bonusLabel(rare),
                cost: rare.upgradeCost,
                rarityColor: _rarityColor(rare.rarity),
                isActive: rare.isActive,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BonusCard(
                rarity: epic.rarity.label,
                level: epic.level,
                collectionRate: state.getCollectionRateByRarity(epic.rarity),
                bonus: _bonusLabel(epic),
                cost: epic.upgradeCost,
                rarityColor: _rarityColor(epic.rarity),
                isActive: epic.isActive,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BonusCard(
                rarity: legendary.rarity.label,
                level: legendary.level,
                collectionRate:
                    state.getCollectionRateByRarity(legendary.rarity),
                bonus: _bonusLabel(legendary),
                cost: legendary.upgradeCost,
                rarityColor: _rarityColor(legendary.rarity),
                isActive: legendary.isActive,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BonusCard extends StatelessWidget {
  const _BonusCard({
    required this.rarity,
    required this.level,
    required this.collectionRate,
    required this.bonus,
    required this.cost,
    required this.rarityColor,
    required this.isActive,
  });

  final String rarity;
  final int level;
  final int collectionRate;
  final String bonus;
  final int cost;
  final Color rarityColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? rarityColor.withOpacity(0.4) : Colors.white24,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                rarity.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: rarityColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF162019).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LV.$level',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white60,
                    fontFamily: 'Galmuri11',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$collectionRate%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE7C46A),
              fontFamily: 'Galmuri11',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bonus,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? const Color(0xFF5FD1B7) : Colors.white38,
              fontFamily: 'Galmuri11',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 12,
                color: Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                '룬 $cost',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white38,
                  fontFamily: 'Galmuri11',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
