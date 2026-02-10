import 'package:flutter/material.dart';

import '../../../shared/data/mock_items.dart';
import '../../../shared/models/codex_entry_model.dart';
import '../../../shared/widgets/atmospheric_scaffold.dart';

class CodexScreen extends StatelessWidget {
  const CodexScreen({super.key});

  // Mock 코덱스 엔트리 생성
  static final List<CodexEntryModel> _mockCodex = [
    CodexEntryModel(
      item: MockItems.items[0], // 구리 등불
      collected: true,
      discoveredAt: DateTime.now().subtract(const Duration(days: 3)),
      encounterCount: 5,
    ),
    CodexEntryModel(
      item: MockItems.items[1], // 룬 조각
      collected: true,
      discoveredAt: DateTime.now().subtract(const Duration(days: 2)),
      encounterCount: 8,
    ),
    CodexEntryModel.undiscovered(MockItems.items[2]), // 안개 나침반
    CodexEntryModel.undiscovered(MockItems.items[3]), // 망령의 인장
    CodexEntryModel.undiscovered(MockItems.items[4]), // 황금 껍질
    CodexEntryModel.undiscovered(MockItems.items[5]), // 침묵의 주상
  ];

  @override
  Widget build(BuildContext context) {
    return AtmosphericScaffold(
      title: '코덱스 기록',
      subtitle: '수집률로 잠금 해제된 영구 보너스.',
      badge: const _Badge(label: '수집'),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.filter_alt_outlined),
          color: Colors.white70,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ProgressCard(
            percent: 0.27,
            label: '27% 완료',
            subtitle: '30%에서 다음 보너스: +1 공격',
          ),
          const SizedBox(height: 14),
          const _BonusGrid(),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(label: '전체', isActive: true),
              _FilterChip(label: '일반'),
              _FilterChip(label: '희귀'),
              _FilterChip(label: '전설'),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _mockCodex.length,
              itemBuilder: (context, index) {
                final entry = _mockCodex[index];
                return _CodexCard(entry: entry);
              },
            ),
          ),
        ],
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
        color: const Color(0xFF0F1814).withOpacity(0.6),
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
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A2420),
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
  const _FilterChip({required this.label, this.isActive = false});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          color: entry.collected ? const Color(0xFF5FD1B7) : Colors.white12,
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
              border: Border.all(color: Colors.white12),
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
              color: entry.collected ? Colors.white60 : Colors.white30,
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
  const _BonusGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BonusCard(
            rarity: '일반',
            level: 0,
            collectionRate: 20,
            bonus: '미활성화',
            cost: 10,
            rarityColor: Colors.white70,
            isActive: false,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BonusCard(
            rarity: '희귀',
            level: 0,
            collectionRate: 10,
            bonus: '미활성화',
            cost: 20,
            rarityColor: const Color(0xFF5FD1B7),
            isActive: false,
          ),
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
              Icon(
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

