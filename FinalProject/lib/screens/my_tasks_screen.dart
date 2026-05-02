import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/constants.dart';

class MyTasksScreen extends StatelessWidget {
  const MyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Tasks',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {}, // My Lists — Week 2
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterTabs(activeFilter: state.activeTabFilter),
          Expanded(
            child: state.filteredTasks.isEmpty
                ? const Center(
                    child: Text('No tasks yet. Tap the mic to add one!'))
                : ListView.builder(
                    itemCount: state.filteredTasks.length,
                    itemBuilder: (_, i) {
                      final task = state.filteredTasks[i];
                      return ListTile(
                        leading: Checkbox(
                          value: task.completed,
                          onChanged: (_) => state.toggleComplete(task.id),
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const _HintBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Voice input — Week 3
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
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80, top: 4),
      child: Text(
        kHintBarText,
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        textAlign: TextAlign.center,
      ),
    );
  }
}
