class Task {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  String listId;
  bool completed;
  bool gpsReminder;
  double? lat;
  double? lng;
  String? locationName;
  final DateTime createdAt;
  int orderIndex;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    required this.listId,
    this.completed = false,
    this.gpsReminder = false,
    this.lat,
    this.lng,
    this.locationName,
    required this.createdAt,
    required this.orderIndex,
  });

  Task copyWith({
    String? title,
    Object? description = _sentinel,
    Object? dueDate = _sentinel,
    String? listId,
    bool? completed,
    bool? gpsReminder,
    Object? lat = _sentinel,
    Object? lng = _sentinel,
    Object? locationName = _sentinel,
    int? orderIndex,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description == _sentinel ? this.description : description as String?,
      dueDate: dueDate == _sentinel ? this.dueDate : dueDate as DateTime?,
      listId: listId ?? this.listId,
      completed: completed ?? this.completed,
      gpsReminder: gpsReminder ?? this.gpsReminder,
      lat: lat == _sentinel ? this.lat : lat as double?,
      lng: lng == _sentinel ? this.lng : lng as double?,
      locationName: locationName == _sentinel ? this.locationName : locationName as String?,
      createdAt: createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

const Object _sentinel = Object();
