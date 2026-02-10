import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/firestore_service.dart';
import '../models/user_model.dart';
import 'app_providers.dart';

class AuthState {
  const AuthState({
    required this.isLoggedIn,
    this.user,
    this.userData,
    this.isLoading = false,
    this.error,
  });

  final bool isLoggedIn;
  final User? user;
  final UserModel? userData; // Firestore 유저 데이터
  final bool isLoading;
  final String? error;

  String? get username =>
      userData?.nickname ?? user?.displayName ?? user?.email;

  AuthState copyWith({
    bool? isLoggedIn,
    User? user,
    UserModel? userData,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  factory AuthState.initial() => const AuthState(
        isLoggedIn: false,
        user: null,
      );

  factory AuthState.authenticated(User user, [UserModel? userData]) =>
      AuthState(
        isLoggedIn: true,
        user: user,
        userData: userData,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  
  // FirestoreService는 Provider를 통해 가져옴
  FirestoreService get _firestoreService => ref.read(firestoreServiceProvider);

  AuthNotifier() {
    // 웹 플랫폼에서는 clientId가 필요하지 않음 (index.html에서 설정)
    // 모바일 플랫폼에서는 자동으로 설정됨
    // scopes를 제거하여 People API 의존성 제거
    _googleSignIn = GoogleSignIn();
  }

  @override
  AuthState build() {
    // 인증 상태 스트림 구독
    // signInWithGoogle()에서 이미 Firestore 데이터를 로드하므로
    // 여기서는 로그아웃 처리만 담당
    final subscription = _auth.authStateChanges().listen((User? user) async {
      if (user == null && state.isLoggedIn) {
        // 로그아웃 처리
        state = AuthState.initial();
      }
    });

    // Provider가 dispose될 때 구독 취소
    ref.onDispose(() {
      subscription.cancel();
    });

    // 초기 상태: 현재 로그인된 유저가 있으면 Firestore에서 데이터 로드
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // 초기 로딩 시에만 Firestore 조회 (비동기 처리)
      _loadUserData(currentUser);
      return AuthState.authenticated(currentUser);
    }
    return AuthState.initial();
  }

  /// 유저 데이터 로딩 (초기화 시에만 사용)
  Future<void> _loadUserData(User user) async {
    try {
      final userData = await _firestoreService.getUser(user.uid);
      if (userData != null) {
        state = state.copyWith(userData: userData);
      }
    } catch (e) {
      debugPrint('유저 데이터 로딩 실패: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Google 로그인 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인 취소
        state = state.copyWith(isLoading: false);
        return;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 자격 증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase로 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      // Firestore에 유저 저장/업데이트 및 게임 데이터 초기화 (한 번만 호출)
      if (userCredential.user != null) {
        // 병렬 처리로 Firestore 읽기/쓰기 최적화
        final results = await Future.wait([
          _firestoreService.createOrUpdateUser(
            userCredential.user!,
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          ),
          _firestoreService.getOrCreateGameData(userCredential.user!.uid),
        ]);
        
        final userData = results[0] as UserModel?;

        // 상태 업데이트 (유저 데이터 포함)
        state = state.copyWith(
          isLoggedIn: true,
          user: userCredential.user,
          userData: userData,
          isLoading: false,
        );

        // FCM 토큰 가져와서 저장 (웹 + 모바일)
        try {
          final fcmToken = kIsWeb
              ? await FirebaseMessaging.instance.getToken(
                  vapidKey:
                      'BKnDFPCHPyI4Xn7Pm4TgIUTHwbemVFAEY4UD6EHK3ysvs4vFsXQRuIvIXhFa44BiBsERa7cG-bsihZuDAPfsKIM',
                )
              : await FirebaseMessaging.instance.getToken();

          if (fcmToken != null) {
            await updateFcmToken(fcmToken);
          }
        } catch (e) {
          debugPrint('FCM 토큰 가져오기 실패: $e');
        }
      }

      // authStateChanges 리스너가 상태를 업데이트함
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '로그인 실패: ${e.toString()}',
      );
    }
  }

  /// 닉네임 변경
  Future<void> updateNickname(String nickname) async {
    final user = state.user;
    if (user == null) return;

    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      final userData = await _firestoreService.updateNickname(
        user.uid,
        trimmed,
      );
      state = state.copyWith(userData: userData, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '닉네임 변경 실패: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        error: '로그아웃 실패: ${e.toString()}',
      );
    }
  }

  /// 게임 데이터 초기화
  Future<void> resetGameData() async {
    final user = state.user;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 게임 데이터 초기화
      await _firestoreService.resetGameData(user.uid);
      
      // 닉네임 변경 횟수 리셋
      await _firestoreService.resetNicknameChangeCount(user.uid);
      
      // 최신 유저 데이터 다시 로드
      final updatedUserData = await _firestoreService.getUser(user.uid);
      
      state = state.copyWith(
        isLoading: false,
        userData: updatedUserData,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '데이터 초기화 실패: ${e.toString()}',
      );
    }
  }

  /// FCM 토큰 업데이트 (푸시 알림용)
  Future<void> updateFcmToken(String? token) async {
    final user = state.user;
    if (user == null) return;

    try {
      await _firestoreService.updateFcmToken(user.uid, token);

      // 상태 업데이트
      if (state.userData != null) {
        state = state.copyWith(
          userData: state.userData!.updateFcmToken(token ?? ''),
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'FCM 토큰 업데이트 실패: ${e.toString()}',
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
