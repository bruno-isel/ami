import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../routes.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';
import '../widgets/location_search_sheet.dart';

class ConfirmTaskScreen extends StatefulWidget {
  const ConfirmTaskScreen({super.key});

  @override
  State<ConfirmTaskScreen> createState() => _ConfirmTaskScreenState();
}

class _ConfirmTaskScreenState extends State<ConfirmTaskScreen> {
  late TextEditingController _titleCtrl;
  DateTime? _dueDate;
  late String _listId;
  bool _gpsReminder = false;
  double? _lat;
  double? _lng;
  String? _locationName;
  bool _loadingLocation = false;

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
      gpsReminder: _gpsReminder,
      lat: _lat,
      lng: _lng,
      locationName: _locationName,
    );
    state.confirmDraft();
    hapticMedium();
    Navigator.pushReplacementNamed(context, Routes.taskCreated);
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
            const SnackBar(content: Text('Permissão de localização negada')),
          );
        }
        return;
      }
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
          name = locationShortName(data['display_name'] as String? ?? '');
        } catch (_) {}
        setState(() {
          _lat = pos!.latitude;
          _lng = pos.longitude;
          _locationName = name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível obter localização: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _searchLocation() async {
    final result =
        await showModalBottomSheet<({double lat, double lng, String name})>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const LocationSearchSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _lat = result.lat;
      _lng = result.lng;
      _locationName = result.name;
    });
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
            const SizedBox(height: 8),

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
                    title: const Text('Lembrete por localização',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Lembrar ao chegar a este local',
                        style: TextStyle(fontSize: 12)),
                    value: _gpsReminder,
                    activeColor: kPrimaryBlue,
                    secondary: Icon(Icons.location_on,
                        color: _gpsReminder ? kPrimaryBlue : Colors.grey[400]),
                    onChanged: (v) {
                      setState(() {
                        _gpsReminder = v;
                        if (!v) {
                          _lat = null;
                          _lng = null;
                          _locationName = null;
                        }
                      });
                    },
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
                                  }),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8)),
                                  child: const Text('Limpar'),
                                ),
                              TextButton.icon(
                                onPressed: _searchLocation,
                                icon: const Icon(Icons.search, size: 16),
                                label: const Text('Pesquisar'),
                                style: TextButton.styleFrom(
                                    foregroundColor: kPrimaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                              ),
                              TextButton.icon(
                                onPressed:
                                    _loadingLocation ? null : _fetchLocation,
                                icon: _loadingLocation
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2))
                                    : const Icon(Icons.my_location, size: 16),
                                label: const Text('Atual'),
                                style: TextButton.styleFrom(
                                    foregroundColor: kPrimaryBlue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8)),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Text(
                              _lat != null
                                  ? (_locationName ??
                                      '${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}')
                                  : 'Nenhum local definido',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _lat != null
                                      ? Colors.black87
                                      : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
