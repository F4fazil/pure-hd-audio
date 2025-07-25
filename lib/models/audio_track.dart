class AudioTrack {
  final String title;
  final String url;
  final String? artist;
  final String? album;
  final Duration? duration;
  final String category; // 'meditation' or 'upbeat'

  AudioTrack({
    required this.title,
    required this.url,
    required this.category,
    this.artist,
    this.album,
    this.duration,
  });

  @override
  String toString() => title;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioTrack && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}