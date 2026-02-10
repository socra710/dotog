import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/dungeon_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showTitle = false;
  bool _showMeta = false;
  bool _showActions = false;

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
                          '버전 v1.0.0',
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
                      _LogoutButton(onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      }),
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
                      child: Row(
                        children: [
                          _StatPill(
                              label: '룬',
                              value:
                                  '${ref.watch(dungeonProvider).player.runes}'),
                          const SizedBox(width: 10),
                          const _StatPill(label: '코덱스', value: '27%'),
                          const SizedBox(width: 10),
                          const _StatPill(label: '자동', value: 'ON'),
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
                              final runes =
                                  ref.watch(dungeonProvider).player.runes;
                              if (runes < 1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('룬이 부족합니다. (필요: 1개, 보유: $runes개)'),
                                    backgroundColor: const Color(0xFFE7C46A),
                                  ),
                                );
                              } else {
                                context.go('/dungeon');
                              }
                            },
                            isDisabled:
                                ref.watch(dungeonProvider).player.runes < 1,
                          ),
                          const SizedBox(height: 12),
                          _ActionCard(
                            title: '아이템 도감',
                            subtitle: '획득한 아이템 및 보너스 확인하기.',
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.logout),
      color: Colors.white70,
      tooltip: '로그아웃',
    );
  }
}
