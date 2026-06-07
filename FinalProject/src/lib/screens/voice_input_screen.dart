import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../app_state.dart';
import '../routes.dart';
import '../utils/constants.dart';
import '../utils/haptics.dart';

class VoiceInputScreen extends StatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  State<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends State<VoiceInputScreen>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  bool _speechAvailable = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _textCtrl = TextEditingController();
  String _accumulated = '';
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  DateTime? _lastShakeTime;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() => setState(() {}));
    _accelSub = userAccelerometerEventStream().listen(_onAccelerometer);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _speech.stop();
    super.dispose();
  }

  void _onAccelerometer(UserAccelerometerEvent e) {
    final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (magnitude < kShakeThreshold) return;
    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!).inMilliseconds < kShakeWindowMs) return;
    _lastShakeTime = now;
    _clearAndRetry();
  }

  Future<void> _clearAndRetry() async {
    await _speech.stop();
    final state = context.read<AppState>();
    state.stopListening();
    state.updateTranscription('');
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    _accumulated = '';
    _textCtrl.clear();
    hapticHeavy();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done') {
          final state = context.read<AppState>();
          if (state.isListening) _onSpeechDone(state);
        }
      },
      onError: (e) {
        if (!mounted) return;
        final state = context.read<AppState>();
        if (state.isListening) _onSpeechDone(state);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) return;
    final state = context.read<AppState>();
    hapticMedium();
    state.startListening();
    _pulseCtrl.repeat(reverse: true);
    _accumulated = _textCtrl.text.trim();
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        final combined = _accumulated.isEmpty ? words : '$_accumulated $words';
        _textCtrl.text = combined;
        state.updateTranscription(combined);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'pt_PT',
      ),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    final state = context.read<AppState>();
    _onSpeechDone(state);
  }

  void _onSpeechDone(AppState state) {
    if (!state.isListening) return;
    hapticLight();
    state.stopListening();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    if (mounted) setState(() {});
  }

  void _confirm(AppState state) {
    state.updateTranscription(_textCtrl.text.trim());
    state.buildDraftFromTranscription();
    hapticMedium();
    Navigator.pushReplacementNamed(context, Routes.confirmTask);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isListening = state.isListening;
    final hasText = _textCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _speech.stop();
            state.stopListening();
            Navigator.pop(context);
          },
        ),
        title: const Text('New Task',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Status label
            Text(
              isListening
                  ? 'Listening...'
                  : hasText
                      ? 'Tap mic to re-record'
                      : _speechAvailable
                          ? 'Tap the mic to speak'
                          : 'Speech recognition unavailable',
              style: TextStyle(
                fontSize: 16,
                color: isListening ? kPrimaryBlue : Colors.grey[500],
                fontWeight:
                    isListening ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 48),

            // Mic button with pulse animation
            GestureDetector(
              onTap: isListening ? _stopListening : _startListening,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: isListening ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: kAnimDuration,
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isListening ? kPrimaryBlue : Colors.grey[100],
                    boxShadow: isListening
                        ? [
                            BoxShadow(
                              color: kPrimaryBlue.withValues(alpha: 0.35),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isListening ? Icons.stop : Icons.mic,
                    size: 44,
                    color: isListening ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tap-to-stop hint
            AnimatedOpacity(
              opacity: isListening ? 1.0 : 0.0,
              duration: kAnimDuration,
              child: Text(
                'Tap to stop',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 32),

            // Transcription box
            AnimatedOpacity(
              opacity: hasText || isListening ? 1.0 : 0.0,
              duration: kAnimDuration,
              child: TextField(
                controller: _textCtrl,
                enabled: !isListening,
                maxLines: null,
                style: const TextStyle(fontSize: 17, height: 1.5),
                decoration: InputDecoration(
                  hintText: '...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: kPrimaryBlue, width: 1.5),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: kPrimaryBlue.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Continue button — appears only when there's text and not listening
            AnimatedOpacity(
              opacity: hasText && !isListening ? 1.0 : 0.0,
              duration: kAnimDuration,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: hasText && !isListening
                        ? () => _confirm(state)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
