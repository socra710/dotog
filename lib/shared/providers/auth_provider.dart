import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/firestore_service.dart';
import '../models/user_model.dart';

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

  String? get username => user?.displayName ?? user?.email;

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
  final FirestoreService _firestoreService = FirestoreService();
  late final GoogleSignIn _googleSignIn;

  AuthNotifier() {
    // 웹 플랫폼에서는 clientId가 필요하지 않음 (index.html에서 설정)
    // 모바일 플랫폼에서는 자동으로 설정됨
    // scopes를 제거하여 People API 의존성 제거
    _googleSignIn = GoogleSignIn();
  }

  @override
  AuthState build() {
    // 인증 상태 스트림 구독
    final subscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Firestore에서 유저 데이터 로드
        try {
          final userData = await _firestoreService.getUser(user.uid);
          state = AuthState(
            isLoggedIn: true,
            user: user,
            userData: userData,
          );
        } catch (e) {
          // Firestore 로드 실패 시 Firebase Auth 유저만 사용
          state = AuthState.authenticated(user);
        }
      } else {
        if (state.isLoggedIn) {
          state = AuthState.initial();
        }
      }
    });

    // Provider가 dispose될 때 구독 취소
    ref.onDispose(() {
      subscription.cancel();
    });

    // 초기 상태 반환
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return AuthState.authenticated(currentUser);
    }
    return AuthState.initial();
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

      // Firestore에 유저 저장/업데이트 (토큰 포함)
      if (userCredential.user != null) {
        final userData = await _firestoreService.createOrUpdateUser(
          userCredential.user!,
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

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
