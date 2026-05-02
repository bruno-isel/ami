import 'package:flutter/material.dart';

class TaskList {
  final String id;
  String name;
  int colorValue;
  final DateTime createdAt;

  TaskList({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });

  Color get color => Color(colorValue);
}
