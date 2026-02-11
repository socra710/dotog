import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore users 컬렉션의 유저 모델
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.nickname,
    this.nicknameSetAt,
    this.nicknameChangeCount = 0,
    required this.createdAt,
    required this.lastLoginAt,
    this.fcmToken,
    this.accessToken,
    this.idToken,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? nickname;
  final DateTime? nicknameSetAt;
  final int nicknameChangeCount;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final String? fcmToken;
  final String? accessToken;
  final String? idToken;

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? nickname,
    DateTime? nicknameSetAt,
    int? nicknameChangeCount,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? fcmToken,
    String? accessToken,
    String? idToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      nickname: nickname ?? this.nickname,
      nicknameSetAt: nicknameSetAt ?? this.nicknameSetAt,
      nicknameChangeCount: nicknameChangeCount ?? this.nicknameChangeCount,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      fcmToken: fcmToken ?? this.fcmToken,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
    );
  }

  /// Firestore 문서를 UserModel로 변환
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      nickname: data['nickname'] as String?,
      nicknameSetAt: (data['nicknameSetAt'] as Timestamp?)?.toDate(),
      nicknameChangeCount: data['nicknameChangeCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      fcmToken: data['fcmToken'] as String?,
      accessToken: data['accessToken'] as String?,
      idToken: data['idToken'] as String?,
    );
  }

  /// UserModel을 Firestore 문서로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'nickname': nickname,
      'nicknameSetAt':
          nicknameSetAt == null ? null : Timestamp.fromDate(nicknameSetAt!),
      'nicknameChangeCount': nicknameChangeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'fcmToken': fcmToken,
      'accessToken': accessToken,
      'idToken': idToken,
    };
  }

  /// 새 유저 생성 (가입 시)
  factory UserModel.create({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      nickname: null,
      nicknameSetAt: null,
      nicknameChangeCount: 0,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  /// 로그인 시간만 업데이트
  UserModel updateLastLogin() {
    return copyWith(lastLoginAt: DateTime.now());
  }

  /// FCM 토큰 업데이트
  UserModel updateFcmToken(String token) {
    return copyWith(fcmToken: token);
  }
}
