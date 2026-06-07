import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../app_state.dart';
import '../models/task.dart';
import '../routes.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  bool _showCompleted = false;
  bool _shakeEnabled = true;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  DateTime? _lastShakeTime;
  bool _shakeDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _accelSub = userAccelerometerEventStream().listen(_onAccelerometer);
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _onAccelerometer(UserAccelerometerEvent e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (!_shakeEnabled) return;
    if (magnitude < kShakeThreshold) return;

    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!).inMilliseconds < kShakeWindowMs) return;
    _lastShakeTime = now;

    if (_shakeDialogOpen) return;
    final state = context.read<AppState>();
    if (state.lastCreatedTask == null) return;

    hapticHeavy();
    _showShakeDialog(state);
  }

  Future<void> _showShakeDialog(AppState state) async {
    _shakeDialogOpen = true;
    final taskTitle = state.lastCreatedTask!.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Undo last task?'),
        content: Text('Remove "$taskTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    _shakeDialogOpen = false;
    if (confirmed == true) {
      hapticMedium();
      state.undoLastCreate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allFiltered = state.filteredTasks;
    final visible = _showCompleted
        ? allFiltered
        : allFiltered.where((t) => !t.completed).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Tasks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.grey),
            tooltip: 'My Lists',
            onPressed: () => Navigator.pushNamed(context, Routes.myLists),
          ),
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility_off : Icons.check_circle_outline,
              color: _showCompleted ? kPrimaryBlue : Colors.grey,
            ),
            tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'shake') {
                setState(() => _shakeEnabled = !_shakeEnabled);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'shake',
                child: Row(
                  children: [
                    Icon(
                      _shakeEnabled
                          ? Icons.vibration
                          : Icons.phonelink_erase,
                      color: _shakeEnabled ? kPrimaryBlue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_shakeEnabled
                        ? 'Shake to undo: on'
                        : 'Shake to undo: off'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const _HintBar(),
      body: Column(
        children: [
          _FilterTabs(activeFilter: state.activeTabFilter),
          Expanded(
            child: visible.isEmpty
                ? _EmptyState(showCompleted: _showCompleted)
                : ReorderableListView.builder(
                    itemCount: visible.length,
                    onReorder: (oldIndex, newIndex) {
                      hapticMedium();
                      state.reorderTask(oldIndex, newIndex);
                    },
                    itemBuilder: (_, i) {
                      final task = visible[i];
                      return _TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        listColor: state.listById(task.listId)?.color ??
                            kCategoryPersonal,
                        onComplete: () {
                          hapticMedium();
                          state.toggleComplete(task.id);
                        },
                        onDelete: () {
                          hapticHeavy();
                          state.deleteTask(task.id);
                        },
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routes.taskDetail,
                            arguments: task.id,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.voiceInput);
        },
        backgroundColor: kPrimaryBlue,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text('New task', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }


}

class _FilterTabs extends StatelessWidget {
  final String activeFilter;
  const _FilterTabs({required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final tabs = [
      ('all', 'All'),
      ...state.lists.map((l) => (l.id, l.name)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: tabs.map((tab) {
          final selected = activeFilter == tab.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(tab.$2),
              selected: selected,
              onSelected: (_) => state.setFilter(tab.$1),
              selectedColor: kPrimaryBlue,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  final Color listColor;
  final VoidCallback onComplete;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TaskTile({
    super.key,
    required this.task,
    required this.listColor,
    required this.onComplete,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: onComplete,
                child: AnimatedContainer(
                  duration: kAnimDuration,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.completed
                          ? Colors.green
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: task.completed
                        ? Colors.green
                        : Colors.transparent,
                  ),
                  child: task.completed
                      ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        _formatDate(task.dueDate!),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: listColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today, ${DateFormat.Hm().format(date)}';
    if (d == tomorrow) return 'Tomorrow, ${DateFormat.Hm().format(date)}';
    return DateFormat('EEE, HH:mm').format(date);
  }
}

class _EmptyState extends StatelessWidget {
  final bool showCompleted;
  const _EmptyState({required this.showCompleted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            showCompleted ? 'No completed tasks' : 'No tasks yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (!showCompleted)
            Text(
              'Tap the mic to add one',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        kHintBarText,
        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        textAlign: TextAlign.center,
      ),
    );
  }
}
