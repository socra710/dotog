import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/mock_items.dart';
import '../models/codex_bonus_model.dart';
import '../models/codex_entry_data_model.dart';
import '../models/game_data_model.dart';
import '../models/item_model.dart';
import '../models/rarity.dart';
import '../models/user_model.dart';

/// Firestore 컬렉션 경로 상수
class FirestoreCollections {
  static const String users = 'users';
  // TODO: character → players 컬렉션으로 리팩토링
  // 현재: character 컬렉션이 실제 게임 데이터를 저장 중
  // 계획: players 컬렉션으로 통일하기
  static const String players = 'players'; // 게임 데이터용 (예정)
  static const String items = 'items'; // 아이템 데이터용
}

/// Firestore 유저 관리 서비스
///
/// 최적화 기능:
/// - 유저 데이터 캐싱으로 불필요한 읽기 방지 (5분 TTL)
/// - 게임 데이터 캐싱으로 반복 조회 최적화
/// - 배치 작업 지원
///
/// 사용 방법:
/// ```dart
/// // Provider를 통해 사용 (싱글톤)
/// final firestoreService = ref.read(firestoreServiceProvider);
///
/// // 유저 조회 (캐싱 적용)
/// final user = await firestoreService.getUser(uid);
///
/// // 실시간 스트림 (필요한 경우만 사용)
/// firestoreService.watchGameData(uid).listen((data) {
///   // 실시간 업데이트 처리
/// });
/// ```
///
/// 주의사항:
/// - 직접 인스턴스 생성 금지: FirestoreService() ❌
/// - 항상 firestoreServiceProvider 사용 ✅
/// - 실시간 리스너는 필요한 곳에만 사용 (비용 고려)
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 유저 데이터 캐시 (메모리 내 캐시)
  final Map<String, UserModel> _userCache = {};
  final Map<String, DateTime> _userCacheTimestamp = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // 게임 데이터 캐시
  final Map<String, GameDataModel> _gameDataCache = {};
  final Map<String, DateTime> _gameDataCacheTimestamp = {};

  // items 컬렉션 캐시
  List<ItemModel>? _allItemsCache;
  DateTime? _allItemsCacheTimestamp;

  /// users 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestoreCollections.users);

  /// 유저 문서 참조
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _usersCollection.doc(uid);

  /// 플레이어 문서 참조
  DocumentReference<Map<String, dynamic>> _playerDoc(String uid) =>
      _firestore.collection(FirestoreCollections.players).doc(uid);

  /// items 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection(FirestoreCollections.items);

  String _generateRandomNickname() {
    final adjectives = [
      '어둠의',
      '고요한',
      '잊혀진',
      '잿빛',
      '은빛',
      '불꽃',
      '안개',
      '황금',
      '푸른',
      '차가운',
      '부서진',
      '떠도는',
      '잠든',
      '깨어난',
      '저주받은',
      '축복받은',
      '영원한',
      '고대의',
      '가려진',
      '빛나는',
    ];
    final nouns = [
      '등불',
      '망령',
      '룬',
      '정찰자',
      '파수꾼',
      '방패',
      '검',
      '탐험가',
      '사냥꾼',
      '나침반',
      '수호자',
      '전사',
      '마법사',
      '도적',
      '유령',
      '기사',
      '순례자',
      '현자',
      '방랑자',
      '용병',
    ];

    final random = Random();
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final number = random.nextInt(900) + 100;
    return '$adjective$noun$number';
  }

  /// Firebase Auth 유저로 Firestore에 유저 생성 또는 업데이트
  ///
  /// 신규 유저: 새 문서 생성
  /// 기존 유저: lastLoginAt만 업데이트
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 연결 실패, 권한 오류
  /// - Exception: 예상치 못한 오류
  Future<UserModel> createOrUpdateUser(
    User firebaseUser, {
    String? accessToken,
    String? idToken,
  }) async {
    try {
      final userDoc = _userDoc(firebaseUser.uid);
      final docSnapshot = await userDoc.get();

      final now = DateTime.now();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data == null) {
          throw StateError('유저 문서 데이터가 비어있습니다.');
        }

        final currentNickname = data['nickname'] as String?;
        final shouldSetNickname =
            currentNickname == null || currentNickname.trim().isEmpty;
        final nickname =
            shouldSetNickname ? _generateRandomNickname() : currentNickname;

        // 기존 유저 - lastLoginAt 및 토큰 업데이트
        await userDoc.update({
          'lastLoginAt': Timestamp.fromDate(now),
          // 프로필 정보도 최신화 (Google 계정에서 변경될 수 있음)
          'displayName': firebaseUser.displayName,
          'photoURL': firebaseUser.photoURL,
          'email': firebaseUser.email,
          'accessToken': accessToken,
          'idToken': idToken,
          if (shouldSetNickname) 'nickname': nickname,
          if (shouldSetNickname) 'nicknameSetAt': Timestamp.fromDate(now),
        });

        // 업데이트된 데이터 조회
        final updatedDoc = await userDoc.get();
        final userData = UserModel.fromFirestore(updatedDoc);

        // 캐시 업데이트
        _userCache[firebaseUser.uid] = userData;
        _userCacheTimestamp[firebaseUser.uid] = DateTime.now();

        return userData;
      } else {
        final nickname = _generateRandomNickname();
        // 신규 유저 - 새 문서 생성
        final newUser = UserModel.create(
          uid: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        ).copyWith(
          accessToken: accessToken,
          idToken: idToken,
          nickname: nickname,
          nicknameSetAt: now,
        );

        await userDoc.set(newUser.toFirestore());

        // 캐시 업데이트
        _userCache[firebaseUser.uid] = newUser;
        _userCacheTimestamp[firebaseUser.uid] = DateTime.now();

        return newUser;
      }
    } on FirebaseException catch (e) {
      throw StateError('Firestore 오류: ${e.message}');
    } catch (e) {
      throw StateError('유저 생성/업데이트 실패: ${e.toString()}');
    }
  }

  /// 닉네임 중복 체크
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회 실패
  Future<bool> isNicknameTaken(String nickname) async {
    try {
      final query = await _usersCollection
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw StateError('닉네임 조회 실패: ${e.message}');
    } catch (e) {
      throw StateError('닉네임 중복 체크 실패: ${e.toString()}');
    }
  }

  /// 닉네임 변경 (중복 체크 및 1회 무료 제한)
  ///
  /// 에러 처리:
  /// - StateError: 유저 미존재, 닉네임 중복, 변경 횟수 초과
  /// - FirebaseException: Firestore 오류
  Future<UserModel> updateNickname(String uid, String nickname,
      {bool isPremium = false}) async {
    try {
      final userDoc = _userDoc(uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        throw StateError('유저 문서가 존재하지 않습니다.');
      }

      final userData = UserModel.fromFirestore(snapshot);

      // 무료 변경 횟수 체크 (프리미엄이 아닐 경우)
      if (!isPremium && userData.nicknameChangeCount >= 1) {
        throw StateError('무료 닉네임 변경 횟수를 초과했습니다. 프리미엄 변경을 이용해주세요.');
      }

      // 중복 체크
      final isTaken = await isNicknameTaken(nickname);
      if (isTaken) {
        throw StateError('이미 사용 중인 닉네임입니다.');
      }

      await userDoc.update({
        'nickname': nickname,
        'nicknameSetAt': Timestamp.fromDate(DateTime.now()),
        'nicknameChangeCount': userData.nicknameChangeCount + 1,
      });

      // 캐시 무효화 (다시 조회)
      _invalidateUserCache(uid);

      final updatedSnapshot = await userDoc.get();
      return UserModel.fromFirestore(updatedSnapshot);
    } on FirebaseException catch (e) {
      throw StateError('Firestore 오류: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// 유저 정보 조회 (캐싱 적용)
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회 실패
  /// - Exception: Firestore 데이터 직렬화 오류
  Future<UserModel?> getUser(String uid) async {
    try {
      // 캐시 확인
      if (_userCache.containsKey(uid)) {
        final cacheTime = _userCacheTimestamp[uid];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          return _userCache[uid];
        }
      }

      // 캐시가 없거나 만료되었으면 Firestore에서 조회
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;

      final user = UserModel.fromFirestore(doc);

      // 캐시 업데이트
      _userCache[uid] = user;
      _userCacheTimestamp[uid] = DateTime.now();

      return user;
    } on FirebaseException catch (e) {
      throw StateError('사용자 조회 실패: ${e.message}');
    } catch (e) {
      throw StateError('사용자 데이터 처리 오류: ${e.toString()}');
    }
  }

  /// 캐시 무효화 (업데이트 후 호출)
  void _invalidateUserCache(String uid) {
    _userCache.remove(uid);
    _userCacheTimestamp.remove(uid);
  }

  void _invalidateGameDataCache(String uid) {
    _gameDataCache.remove(uid);
    _gameDataCacheTimestamp.remove(uid);
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

    // FCM 토큰은 캐시에 영향 없음 (중요한 데이터가 아님)
  }

  /// 유저 삭제 (계정 삭제 시)
  Future<void> deleteUser(String uid) async {
    await _userDoc(uid).delete();
    _invalidateUserCache(uid);
  }

  /// 로그인 시간 업데이트
  Future<void> updateLastLogin(String uid) async {
    await _userDoc(uid).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
    });
    // lastLoginAt은 캐시 무효화 불필요 (중요한 데이터가 아님)
  }

  /// 게임 데이터 조회 (캐싱 적용)
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회 실패
  /// - Exception: Firestore 데이터 직렬화 오류
  Future<GameDataModel?> getGameData(String uid) async {
    try {
      // 캐시 확인
      if (_gameDataCache.containsKey(uid)) {
        final cacheTime = _gameDataCacheTimestamp[uid];
        if (cacheTime != null &&
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          return _gameDataCache[uid];
        }
      }

      // 캐시가 없거나 만료되었으면 Firestore에서 조회
      final doc = await _playerDoc(uid).get();
      if (!doc.exists) return null;

      final gameData = GameDataModel.fromFirestore(doc);

      // 캐시 업데이트
      _gameDataCache[uid] = gameData;
      _gameDataCacheTimestamp[uid] = DateTime.now();

      return gameData;
    } on FirebaseException catch (e) {
      throw StateError('게임 데이터 조회 실패: ${e.message}');
    } catch (e) {
      throw StateError('게임 데이터 처리 오류: ${e.toString()}');
    }
  }

  /// 게임 데이터 스트림 (실시간)
  Stream<GameDataModel?> watchGameData(String uid) {
    return _playerDoc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameDataModel.fromFirestore(doc);
    });
  }

  /// 게임 데이터 최초 생성
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 쓰기 실패
  Future<GameDataModel> createInitialGameData(String uid) async {
    try {
      final data = GameDataModel.initial();
      await _playerDoc(uid).set(data.toFirestore());

      // 캐시 업데이트
      _gameDataCache[uid] = data;
      _gameDataCacheTimestamp[uid] = DateTime.now();

      return data;
    } on FirebaseException catch (e) {
      throw StateError('게임 데이터 생성 실패: ${e.message}');
    } catch (e) {
      throw StateError('게임 데이터 생성 중 오류: ${e.toString()}');
    }
  }

  /// 게임 데이터 존재 보장
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회/쓰기 실패
  Future<GameDataModel> getOrCreateGameData(String uid) async {
    try {
      final existing = await getGameData(uid);
      if (existing != null) return existing;
      return await createInitialGameData(uid);
    } catch (e) {
      rethrow;
    }
  }

  /// 게임 데이터 초기화 (리셋)
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 쓰기 실패
  Future<GameDataModel> resetGameData(String uid) async {
    try {
      final data = GameDataModel.initial();
      await _playerDoc(uid).set(data.toFirestore());

      // 캐시 무효화
      _invalidateGameDataCache(uid);

      return data;
    } on FirebaseException catch (e) {
      throw StateError('게임 데이터 초기화 실패: ${e.message}');
    } catch (e) {
      throw StateError('게임 데이터 초기화 중 오류: ${e.toString()}');
    }
  }

  /// 닉네임 변경 횟수 리셋
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 업데이트 실패
  Future<void> resetNicknameChangeCount(String uid) async {
    try {
      await _userDoc(uid).update({
        'nicknameChangeCount': 0,
      });
      _invalidateUserCache(uid);
    } on FirebaseException catch (e) {
      throw StateError('닉네임 변경 횟수 리셋 실패: ${e.message}');
    } catch (e) {
      throw StateError('리셋 중 오류: ${e.toString()}');
    }
  }

  /// 배치 쓰기 예시 (여러 문서를 한 번에 쓰기)
  ///
  /// 원자성 보장: 모두 성공 또는 모두 실패
  /// 네트워크 요청 횟수 감소
  ///
  /// 에러 처리:
  /// - FirebaseException: 배치 작업 실패
  Future<void> batchWrite(List<UserModel> users) async {
    try {
      final batch = _firestore.batch();
      for (final user in users) {
        batch.set(_userDoc(user.uid), user.toFirestore());
      }
      await batch.commit();

      // 캐시 무효화
      for (final user in users) {
        _invalidateUserCache(user.uid);
      }
    } on FirebaseException catch (e) {
      throw StateError('배치 쓰기 실패: ${e.message}');
    } catch (e) {
      throw StateError('배치 작업 중 오류: ${e.toString()}');
    }
  }

  /// 트랜잭션을 사용한 안전한 업데이트 예시
  ///
  /// 동시성 제어가 필요한 경우 사용 (예: 룬 차감, 재화 거래)
  /// ```dart
  /// await firestoreService.updateRunesWithTransaction(
  ///   uid,
  ///   amount: -100, // 100룬 차감
  /// );
  /// ```
  ///
  /// 에러 처리:
  /// - StateError: 게임 데이터 미존재, 룬 부족
  /// - FirebaseException: Firestore 트랜잭션 실패
  Future<void> updateRunesWithTransaction(
    String uid, {
    required int amount,
  }) async {
    try {
      final playerDocRef = _playerDoc(uid);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(playerDocRef);

        if (!snapshot.exists) {
          throw StateError('게임 데이터가 존재하지 않습니다.');
        }

        final currentData = GameDataModel.fromFirestore(snapshot);
        final newRunes = currentData.player.runes + amount;

        if (newRunes < 0) {
          throw StateError('룬이 부족합니다.');
        }

        transaction.update(playerDocRef, {
          'player.runes': newRunes,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      // 트랜잭션 성공 시 캐시 무효화
      _invalidateGameDataCache(uid);
    } on FirebaseException catch (e) {
      throw StateError('룬 업데이트 실패: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// 코덱스 보너스 업그레이드 (룬 차감 포함)
  ///
  /// - 룬이 부족하면 예외 발생
  /// - 등급별 수집률로 보너스 계산
  ///
  /// 에러 처리:
  /// - StateError: 게임 데이터 미존재, 룬 부족
  /// - FirebaseException: Firestore 트랜잭션 실패
  Future<CodexBonusState> upgradeCodexBonus(
    String uid, {
    required Rarity rarity,
  }) async {
    try {
      final playerDocRef = _playerDoc(uid);
      late CodexBonusState updatedState;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(playerDocRef);

        if (!snapshot.exists) {
          throw StateError('게임 데이터가 존재하지 않습니다.');
        }

        final currentData = GameDataModel.fromFirestore(snapshot);
        final currentBonusState = currentData.codexBonusState;
        final currentConfig = currentBonusState.getByRarity(rarity);
        final cost = currentConfig.upgradeCost;
        final collectionRate = _getCollectionRateByRarity(
          currentData.codexEntries,
          rarity,
        );

        if (currentData.player.runes < cost) {
          throw StateError('룬이 부족합니다.');
        }

        updatedState = currentBonusState.upgradeRarity(rarity, collectionRate);
        final newRunes = currentData.player.runes - cost;

        transaction.update(playerDocRef, {
          'player.runes': newRunes,
          'codexBonusState': updatedState.toMap(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });

      _invalidateGameDataCache(uid);
      return updatedState;
    } on FirebaseException catch (e) {
      throw StateError('코덱스 보너스 업그레이드 실패: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  int _getCollectionRateByRarity(
    List<CodexEntryDataModel> entries,
    Rarity rarity,
  ) {
    final itemRarityById = {
      for (final item in MockItems.items) item.id: item.rarity,
    };
    final total = itemRarityById.values.where((r) => r == rarity).length;

    if (total == 0) return 0;

    final collected = entries.where((entry) {
      if (!entry.collected) return false;
      final entryRarity = itemRarityById[entry.itemId];
      return entryRarity == rarity;
    }).length;

    return ((collected / total) * 100).round();
  }

  // ============================================================================
  // Items 컬렉션 관리 (AI 생성 아이템)
  // ============================================================================

  /// 전체 아이템 목록 조회 (캐싱 적용)
  ///
  /// AI가 생성한 모든 아이템을 Firestore에서 조회합니다.
  /// 수집률 계산의 분모가 됩니다.
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회 실패
  Future<List<ItemModel>> getAllItems() async {
    try {
      // 캐시 확인 (5분)
      if (_allItemsCache != null && _allItemsCacheTimestamp != null) {
        if (DateTime.now().difference(_allItemsCacheTimestamp!) <
            _cacheDuration) {
          return _allItemsCache!;
        }
      }

      // Firestore에서 조회
      final snapshot = await _itemsCollection.get();
      final items =
          snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();

      // 캐시 업데이트
      _allItemsCache = items;
      _allItemsCacheTimestamp = DateTime.now();

      return items;
    } on FirebaseException catch (e) {
      throw StateError('아이템 목록 조회 실패: ${e.message}');
    } catch (e) {
      throw StateError('아이템 데이터 처리 오류: ${e.toString()}');
    }
  }

  /// 아이템 ID로 조회
  ///
  /// 에러 처리:
  Future<ItemModel?> getItem(String id) async {
    try {
      final doc = await _itemsCollection.doc(id).get();
      if (!doc.exists) return null;
      return ItemModel.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Items 컬렉션 초기화 (MockItems 데이터로 모든 아이템 생성)
  ///
  /// 앱 첫 실행 시 호출하면 Firestore에 모든 아이템이 한 번에 추가됩니다.
  /// 이미 있는 아이템은 덮어씀.
  ///
  /// 사용:
  /// ```dart
  /// await firestoreService.initializeItems();
  /// ```
  Future<void> initializeItems() async {
    try {
      final batch = _firestore.batch();

      // MockItems의 모든 아이템을 Firestore에 추가
      for (final item in MockItems.items) {
        final ref = _itemsCollection.doc(item.id);
        batch.set(ref, {
          'id': item.id,
          'name': item.name,
          'description': item.description,
          'rarity': item.rarity.name, // enum을 string으로
          'attackBonus': item.attackBonus,
          'defenseBonus': item.defenseBonus,
          'hpBonus': item.hpBonus,
          'luckBonus': item.luckBonus,
        });
      }

      // 배치 커밋
      await batch.commit();

      // 캐시 무효화
      _allItemsCache = null;
      _allItemsCacheTimestamp = null;

      debugPrint('✅ Items 컬렉션 초기화 완료: ${MockItems.items.length}개 아이템 추가');
    } on FirebaseException catch (e) {
      throw StateError('Items 초기화 실패: ${e.message}');
    } catch (e) {
      throw StateError('Items 초기화 중 오류: ${e.toString()}');
    }
  }

  /// 아이템 ID로 조회
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회 실패
  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (!doc.exists) return null;
      return ItemModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw StateError('아이템 조회 실패: ${e.message}');
    } catch (e) {
      throw StateError('아이템 데이터 처리 오류: ${e.toString()}');
    }
  }

  /// 아이템이 존재하지 않으면 추가 (AI 던전 생성 시 사용)
  ///
  /// - 중복 체크: 같은 ID가 이미 존재하면 추가하지 않음
  /// - 캐시 무효화: 새 아이템 추가 시 캐시를 리셋
  ///
  /// 반환값:
  /// - true: 새 아이템 추가됨
  /// - false: 이미 존재하는 아이템
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 쓰기 실패
  Future<bool> addItemIfNotExists(ItemModel item) async {
    try {
      final docRef = _itemsCollection.doc(item.id);
      final doc = await docRef.get();

      if (doc.exists) {
        return false; // 이미 존재
      }

      // 새 아이템 추가
      await docRef.set(item.toFirestore());

      // 캐시 무효화
      _invalidateItemsCache();

      return true; // 새로 추가됨
    } on FirebaseException catch (e) {
      throw StateError('아이템 추가 실패: ${e.message}');
    } catch (e) {
      throw StateError('아이템 추가 중 오류: ${e.toString()}');
    }
  }

  /// 여러 아이템을 배치로 추가 (최초 seed 데이터 용)
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 쓰기 실패
  Future<void> addItemsBatch(List<ItemModel> items) async {
    try {
      final batch = _firestore.batch();

      for (final item in items) {
        final docRef = _itemsCollection.doc(item.id);
        batch.set(docRef, item.toFirestore(), SetOptions(merge: true));
      }

      await batch.commit();

      // 캐시 무효화
      _invalidateItemsCache();
    } on FirebaseException catch (e) {
      throw StateError('아이템 배치 추가 실패: ${e.message}');
    } catch (e) {
      throw StateError('아이템 배치 추가 중 오류: ${e.toString()}');
    }
  }

  /// items 캐시 무효화
  void _invalidateItemsCache() {
    _allItemsCache = null;
    _allItemsCacheTimestamp = null;
  }

  /// 전체 아이템 스트림 (실시간 - 조심해서 사용)
  Stream<List<ItemModel>> watchAllItems() {
    return _itemsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    });
  }

  /// 초기 Mock 아이템을 Firestore에 추가 (개발용)
  ///
  /// - items 컬렉션이 비어있을 때만 실행
  /// - 앱 최초 실행 시 호출하여 초기 데이터 생성
  ///
  /// 에러 처리:
  /// - FirebaseException: Firestore 조회/쓰기 실패
  Future<void> ensureInitialItems() async {
    try {
      // 아이템이 이미 있는지 확인
      final snapshot = await _itemsCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // 이미 아이템이 있음
      }

      // Mock 아이템 추가
      await addItemsBatch(MockItems.items);
    } catch (e) {
      // 에러 무시 (앱 실행은 계속)
    }
  }
}
