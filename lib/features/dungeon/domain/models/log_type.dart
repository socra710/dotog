/// 전투 로그 타입
enum LogType {
  combat('전투', 'combat'),
  damage('피해', 'damage'),
  loot('전리품', 'loot'),
  event('이벤트', 'event'),
  system('시스템', 'system');

  const LogType(this.label, this.code);

  final String label;
  final String code;
}
