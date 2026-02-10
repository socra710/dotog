import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dungeon provider는 dungeon_provider.dart에 분리되어 있습니다
export 'dungeon_provider.dart';
export 'auth_provider.dart';

final appNameProvider = Provider<String>((ref) => 'DOTOG');
