import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/log_event.dart';

Future<void> exportLogCsv(List<LogEvent> events) async {
  final buffer = StringBuffer()..write(LogEvent.csvHeader());
  for (final e in events) {
    buffer.writeln(e.toCsvRow().join(','));
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/voicetask_log.csv');
  await file.writeAsString(buffer.toString());
  await Share.shareXFiles(
    [XFile(file.path)],
    subject: 'VoiceTask interaction log',
  );
}
