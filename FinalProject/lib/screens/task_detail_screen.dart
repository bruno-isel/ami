import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime? _dueDate;
  late String _listId;
  bool _gpsReminder = false;
  double? _lat;
  double? _lng;
  bool _dirty = false;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    final task = context.read<AppState>().tasks.firstWhere((t) => t.id == widget.taskId);
    _titleCtrl = TextEditingController(text: task.title);
    _descCtrl = TextEditingController(text: task.description ?? '');
    _dueDate = task.dueDate;
    _listId = task.listId;
    _gpsReminder = task.gpsReminder;
    _lat = task.lat;
    _lng = task.lng;
    _titleCtrl.addListener(_onChanged);
    _descCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() => _dirty = true);

  void _save(AppState state) {
    final task = state.tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null) return;
    final desc = _descCtrl.text.trim();
    state.updateTask(widget.taskId, task.copyWith(
      title: _titleCtrl.text.trim(),
      description: desc.isEmpty ? null : desc,
      dueDate: _dueDate,
      listId: _listId,
      gpsReminder: _gpsReminder,
      lat: _lat,
      lng: _lng,
    ));
    state.addLog('task_edited', meta: {'taskId': widget.taskId});
    hapticLight();
    setState(() => _dirty = false);
  }

  Future<void> _pickDate(AppState state) async {
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
      _dueDate = DateTime(date.year, date.month, date.day,
          time?.hour ?? 9, time?.minute ?? 0);
      _dirty = true;
    });
    state.addLog('task_date_picked', meta: {'taskId': widget.taskId});
  }

  Future<void> _fetchLocation() async {
    setState(() => _loadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _dirty = true;
      });
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _confirmDelete(AppState state) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
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
    );
    if (confirmed != true) return;
    hapticHeavy();
    state.deleteTask(widget.taskId);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    state.currentScreen = 'task_detail';
    final task = state.tasks.where((t) => t.id == widget.taskId).firstOrNull;
    if (task == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Task Detail',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (_dirty)
            TextButton(
              onPressed: () => _save(state),
              child: const Text('Save',
                  style: TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Due date
          InkWell(
            onTap: () => _pickDate(state),
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
                    _dueDate == null ? 'No due date' : _formatDate(_dueDate!),
                    style: TextStyle(
                      fontSize: 15,
                      color: _dueDate == null ? Colors.grey[500] : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() { _dueDate = null; _dirty = true; }),
                      child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // List selector
          const Text('List', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ListChip(
                label: 'Work',
                color: kCategoryWork,
                selected: _listId == kWorkListId,
                onTap: () => setState(() { _listId = kWorkListId; _dirty = true; }),
              ),
              const SizedBox(width: 10),
              _ListChip(
                label: 'Personal',
                color: kCategoryPersonal,
                selected: _listId == kPersonalListId,
                onTap: () => setState(() { _listId = kPersonalListId; _dirty = true; }),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // GPS reminder
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Location reminder',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Remind me when I arrive here',
                      style: TextStyle(fontSize: 12)),
                  value: _gpsReminder,
                  activeColor: kPrimaryBlue,
                  onChanged: (v) {
                    setState(() {
                      _gpsReminder = v;
                      if (!v) { _lat = null; _lng = null; }
                      _dirty = true;
                    });
                    state.addLog('gps_reminder_toggle',
                        meta: {'taskId': widget.taskId, 'enabled': v});
                  },
                  secondary: Icon(
                    Icons.location_on,
                    color: _gpsReminder ? kPrimaryBlue : Colors.grey[400],
                  ),
                ),
                if (_gpsReminder) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _lat != null
                                ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                : 'No location set',
                            style: TextStyle(
                              fontSize: 13,
                              color: _lat != null ? Colors.black87 : Colors.grey[500],
                            ),
                          ),
                        ),
                        if (_lat != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _lat = null;
                              _lng = null;
                              _dirty = true;
                            }),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8)),
                            child: const Text('Clear'),
                          ),
                        TextButton.icon(
                          onPressed: _loadingLocation ? null : _fetchLocation,
                          icon: _loadingLocation
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(_lat != null ? 'Update' : 'Use current'),
                          style: TextButton.styleFrom(
                              foregroundColor: kPrimaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Delete
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(state),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete task', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]}, $h:$m';
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
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey[600],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
