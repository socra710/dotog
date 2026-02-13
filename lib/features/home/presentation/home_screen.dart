import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/player_model.dart';
import '../../../shared/providers/app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTitle = false;
  bool _showMeta = false;
  bool _showActions = false;

  String _formatTokenCooldown(int seconds) {
    if (seconds <= 0) return '가득 참';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(secs)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(secs)}';
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() => _showTitle = true);
    });
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _showMeta = true);
    });
    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _showActions = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // ===== Firestore 데이터 구독 (실시간 연동) =====
    final gameDataAsync = ref.watch(gameDataProvider);
    final tokenCooldown = ref.watch(dungeonProvider).tokenCooldownSeconds;
    final authData = ref.watch(authProvider);

    // Firestore 데이터 또는 기본값 사용
    final gameData = gameDataAsync.value;
    final tokens = gameData?.player.tokens ?? 0;
    final runes = gameData?.player.runes ?? 0;
    final codexCount = gameData?.codexEntries.length ?? 0;

    final basePlayer = gameData?.player;
    final displayPlayer = basePlayer;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F2A24),
                  Color(0xFF2A3C33),
                  Color(0xFF0E1411),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: _Orb(
              size: size.width * 0.6,
              color: const Color(0xFF5FD1B7).withOpacity(0.18),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _Orb(
              size: size.width * 0.75,
              color: const Color(0xFFE7C46A).withOpacity(0.12),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            right: -40,
            child: _Orb(
              size: 140,
              color: const Color(0xFF0F1C18).withOpacity(0.35),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1814).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Text(
                          '베타 v1.0.0',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.go('/codex'),
                        icon: const Icon(Icons.menu_book_outlined),
                        color: Colors.white70,
                      ),
                      IconButton(
                        onPressed: () => context.go('/settings'),
                        icon: const Icon(Icons.settings_outlined),
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 420),
                    opacity: _showTitle ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 420),
                      offset: _showTitle ? Offset.zero : const Offset(0, 0.12),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOTOG',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: Color(0xFFF3F8F2),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '도트 던전의 모험이 시작됩니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 380),
                    opacity: _showMeta ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 380),
                      offset: _showMeta ? Offset.zero : const Offset(0, 0.12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _StatPill(
                                label: '토큰',
                                value: '$tokens',
                              ),
                              const SizedBox(width: 10),
                              _StatPill(
                                label: '코덱스',
                                value: '$codexCount개',
                              ),
                              const SizedBox(width: 10),
                              _StatPill(
                                label: '룬',
                                value: '$runes',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tokens >= 10
                                ? '토큰 가득 참'
                                : tokenCooldown > 0
                                    ? '다음 토큰까지 ${_formatTokenCooldown(tokenCooldown)} ($tokens/${10})'
                                    : '토큰 가득 참',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontFamily: 'Galmuri11',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (displayPlayer != null)
                            _CharacterStatsCard(
                              basePlayer: displayPlayer,
                              displayPlayer: displayPlayer,
                              nickname: authData.userData?.nickname ?? '모험가',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 380),
                    opacity: _showActions ? 1 : 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 380),
                      offset:
                          _showActions ? Offset.zero : const Offset(0, 0.12),
                      child: Column(
                        children: [
                          _ActionCard(
                            title: '던전 입장',
                            subtitle: '도트 던전에서 모험을 시작합니다.',
                            icon: Icons.bolt_outlined,
                            onTap: () {
                              if (tokens < 1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '토큰이 부족합니다. (필요: 1개, 보유: $tokens개)'),
                                    backgroundColor: const Color(0xFFE7C46A),
                                  ),
                                );
                              } else {
                                context.go('/dungeon');
                              }
                            },
                            isDisabled: tokens < 1,
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            title: '코덱스 보기',
                            subtitle: '획득한 코덱스 및 보너스 확인하기.',
                            icon: Icons.auto_awesome_mosaic_outlined,
                            onTap: () => context.go('/codex'),
                            isSecondary: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isSecondary = false,
    this.isDisabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSecondary;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isSecondary ? const Color(0xFF1E2B25) : const Color(0xFF24352C);

    return Material(
      color: isDisabled
          ? const Color(0xFF0E1411).withOpacity(0.5)
          : baseColor.withOpacity(0.85),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1512).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDisabled
                        ? Colors.white24.withOpacity(0.3)
                        : Colors.white24,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDisabled ? Colors.white38 : const Color(0xFFE7C46A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDisabled
                            ? Colors.white38
                            : const Color(0xFFF3F8F2),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDisabled ? Colors.white24 : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: isDisabled ? Colors.white24 : Colors.white70,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

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
        ],
      ),
    );
  }
}

