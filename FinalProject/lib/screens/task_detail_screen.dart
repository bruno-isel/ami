import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  String? _locationName;
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
    _locationName = task.locationName;
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
      locationName: _locationName,
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
      // Try last known first — faster and works in simulator
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        String? name;
        try {
          final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
            'lat': pos.latitude.toString(),
            'lon': pos.longitude.toString(),
            'format': 'json',
          });
          final resp = await http.get(uri,
              headers: {'User-Agent': 'VoiceTask/1.0 (student project)'});
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          name = _shortName(data['display_name'] as String? ?? '');
        } catch (_) {}
        setState(() {
          _lat = pos!.latitude;
          _lng = pos.longitude;
          _locationName = name;
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _searchLocation() async {
    final result = await showModalBottomSheet<({double lat, double lng, String name})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _LocationSearchSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _locationName = result.name;
      _dirty = true;
    });
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
                      if (!v) { _lat = null; _lng = null; _locationName = null; }
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (_lat != null)
                              TextButton(
                                onPressed: () => setState(() {
                                  _lat = null;
                                  _lng = null;
                                  _locationName = null;
                                  _dirty = true;
                                }),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                                child: const Text('Clear'),
                              ),
                            TextButton.icon(
                              onPressed: _searchLocation,
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Search'),
                              style: TextButton.styleFrom(
                                  foregroundColor: kPrimaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                            ),
                            TextButton.icon(
                              onPressed: _loadingLocation ? null : _fetchLocation,
                              icon: _loadingLocation
                                  ? const SizedBox(
                                      width: 14, height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location, size: 16),
                              label: const Text('Current'),
                              style: TextButton.styleFrom(
                                  foregroundColor: kPrimaryBlue,
                                  padding: const EdgeInsets.symmetric(horizontal: 8)),
                            ),
                          ],
                        ),
                        if (_lat != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text(
                              _locationName ?? '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text('No location set',
                                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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

String _shortName(String displayName) {
  if (displayName.isEmpty) return displayName;
  return displayName.split(',').take(3).map((s) => s.trim()).join(', ');
}

class _NominatimResult {
  final String displayName;
  final double lat;
  final double lng;
  const _NominatimResult(this.displayName, this.lat, this.lng);
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _ctrl = TextEditingController();
  List<_NominatimResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _ctrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _loading = true; _error = null; _results = []; });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
        'countrycodes': 'pt',
      });
      final response = await http.get(uri,
          headers: {'User-Agent': 'VoiceTask/1.0 (student project)'});
      final data = jsonDecode(response.body) as List;
      if (data.isEmpty) {
        setState(() => _error = 'No results found for "$query"');
        return;
      }
      setState(() {
        _results = data.map((item) => _NominatimResult(
          item['display_name'] as String,
          double.parse(item['lat'] as String),
          double.parse(item['lon'] as String),
        )).toList();
      });
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ..._results.map((r) => ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(r.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                    '${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(context, (lat: r.lat, lng: r.lng, name: _shortName(r.displayName))),
                contentPadding: EdgeInsets.zero,
              )),
          if (_results.isEmpty && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Type a place name and tap search',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
