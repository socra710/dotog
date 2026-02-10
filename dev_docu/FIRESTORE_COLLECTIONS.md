# Firestore 컬렉션 구조

## 개요

DOTOG 앱의 Firestore 데이터베이스 컬렉션 구조를 정의합니다.

## 컬렉션

### 1. `users` - 유저 정보

로그인한 유저의 기본 정보를 저장합니다.

**문서 ID**: Firebase Auth UID

**필드**:

| 필드명        | 타입      | 필수 | 설명               |
| ------------- | --------- | ---- | ------------------ |
| `email`       | string    | ✓    | 유저 이메일        |
| `displayName` | string    |      | 유저 표시 이름     |
| `photoURL`    | string    |      | 프로필 사진 URL    |
| `createdAt`   | timestamp | ✓    | 가입 시간          |
| `lastLoginAt` | timestamp | ✓    | 마지막 로그인 시간 |
| `fcmToken`    | string    |      | FCM 푸시 알림 토큰 |

**인덱스**: 없음 (단순 조회만 사용)

**보안 규칙**:

```javascript
match /users/{userId} {
  // 본인만 읽기/쓰기 가능
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**예시 문서**:

```json
{
  "email": "user@example.com",
  "displayName": "홍길동",
  "photoURL": "https://lh3.googleusercontent.com/...",
  "createdAt": "2026-02-10T10:30:00Z",
  "lastLoginAt": "2026-02-10T14:25:00Z",
  "fcmToken": "eXample_FCM_T0ken..."
}
```

---

### 2. `players` - 게임 플레이어 데이터 (예정)

게임 진행도 및 플레이어 상태를 저장합니다.

**문서 ID**: Firebase Auth UID (users와 동일)

**필드 (예정)**:

| 필드명           | 타입      | 필수 | 설명                             |
| ---------------- | --------- | ---- | -------------------------------- |
| `currentHp`      | number    | ✓    | 현재 HP                          |
| `maxHp`          | number    | ✓    | 최대 HP                          |
| `attack`         | number    | ✓    | 공격력                           |
| `defense`        | number    | ✓    | 방어력                           |
| `luck`           | number    | ✓    | 행운                             |
| `runes`          | number    | ✓    | 룬 (게임 화폐)                   |
| `level`          | number    | ✓    | 레벨                             |
| `currentFloor`   | number    | ✓    | 현재 던전 층수                   |
| `inventory`      | array     | ✓    | 보유 아이템 ID 목록              |
| `collectedItems` | array     | ✓    | 수집한 아이템 ID 목록 (코덱스용) |
| `updatedAt`      | timestamp | ✓    | 마지막 업데이트 시간             |

---

### 3. `items` - 아이템/아티팩트 정의 (예정)

게임 내 아이템 마스터 데이터입니다.

**문서 ID**: 아이템 고유 ID (예: "ancient_sword_001")

**필드 (예정)**:

| 필드명         | 타입   | 필수 | 설명                             |
| -------------- | ------ | ---- | -------------------------------- |
| `name`         | string | ✓    | 아이템 이름                      |
| `description`  | string | ✓    | 아이템 설명                      |
| `rarity`       | string | ✓    | 희귀도 (common, rare, legendary) |
| `attackBonus`  | number |      | 공격력 보너스                    |
| `defenseBonus` | number |      | 방어력 보너스                    |
| `luckBonus`    | number |      | 행운 보너스                      |
| `iconUrl`      | string |      | 아이템 아이콘 URL                |

---

## 사용 예시

### 유저 생성/업데이트 (로그인 시)

```dart
final firestoreService = FirestoreService();
final firebaseUser = FirebaseAuth.instance.currentUser!;

// 로그인 시 자동으로 Firestore에 저장
final userData = await firestoreService.createOrUpdateUser(firebaseUser);
```

### 유저 정보 조회

```dart
final userData = await firestoreService.getUser(uid);
print('마지막 로그인: ${userData?.lastLoginAt}');
```

### FCM 토큰 업데이트

```dart
// auth_provider를 통해
final authNotifier = ref.read(authProvider.notifier);
await authNotifier.updateFcmToken('new_fcm_token_here');
```

### 실시간 유저 정보 구독

```dart
firestoreService.watchUser(uid).listen((userData) {
  if (userData != null) {
    print('유저 업데이트: ${userData.displayName}');
  }
});
```

---

## 보안 고려사항

1. **인증 필수**: 모든 컬렉션 접근은 Firebase Auth 인증 필요
2. **사용자별 격리**: 유저는 본인 문서만 읽기/쓰기 가능
3. **서버 타임스탬프**: `createdAt`, `lastLoginAt`은 서버 시간 사용
4. **FCM 토큰**: 보안 토큰이므로 본인만 접근 가능

---

## 마이그레이션 계획

현재는 `users` 컬렉션만 구현되어 있습니다. 향후 게임 데이터를 Firestore로 이전할 때:

1. `players` 컬렉션에 게임 진행도 저장
2. `items` 컬렉션에 아이템 마스터 데이터 저장
3. 로컬 mock 데이터를 점진적으로 Firestore로 마이그레이션
