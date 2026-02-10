import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// Firestore 컬렉션 경로 상수
class FirestoreCollections {
  static const String users = 'users';
  static const String players = 'players'; // 게임 데이터용
  static const String items = 'items'; // 아이템 데이터용
}

/// Firestore 유저 관리 서비스
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// users 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  /// 유저 문서 참조
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  /// Firebase Auth 유저로 Firestore에 유저 생성 또는 업데이트
  ///
  /// 신규 유저: 새 문서 생성
  /// 기존 유저: lastLoginAt만 업데이트
  Future<UserModel> createOrUpdateUser(User firebaseUser) async {
    final userDoc = _userDoc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    final now = DateTime.now();

    if (docSnapshot.exists) {
      // 기존 유저 - lastLoginAt 업데이트
      await userDoc.update({
        'lastLoginAt': Timestamp.fromDate(now),
        // 프로필 정보도 최신화 (Google 계정에서 변경될 수 있음)
        'displayName': firebaseUser.displayName,
        'photoURL': firebaseUser.photoURL,
        'email': firebaseUser.email,
      });

      // 업데이트된 데이터 조회
      final userData = UserModel.fromFirestore(await userDoc.get());
      return userData;
    } else {
      // 신규 유저 - 새 문서 생성
      final newUser = UserModel.create(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
      );

      await userDoc.set(newUser.toFirestore());
      return newUser;
    }
  }

  /// 유저 정보 조회
  Future<UserModel?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// 유저 정보 스트림 (실시간)
  Stream<UserModel?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// FCM 토큰 업데이트
  Future<void> updateFcmToken(String uid, String? token) async {
    await _userDoc(uid).update({
      'fcmToken': token,
    });
  }

  /// 유저 삭제 (계정 삭제 시)
  Future<void> deleteUser(String uid) async {
    await _userDoc(uid).delete();
  }

  /// 로그인 시간 업데이트
  Future<void> updateLastLogin(String uid) async {
    await _userDoc(uid).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 배치 쓰기 예시 (여러 문서를 한 번에 쓰기)
  Future<void> batchWrite(List<UserModel> users) async {
    final batch = _firestore.batch();
    for (final user in users) {
      batch.set(_userDoc(user.uid), user.toFirestore());
    }
    await batch.commit();
  }
}
