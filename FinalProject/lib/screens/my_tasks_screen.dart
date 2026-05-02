import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_state.dart';
import '../models/task.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    state.currentScreen = 'my_tasks';

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
            icon: Icon(
              _showCompleted ? Icons.visibility_off : Icons.check_circle_outline,
              color: _showCompleted ? kPrimaryBlue : Colors.grey,
            ),
            tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
            onPressed: () {
              setState(() => _showCompleted = !_showCompleted);
              state.addLog('toggle_completed_filter',
                  meta: {'show': _showCompleted});
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              state.addLog('nav_to_lists');
              // Navigator.pushNamed(context, Routes.myLists); — Week 2
            },
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
                          _showUndoSnackbar(context, state);
                        },
                        onTap: () {
                          state.addLog('task_open',
                              meta: {'taskId': task.id});
                          // Navigator.pushNamed — Task Detail, Week 2
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          state.addLog('voice_fab_tap', modality: 'touch');
          // Navigator.pushNamed(context, Routes.voiceInput); — Week 3
        },
        backgroundColor: kPrimaryBlue,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text('New task', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showUndoSnackbar(BuildContext context, AppState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Task deleted'),
        duration: kUndoTimeout,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => state.undoLastCreate(),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  final String activeFilter;
  const _FilterTabs({required this.activeFilter});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    const tabs = [
      ('all', 'All'),
      (kWorkListId, 'Work'),
      (kPersonalListId, 'Personal'),
    ];
    return Padding(
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
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
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
