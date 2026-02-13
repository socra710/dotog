# Firestore 연동 현황 및 마이그레이션 계획

## 🚨 현재 상황

### 파이어스토어 구조

| 컬렉션      | 상태      | 용도                          |
| ----------- | --------- | ----------------------------- |
| `users`     | ✅ 구현됨 | 유저 정보 (닉네임, 이메일 등) |
| `character` | ✅ 존재함 | 게임 데이터 (추정)            |
| `players`   | ❌ 없음   | 게임 플레이어 데이터 (계획)   |

### 메인화면 데이터 출처

- **토큰 10개**: `dungeonProvider` (로컬 메모리)
- **코덱스**: `dungeonProvider` (로컬 메모리)
- **룬 10개**: `dungeonProvider` (로컬 메모리)
- **플레이어 스탯**: `dungeonProvider` (로컬 메모리)

**결론**: 현재 Firestore 연동이 완전하지 않음 🔴

---

## 📋 필요한 작업

### 1단계: `character` 컬렉션 분석

```dart
// character 컬렉션의 실제 구조를 파악하세요
// 예시:
{
  uid: "user123",
  tokens: 10,
  codex: [...],
  runes: 10,
  playerStats: {...}
}
```

### 2단계: GameDataModel 매핑

```dart
// character 컬렉션 데이터를 GameDataModel로 변환
// firestore_service.dart의 watchGameData() 수정 필요
```

### 3단계: Firestore 연동

```dart
// homeScreen에서 gameDataProvider 활용
final gameData = ref.watch(gameDataProvider);
final tokens = gameData.value?.player.tokens ?? 0;
```

---

## 🔧 해결 방법

### 옵션 A: 기존 `character` 컬렉션 활용 (권장)

1. `FirestoreCollections.characters = 'character'` 추가
2. `firestore_service.dart`의 `_playerDoc(uid)` 수정
3. Character 데이터 스키마를 GameDataModel로 변환

### 옵션 B: 새로운 `players` 컬렉션 생성

1. Firestore에서 `players` 컬렉션 생성
2. `character` 데이터를 `players`로 마이그레이션
3. 현재 코드 그대로 사용

---

## ⚠️ 현재 문제

- `gameDataProvider`가 null을 반환함
- homeScreen에서 로컬 상태만 표시됨
- Firestore 데이터가 UI에 반영되지 않음

---

## 다음 단계

1. 파이어스토어 콘솔에서 `character` 컬렉션 구조 확인
2. 위 "해결 방법" 중 하나 선택
3. `GameDataModel.fromFirestore()` 수정
4. homeScreen 업데이트
