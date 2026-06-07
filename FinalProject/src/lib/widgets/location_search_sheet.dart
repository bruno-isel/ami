import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

String locationShortName(String displayName) {
  if (displayName.isEmpty) return displayName;
  return displayName.split(',').take(3).map((s) => s.trim()).join(', ');
}

class _NominatimResult {
  final String displayName;
  final double lat;
  final double lng;
  const _NominatimResult(this.displayName, this.lat, this.lng);
}

class LocationSearchSheet extends StatefulWidget {
  const LocationSearchSheet({super.key});

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
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
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '5',
        'addressdetails': '1',
        'countrycodes': 'pt',
      });
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'VoiceTask/1.0 (student project)'},
      );
      final data = jsonDecode(response.body) as List;
      if (data.isEmpty) {
        setState(() => _error = 'Sem resultados para "$query"');
        return;
      }
      setState(() {
        _results = data
            .map((item) => _NominatimResult(
                  item['display_name'] as String,
                  double.parse(item['lat'] as String),
                  double.parse(item['lon'] as String),
                ))
            .toList();
      });
    } catch (e) {
      setState(() => _error = 'Pesquisa falhou: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pesquisar local',
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
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
                title: Text(
                  r.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.pop(
                  context,
                  (
                    lat: r.lat,
                    lng: r.lng,
                    name: locationShortName(r.displayName)
                  ),
                ),
                contentPadding: EdgeInsets.zero,
              )),
          if (_results.isEmpty && !_loading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Escreve um local e toca em pesquisar',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
