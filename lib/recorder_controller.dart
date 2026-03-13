import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart' as just;
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audio_session/audio_session.dart';

import 'package:recorder/recorded_audio.dart';
import 'package:recorder/model.dart';

class RecorderController {
  final FlutterSoundRecorder recorder = FlutterSoundRecorder();
  //
  final ValueNotifier<bool> isRecording = ValueNotifier(false);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> isRewinding = ValueNotifier(false);
  final ValueNotifier<List<RecordedAudio>> audios = ValueNotifier([]);
  final recordingElapsed = ValueNotifier<Duration>(Duration.zero);
  DateTime? _recordingStartTime;
  Timer? _timer;
  //
  late just.AudioPlayer player;
  String currentPlayingPath = '';
  double _lastPlayVolume = 1.0;
  //
  late just.AudioPlayer _playerEffect;
  //

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
    ));
    await session.setActive(true);
    //
    await recorder.openRecorder();
    await _loadSavedRecordings();
    player = just.AudioPlayer();
    player.playerStateStream.listen((state) {
      if (state.processingState == just.ProcessingState.completed) {
        isPlaying.value = false;
      }
    });
    _playerEffect = just.AudioPlayer();
    await _playerEffect.setAsset('assets/sound/click.wav');
    //
    if (Model.vibrateEnabled && await Vibration.hasVibrator()) {
    }
  }

  Future<void> dispose() async {
    final session = await AudioSession.instance;
    await session.setActive(false);
    await recorder.closeRecorder();
    await player.dispose();
    await _playerEffect.dispose();
  }

  Future<void> _loadSavedRecordings() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = Directory(dir.path).listSync();
    files.sort((a, b) => a.path.compareTo(b.path));
    final List<RecordedAudio> loaded = [];
    for (var f in files) {
      if (f is File && (f.path.endsWith('.aac') || f.path.endsWith('.wav'))) {
        final stat = await f.stat();
        final duration = await getAudioDuration(f.path);
        final file = File(f.path);
        final bytes = await file.length();
        loaded.add(
          RecordedAudio(
            id: stat.modified.millisecondsSinceEpoch.toString(),
            path: f.path,
            createdAt: stat.modified,
            duration: duration,
            sizeBytes: bytes,
          ),
        );
      }
    }
    audios.value = loaded;
  }

  Future<void> _playClickSound() async {
    if (Model.soundEnabled) {
      await _playerEffect.setVolume(Model.soundVolume);
      await _playerEffect.seek(Duration.zero);
      await _playerEffect.play();
    }
    if (Model.vibrateEnabled && await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 20);
    }
  }

  Future<Duration> getAudioDuration(String path) async {
    final player = just.AudioPlayer();
    await player.setAudioSource(just.AudioSource.uri(Uri.file(path)));
    final duration = player.duration ?? Duration.zero;
    await player.dispose();
    return duration;
  }

  Future<void> setVolume(double volume) async {
    _lastPlayVolume = volume;
    await player.setVolume(volume);
  }

  Future<void> startRecording() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
    ));
    await session.setActive(true);
    //
    await _playClickSound();
    await Future.delayed(Duration(milliseconds: 300));
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    late String path;
    late Codec codec;
    if (Model.recordFormat == 'aac') {
      path = '${dir.path}/recording_$timestamp.aac';
      codec = Codec.aacADTS;
    } else {
      path = '${dir.path}/recording_$timestamp.wav';
      codec = Codec.pcm16WAV;
    }
    //
    isRecording.value = true;
    _recordingStartTime = DateTime.now();
    recordingElapsed.value = Duration.zero;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_recordingStartTime != null) {
        recordingElapsed.value =
            DateTime.now().difference(_recordingStartTime!);
      }
    });
    await recorder.startRecorder(toFile: path, codec: codec);
  }

  Future<void> stopRecording() async {
    _playClickSound();
    if (!isRecording.value) {
      return;
    }
    final path = await recorder.stopRecorder();
    isRecording.value = false;
    _timer?.cancel();
    _timer = null;
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
    ));
    await session.setActive(true);
    //
    if (path != null) {
      currentPlayingPath = path;
      final duration = await getAudioDuration(path);
      saveRecording(path, duration);
    }
  }

  Future<void> _restoreAudioSessionForPlayback() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
    ));
    await session.setActive(true);
  }

  Future<void> play(String path) async {
    _playClickSound();
    await _restoreAudioSessionForPlayback();
    await player.setVolume(_lastPlayVolume);
    //
    isPlaying.value = true;
    currentPlayingPath = path;
    await player.setAudioSource(just.AudioSource.uri(Uri.file(path)));
    await player.seek(Duration.zero);
    await player.play();
  }

  Future<void> playLatest() async {
    _playClickSound();
    if (currentPlayingPath.isEmpty) {
      return;
    }
    await _restoreAudioSessionForPlayback();
    await player.setVolume(_lastPlayVolume);
    //
    final file = File(currentPlayingPath);
    if (!await file.exists()) {
      currentPlayingPath = '';
      return;
    }
    await player.setAudioSource(
      just.AudioSource.uri(Uri.file(currentPlayingPath)),
    );
    isPlaying.value = true;
    await player.play();
  }

  Future<void> stopPlay() async {
    await player.stop();
    isPlaying.value = false;
  }

  Future<void> rewind() async {
    _playClickSound();
    isRewinding.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isRewinding.value = false;
  }

  Future<void> saveRecording(String path, Duration duration) async {
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }
    final bytes = await file.length();
    final newAudio = RecordedAudio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      createdAt: DateTime.now(),
      duration: duration,
      sizeBytes: bytes,
    );
    audios.value = [...audios.value, newAudio];
  }

  Future<void> deleteAudio(String id) async {
    final target = audios.value.firstWhere((a) => a.id == id);
    final file = File(target.path);
    if (await file.exists()) {
      await file.delete();
    }
    audios.value = audios.value.where((a) => a.id != id).toList();
    if (currentPlayingPath == target.path) {
      currentPlayingPath = '';
      isPlaying.value = false;
    }
  }

  Future<void> sendAudio(String id) async {
    final audio = audios.value.firstWhere((a) => a.id == id);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(audio.path)],
      ),
    );
  }

}
