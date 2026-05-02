class LogEvent {
  final DateTime timestamp;
  final String eventType;
  final String screen;
  final String inputModality;
  final Map<String, dynamic> meta;

  const LogEvent({
    required this.timestamp,
    required this.eventType,
    required this.screen,
    required this.inputModality,
    this.meta = const {},
  });

  List<String> toCsvRow() => [
        timestamp.toIso8601String(),
        eventType,
        screen,
        inputModality,
        meta.entries.map((e) => '${e.key}=${e.value}').join(';'),
      ];

  static String csvHeader() =>
      'timestamp,event_type,screen,input_modality,meta\n';
}
