class RecordedAudio {
  final String id;
  final String path;
  final DateTime createdAt;
  final Duration duration;
  final int sizeBytes;

  RecordedAudio({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.duration,
    required this.sizeBytes,
  });
}