class _CharacterStatsCard extends StatelessWidget {
  const _CharacterStatsCard({
    required this.basePlayer,
    required this.displayPlayer,
    required this.nickname,
  });

  final PlayerModel basePlayer;
  final PlayerModel displayPlayer;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1512).withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '캐릭터',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFF3F8F2),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE7C46A),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'NeoDGM',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 첫 번째 행
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: '레벨',
                  value: '${displayPlayer.level}',
                  icon: Icons.star_outline,
                  color: const Color(0xFFE7C46A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HpStatTile(
                  currentHp: displayPlayer.currentHp,
                  maxHp: displayPlayer.maxHp,
                  bonusMaxHp: displayPlayer.maxHp - basePlayer.maxHp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ExpBar(
            currentExp: displayPlayer.currentExp,
            expToNext: displayPlayer.expToNext,
          ),
          const SizedBox(height: 8),
          // 두 번째 행
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: '공격',
                  value: '${displayPlayer.attack}',
                  bonusValue: displayPlayer.attack - basePlayer.attack,
                  icon: Icons.flash_on,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: '방어',
                  value: '${displayPlayer.defense}',
                  bonusValue: displayPlayer.defense - basePlayer.defense,
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF5FD1B7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: '행운',
                  value: '${displayPlayer.luck}',
                  bonusValue: displayPlayer.luck - basePlayer.luck,
                  icon: Icons.local_fire_department_outlined,
                  color: const Color(0xFFFFD93D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpBar extends StatelessWidget {
  const _ExpBar({required this.currentExp, required this.expToNext});

  final int currentExp;
  final int expToNext;

  @override
  Widget build(BuildContext context) {
    final progress =
        expToNext <= 0 ? 0.0 : (currentExp / expToNext).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF162019).withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph, size: 12, color: Colors.white60),
              const SizedBox(width: 6),
              const Text(
                '경험치',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white60,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '$currentExp/$expToNext',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFE7C46A),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Galmuri11',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF1A2420),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE7C46A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.bonusValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final int? bonusValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162019).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white60,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
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
        ],
      ),
    );
  }
}

class _HpStatTile extends StatelessWidget {
  const _HpStatTile({
    required this.currentHp,
    required this.maxHp,
    this.bonusMaxHp = 0,
  });

  final int currentHp;
  final int maxHp;
  final int bonusMaxHp;

  @override
  Widget build(BuildContext context) {
    final hpPercent = currentHp / maxHp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF162019).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF5FD1B7).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_outlined, size: 12, color: Color(0xFF5FD1B7)),
              SizedBox(width: 4),
              Text(
                'HP',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white60,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      width: (hpPercent * 100).isFinite
                          ? (hpPercent * 100).toStringAsFixed(0).isEmpty
                              ? 0
                              : hpPercent * 100
                          : 0,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5FD1B7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$currentHp/$maxHp',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF5FD1B7),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Galmuri11',
                ),
              ),
            ],
          ),
          if (bonusMaxHp > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+$bonusMaxHp 최대 HP',
              style: const TextStyle(
                fontSize: 9,
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

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 60,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
