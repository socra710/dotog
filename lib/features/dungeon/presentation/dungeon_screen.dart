import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/atmospheric_scaffold.dart';
import '../domain/models/combat_log_model.dart';
import '../domain/models/dungeon_state_model.dart';
import '../domain/models/log_type.dart';

class DungeonScreen extends ConsumerStatefulWidget {
  const DungeonScreen({super.key});

  @override
  ConsumerState<DungeonScreen> createState() => _DungeonScreenState();
}

class _DungeonScreenState extends ConsumerState<DungeonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 화면 진입 시 던전 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDungeon();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startDungeon() async {
    _loadingController.repeat();
    await ref.read(dungeonProvider.notifier).startDungeon();
    _loadingController.stop();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dungeonState = ref.watch(dungeonProvider);
    final dungeonNotifier = ref.read(dungeonProvider.notifier);
    final basePlayer = ref.watch(
      gameDataProvider.select((value) => value.value?.player),
    );
    final isGenerating = dungeonNotifier.isGenerating;

    final baseMaxHp = basePlayer?.maxHp ?? dungeonState.player.maxHp;
    final bonusMaxHp = (dungeonState.player.maxHp - baseMaxHp).clamp(0, 9999);
    final hpValue =
        '${dungeonState.player.currentHp}/${dungeonState.player.maxHp}';

    // 새 로그가 추가될 때 자동 스크롤
    if (dungeonState.logs.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return AtmosphericScaffold(
      title: '던전 실행',
      subtitle: isGenerating ? '던전을 생성하는 중...' : '로그로 변해가는 던전. 기록 중.',
      badge: _Badge(
        label: isGenerating
            ? '생성중'
            : dungeonState.isPaused
                ? '일시정지'
                : '로그 기록중',
      ),
      actions: [
        if (!isGenerating)
          IconButton(
            onPressed: () {
              dungeonNotifier.stopDungeon();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.close),
            color: Colors.white70,
          ),
      ],
      body: isGenerating
          ? _buildLoadingView()
          : _buildDungeonView(
              dungeonState,
              dungeonNotifier,
              hpValue,
              bonusMaxHp,
            ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // AI 생성 아이콘
        RotationTransition(
          turns: _loadingController,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE7C46A).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Color(0xFFE7C46A),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '던전 생성 중',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE7C46A),
            fontFamily: 'Galmuri11',
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '기록 시스템 준비 중...',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white60,
            fontFamily: 'Galmuri11',
          ),
        ),
        const SizedBox(height: 32),
        // 로딩 바
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              backgroundColor: const Color(0xFF1A2420),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF5FD1B7).withOpacity(0.8),
              ),
            ),
          ),
        ),
        const Spacer(),
        const Spacer(),
      ],
    );
  }

  Widget _buildDungeonView(
    DungeonStateModel dungeonState,
    DungeonNotifier dungeonNotifier,
    String hpValue,
    int bonusMaxHp,
  ) {
    return Column(
      children: [
        Row(
          children: [
            _StatPill(label: '층', value: '${dungeonState.floor}F'),
            const SizedBox(width: 10),
            _StatPill(
              label: 'HP',
              value: hpValue,
              bonusValue: bonusMaxHp,
            ),
            const SizedBox(width: 10),
            _StatPill(label: '토큰', value: '${dungeonState.player.tokens}'),
            const SizedBox(width: 10),
            _StatPill(label: '룬', value: '+${dungeonState.player.runes}'),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1512).withOpacity(0.75),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '전투 로그',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontFamily: 'Galmuri11',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: dungeonState.logs.isEmpty
                      ? const Center(
                          child: Text(
                            '전투 시작 대기 중...',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                              fontFamily: 'Galmuri11',
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          itemCount: dungeonState.logs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final log = dungeonState.logs[index];
                            return _LogLine(log: log, index: index);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => dungeonNotifier.togglePause(),
                icon: Icon(
                  dungeonState.isPaused
                      ? Icons.play_circle_outline
                      : Icons.pause_circle_outline,
                ),
                label: Text(dungeonState.isPaused ? '재개' : '일시정지'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome),
                label: const Text('부스트'),
              ),
            ),
          ],
        ),
      ],
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

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.bonusValue,
  });

  final String label;
  final String value;
  final int? bonusValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 1.1,
              color: Colors.white60,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE7C46A),
              fontWeight: FontWeight.w700,
              fontFamily: 'Galmuri11',
            ),
          ),
          if ((bonusValue ?? 0) > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+${bonusValue!}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF5FD1B7),
                fontWeight: FontWeight.w700,
                fontFamily: 'Galmuri11',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogLine extends StatefulWidget {
  const _LogLine({required this.log, required this.index});

  final CombatLogModel log;
  final int index;

  @override
  State<_LogLine> createState() => _LogLineState();
}

class _LogLineState extends State<_LogLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로그 타입에 따른 색상
    Color borderColor = Colors.white12;
    Color textColor = Colors.white70;

    switch (widget.log.type) {
      case LogType.combat:
        if (widget.log.critical) {
          borderColor = const Color(0xFFE7C46A).withOpacity(0.5);
          textColor = const Color(0xFFE7C46A);
        }
        break;
      case LogType.loot:
        borderColor = const Color(0xFF5FD1B7).withOpacity(0.3);
        textColor = const Color(0xFF5FD1B7);
        break;
      case LogType.event:
        borderColor = Colors.white24;
        break;
      case LogType.system:
        textColor = Colors.white60;
        break;
      default:
        break;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF17221C).withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Text(
            widget.log.message,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Galmuri11',
            ),
          ),
        ),
      ),
    );
  }
}
