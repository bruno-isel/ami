class Task {
  final String id;
  String title;
  DateTime? dueDate;
  String listId;
  bool completed;
  bool gpsReminder;
  double? lat;
  double? lng;
  final DateTime createdAt;
  int orderIndex;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    required this.listId,
    this.completed = false,
    this.gpsReminder = false,
    this.lat,
    this.lng,
    required this.createdAt,
    required this.orderIndex,
  });

  Task copyWith({
    String? title,
    DateTime? dueDate,
    String? listId,
    bool? completed,
    bool? gpsReminder,
    double? lat,
    double? lng,
    int? orderIndex,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      listId: listId ?? this.listId,
      completed: completed ?? this.completed,
      gpsReminder: gpsReminder ?? this.gpsReminder,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      createdAt: createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
