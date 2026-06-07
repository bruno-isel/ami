import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models/task.dart';
import 'models/task_list.dart';
import 'utils/constants.dart';

class AppState extends ChangeNotifier {
  final _uuid = const Uuid();

  List<Task> tasks = [];
  List<TaskList> lists = [];

  String activeTabFilter = 'all';
  String currentTranscription = '';
  bool isListening = false;
  Task? draftTask;
  Task? lastCreatedTask;

  AppState() {
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    lists = [
      TaskList(
        id: kWorkListId,
        name: 'Work',
        colorValue: kCategoryWork.value,
        createdAt: now,
      ),
      TaskList(
        id: kPersonalListId,
        name: 'Personal',
        colorValue: kCategoryPersonal.value,
        createdAt: now,
      ),
    ];
    tasks = [
      Task(
        id: _uuid.v4(),
        title: 'Buy milk',
        dueDate: now.copyWith(hour: 9, minute: 0, second: 0),
        listId: kPersonalListId,
        createdAt: now,
        orderIndex: 0,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Play football',
        dueDate: now.copyWith(hour: 18, minute: 0, second: 0),
        listId: kPersonalListId,
        createdAt: now,
        orderIndex: 1,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Send email to boss',
        dueDate: now.add(const Duration(days: 1)).copyWith(hour: 10, minute: 0, second: 0),
        listId: kWorkListId,
        createdAt: now,
        orderIndex: 2,
      ),
      Task(
        id: _uuid.v4(),
        title: 'Finish lab report',
        dueDate: now.add(const Duration(days: 3)).copyWith(hour: 23, minute: 59, second: 0),
        listId: kWorkListId,
        createdAt: now,
        orderIndex: 3,
      ),
    ];
  }

  // --- Filtering ---

  List<Task> get filteredTasks {
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (activeTabFilter == 'all') return sorted;
    return sorted.where((t) => t.listId == activeTabFilter).toList();
  }

  void setFilter(String filter) {
    activeTabFilter = filter;
    notifyListeners();
  }

  // --- Tasks ---

  void addTask(Task t) {
    tasks.add(t);
    lastCreatedTask = t;
    notifyListeners();
  }

  void toggleComplete(String id) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i] = tasks[i].copyWith(completed: !tasks[i].completed);
    notifyListeners();
  }

  void updateTask(String id, Task updated) {
    final i = tasks.indexWhere((t) => t.id == id);
    if (i < 0) return;
    tasks[i] = updated;
    notifyListeners();
  }

  void deleteTask(String id) {
    tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void reorderTask(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final visible = filteredTasks;
    final task = visible[oldIndex];
    final all = List<Task>.from(tasks)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    all.remove(task);
    final insertAt = newIndex < all.length ? newIndex : all.length;
    all.insert(insertAt, task);
    for (var i = 0; i < all.length; i++) {
      all[i].orderIndex = i;
    }
    notifyListeners();
  }

  void undoLastCreate() {
    if (lastCreatedTask == null) return;
    tasks.removeWhere((t) => t.id == lastCreatedTask!.id);
    lastCreatedTask = null;
    notifyListeners();
  }

  void deleteLastTask() {
    if (tasks.isEmpty) return;
    final last = List<Task>.from(tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    deleteTask(last.first.id);
  }

  // --- Voice flow ---

  void startListening() {
    isListening = true;
    currentTranscription = '';
    notifyListeners();
  }

  void stopListening() {
    isListening = false;
    notifyListeners();
  }

  void updateTranscription(String text) {
    currentTranscription = text;
    notifyListeners();
  }

  void buildDraftFromTranscription() {
    final text = currentTranscription.trim();
    if (text.isEmpty) return;
    draftTask = Task(
      id: _uuid.v4(),
      title: _extractTitle(text),
      dueDate: _extractDate(text),
      listId: kPersonalListId,
      createdAt: DateTime.now(),
      orderIndex: tasks.length,
    );
    notifyListeners();
  }

  void confirmDraft() {
    if (draftTask == null) return;
    addTask(draftTask!);
    draftTask = null;
  }

  // Naive NLP — handles Portuguese and English
  String _extractTitle(String text) {
    var title = text
        .replaceAll(RegExp(r'\bamanhã\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bhoje\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'\b(às|as|at) \d{1,2}(:\d{2})?\s*(am|pm|h)?\b',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) return text;
    return title[0].toUpperCase() + title.substring(1);
  }

  DateTime? _extractDate(String text) {
    final now = DateTime.now();
    final lower = text.toLowerCase();
    final (hour, minute) = _extractTime(text);
    if (lower.contains('amanhã') || lower.contains('tomorrow')) {
      final d = now.add(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day, hour, minute);
    }
    if (lower.contains('hoje') || lower.contains('today')) {
      return DateTime(now.year, now.month, now.day, hour, minute);
    }
    if (_hasTimeWord(text)) {
      return DateTime(now.year, now.month, now.day, hour, minute);
    }
    return null;
  }

  bool _hasTimeWord(String text) =>
      RegExp(r'\b(às|as|at) \d{1,2}', caseSensitive: false).hasMatch(text);

  (int, int) _extractTime(String text) {
    final match = RegExp(
            r'\b(?:às|as|at) (\d{1,2})(?::(\d{2}))?\s*(am|pm|h)?',
            caseSensitive: false)
        .firstMatch(text);
    if (match == null) return (9, 0);
    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toLowerCase();
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    return (hour, minute);
  }

  // --- Lists ---

  void addList(TaskList l) {
    lists.add(l);
    notifyListeners();
  }

  void deleteList(String id) {
    lists.removeWhere((l) => l.id == id);
    tasks.removeWhere((t) => t.listId == id);
    notifyListeners();
  }

  TaskList? listById(String id) {
    try {
      return lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
