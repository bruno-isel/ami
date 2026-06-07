import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../app_state.dart';
import '../models/task_list.dart';
import '../utils/constants.dart';

const _kPresetColors = [
  Color(0xFF007AFF),
  Color(0xFFFF9500),
  Color(0xFF34C759),
  Color(0xFFFF3B30),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
  Color(0xFF5AC8FA),
  Color(0xFFFFCC00),
];

class MyListsScreen extends StatelessWidget {
  const MyListsScreen({super.key});

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    Color selected = _kPresetColors[2];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'List name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPrimaryBlue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Color', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _kPresetColors.map((c) {
                  final isSelected = c == selected;
                  return GestureDetector(
                    onTap: () => setLocal(() => selected = c),
                    child: AnimatedContainer(
                      duration: kAnimDuration,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black54, width: 2.5)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                context.read<AppState>().addList(TaskList(
                      id: const Uuid().v4(),
                      name: name,
                      colorValue: selected.value,
                      createdAt: DateTime.now(),
                    ));
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(backgroundColor: kPrimaryBlue),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lists = state.lists;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Lists',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: lists.isEmpty
          ? const Center(
              child: Text('No lists yet.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: lists.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 56),
              itemBuilder: (_, i) {
                final list = lists[i];
                final taskCount = state.tasks.where((t) => t.listId == list.id).length;
                return Dismissible(
                  key: ValueKey(list.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete list?'),
                      content: Text('All tasks in "${list.name}" will also be deleted.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => state.deleteList(list.id),
                  child: ListTile(
                    leading: CircleAvatar(radius: 12, backgroundColor: list.color),
                    title: Text(list.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('$taskCount task${taskCount == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 12)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: kPrimaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
