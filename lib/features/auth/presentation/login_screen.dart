import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleGoogleSignIn() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.isLoggedIn) {
        context.go('/');
      }
    });

    return Scaffold(
      body: Container(
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
        child: Stack(
          children: [
            // 배경 오브 효과
            ..._buildBackgroundOrbs(),
            // 메인 콘텐츠
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 게임 타이틀
                          _buildGameTitle(),
                          const SizedBox(height: 48),
                          // 로그인 카드
                          _buildLoginCard(authState),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundOrbs() {
    return [
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFE7C46A).withOpacity(0.08),
                const Color(0xFFE7C46A).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: -80,
        left: -80,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF5FD1B7).withOpacity(0.06),
                const Color(0xFF5FD1B7).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGameTitle() {
    return Column(
      children: [
        // 메인 타이틀
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE7C46A).withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0E1512).withOpacity(0.6),
          ),
          child: const Text(
            'DOTOG',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Color(0xFFE7C46A),
              letterSpacing: 8,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 서브 타이틀
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFF0E1512).withOpacity(0.4),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: const Text(
            '방치형 던전 크롤러',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              letterSpacing: 3,
              fontFamily: 'Galmuri11',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthState authState) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF162019).withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white24,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 환영 메시지
          const Text(
            '던전에 오신 것을 환영합니다',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFF3F8F2),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '모험을 시작하려면 로그인하세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
              fontFamily: 'Galmuri11',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // 오류 메시지
          if (authState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF6B6B),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authState.error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B6B),
                        fontFamily: 'Galmuri11',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // 구글 로그인 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _handleGoogleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1A1F1B),
                disabledBackgroundColor: Colors.white38,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFFE7C46A).withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1A1F1B),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.login,
                              size: 24,
                              color: Color(0xFF1A1F1B),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Google로 시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // 추가 정보
          const Text(
            '로그인하면 서비스 약관에 동의하게 됩니다',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white38,
              fontFamily: 'Galmuri11',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
