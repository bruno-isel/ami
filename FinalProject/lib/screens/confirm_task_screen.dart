import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../routes.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class ConfirmTaskScreen extends StatefulWidget {
  const ConfirmTaskScreen({super.key});

  @override
  State<ConfirmTaskScreen> createState() => _ConfirmTaskScreenState();
}

class _ConfirmTaskScreenState extends State<ConfirmTaskScreen> {
  late TextEditingController _titleCtrl;
  DateTime? _dueDate;
  late String _listId;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AppState>().draftTask!;
    _titleCtrl = TextEditingController(text: draft.title);
    _dueDate = draft.dueDate;
    _listId = draft.listId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _confirm(AppState state) {
    final draft = state.draftTask!;
    state.draftTask = draft.copyWith(
      title: _titleCtrl.text.trim().isEmpty ? draft.title : _titleCtrl.text.trim(),
      dueDate: _dueDate,
      listId: _listId,
    );
    state.confirmDraft();
    hapticMedium();
    Navigator.pushReplacementNamed(context, Routes.taskCreated);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? now),
    );
    if (!mounted) return;
    setState(() {
      _dueDate = DateTime(
        date.year, date.month, date.day,
        time?.hour ?? 9, time?.minute ?? 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    state.currentScreen = 'confirm_task';

    if (state.draftTask == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => Navigator.popUntil(context, ModalRoute.withName(Routes.myTasks)));
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Confirm Task',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transcription hint
            Text('From your voice:',
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            const SizedBox(height: 4),
            Text(
              state.currentTranscription,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            // Title
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? 'No due date'
                          : DateFormat('EEE d MMM, HH:mm').format(_dueDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: _dueDate == null ? Colors.grey[500] : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List selector
            const Text('List', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ListChip(
                  label: 'Work',
                  color: kCategoryWork,
                  selected: _listId == kWorkListId,
                  onTap: () => setState(() => _listId = kWorkListId),
                ),
                const SizedBox(width: 10),
                _ListChip(
                  label: 'Personal',
                  color: kCategoryPersonal,
                  selected: _listId == kPersonalListId,
                  onTap: () => setState(() => _listId = kPersonalListId),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _confirm(state),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Task',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, ModalRoute.withName(Routes.myTasks)),
                child: Text('Cancel',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500])),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ListChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ListChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kAnimDuration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  color: selected ? color : Colors.grey[600],
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
