import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/atmospheric_scaffold.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidNickname(String nickname) {
    final trimmed = nickname.trim();
    return trimmed.length >= 2 && trimmed.length <= 12;
  }

  Future<void> _submit(String currentNickname) async {
    final nickname = _controller.text.trim();
    if (!_isValidNickname(nickname)) {
      setState(() {
        _errorText = '닉네임은 2~12자로 입력해주세요.';
      });
      return;
    }

    if (nickname == currentNickname) {
      setState(() {
        _errorText = '현재 닉네임과 동일합니다.';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    await ref.read(authProvider.notifier).updateNickname(nickname);
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162019),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: Color(0xFFF3F8F2)),
        ),
        content: const Text(
          '정말 로그아웃하시겠습니까?',
          style: TextStyle(color: Colors.white70, fontFamily: 'Galmuri11'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE7C46A),
              foregroundColor: const Color(0xFF1A1F1B),
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _showResetDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162019),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE7C46A)),
        ),
        title: const Text(
          '데이터 초기화',
          style: TextStyle(color: Color(0xFFE7C46A)),
        ),
        content: const Text(
          '모든 게임 데이터(능력치, 토큰, 룬, 코덱스)가 초기화됩니다.\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Galmuri11'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE7C46A),
              foregroundColor: const Color(0xFF1A1F1B),
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).resetGameData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게임 데이터가 초기화되었습니다.'),
            backgroundColor: Color(0xFFE7C46A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentNickname = authState.userData?.nickname ?? '';
    final changeCount = authState.userData?.nicknameChangeCount ?? 0;
    final hasFreeChange = changeCount < 1;

    ref.listen(authProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        setState(() {
          _errorText = next.error;
        });
      }
    });

    if (_controller.text.isEmpty && currentNickname.isNotEmpty) {
      _controller.text = currentNickname;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }

    return AtmosphericScaffold(
      title: '설정',
      subtitle: '계정 및 게임 설정을 관리합니다.',
      badge: const _Badge(label: '계정'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임 변경 섹션
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1512).withOpacity(0.75),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          color: Color(0xFFE7C46A), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '닉네임 변경',
                        style: TextStyle(
                          color: Color(0xFFF3F8F2),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재 닉네임',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentNickname.isEmpty ? '알 수 없음' : currentNickname,
                    style: const TextStyle(
                      color: Color(0xFFE7C46A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Galmuri11',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLength: 12,
                    decoration: InputDecoration(
                      hintText: '새 닉네임 입력',
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: _errorText,
                      errorStyle: const TextStyle(
                        color: Color(0xFFE7C46A),
                        fontFamily: 'Galmuri11',
                        fontSize: 11,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFF162019).withOpacity(0.7),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE7C46A)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE7C46A)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE7C46A)),
                      ),
                    ),
                    style: const TextStyle(
                      color: Color(0xFFF3F8F2),
                      fontSize: 14,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(currentNickname),
                  ),
                  const SizedBox(height: 12),
                  // 무료 변경 횟수 표시
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162019).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFreeChange
                            ? const Color(0xFF5FD1B7).withOpacity(0.4)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasFreeChange ? Icons.check_circle_outline : Icons.lock_outline,
                          size: 16,
                          color: hasFreeChange ? const Color(0xFF5FD1B7) : Colors.white38,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasFreeChange ? '무료 변경 가능 (1회)' : '무료 변경 완료 (1/1)',
                          style: TextStyle(
                            color: hasFreeChange ? const Color(0xFF5FD1B7) : Colors.white60,
                            fontSize: 11,
                            fontFamily: 'Galmuri11',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: hasFreeChange
                        ? FilledButton(
                            onPressed: authState.isLoading
                                ? null
                                : () => _submit(currentNickname),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFE7C46A),
                              foregroundColor: const Color(0xFF1A1F1B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF1A1F1B),
                                      ),
                                    ),
                                  )
                                : const Text(
                                    '변경하기',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          )
                        : OutlinedButton.icon(
                            onPressed: null, // 추후 프리미엄 기능 구현 시 활성화
                            icon: const Icon(Icons.diamond_outlined, size: 18),
                            label: const Text('프리미엄 변경 (준비중)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white38,
                              disabledForegroundColor: Colors.white38,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFreeChange
                        ? '닉네임은 1회 무료로 변경할 수 있습니다.'
                        : '추가 변경은 프리미엄 기능으로 제공될 예정입니다.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontFamily: 'Galmuri11',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 게임 데이터 초기화 섹션
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1512).withOpacity(0.75),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restart_alt, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '게임 데이터',
                        style: TextStyle(
                          color: Color(0xFFF3F8F2),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '모든 진행 상황을 초기 상태로 되돌립니다.\n능력치, 토큰, 룬, 코덱스가 초기화됩니다.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'Galmuri11',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _showResetDialog,
                      icon: const Icon(Icons.warning_amber_outlined),
                      label: const Text('데이터 초기화'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE7C46A),
                        side: const BorderSide(color: Color(0xFFE7C46A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 로그아웃 섹션
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1512).withOpacity(0.75),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '계정',
                        style: TextStyle(
                          color: Color(0xFFF3F8F2),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재 계정에서 로그아웃합니다.\n다시 로그인하면 진행 상황을 이어서 할 수 있습니다.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontFamily: 'Galmuri11',
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text('로그아웃'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
