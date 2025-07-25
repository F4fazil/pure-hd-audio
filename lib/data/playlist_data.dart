import '../models/audio_track.dart';

class PlaylistData {
  static List<AudioTrack> get meditationTracks => [
    AudioTrack(
      title: 'Alpha Music',
      url: 'https://silsyst.com/432hz_audio/meditation/01.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Breathing',
      url: 'https://silsyst.com/432hz_audio/meditation/02.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Heaven On Heart',
      url: 'https://silsyst.com/432hz_audio/meditation/03.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Love 432',
      url: 'https://silsyst.com/432hz_audio/meditation/04.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Meditation',
      url: 'https://silsyst.com/432hz_audio/meditation/05.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Morning Drums',
      url: 'https://silsyst.com/432hz_audio/meditation/06.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Nirvana',
      url: 'https://silsyst.com/432hz_audio/meditation/07.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Seven Chakras',
      url: 'https://silsyst.com/432hz_audio/meditation/08.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Sleeping',
      url: 'https://silsyst.com/432hz_audio/meditation/09.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
    AudioTrack(
      title: 'Welcome To 5D',
      url: 'https://silsyst.com/432hz_audio/meditation/10.mp3',
      category: 'meditation',
      artist: 'Silentsystem',
      album: '432Hz Meditation Collection',
    ),
  ];

  static List<AudioTrack> get upbeatTracks => [
    AudioTrack(
      title: 'Adventure',
      url: 'https://silsyst.com/432hz_audio/upbeat/01.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Autoverse',
      url: 'https://silsyst.com/432hz_audio/upbeat/02.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Bullet',
      url: 'https://silsyst.com/432hz_audio/upbeat/03.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Desert Shine',
      url: 'https://silsyst.com/432hz_audio/upbeat/04.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Fusion',
      url: 'https://silsyst.com/432hz_audio/upbeat/05.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Large Scale',
      url: 'https://silsyst.com/432hz_audio/upbeat/06.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Projection',
      url: 'https://silsyst.com/432hz_audio/upbeat/07.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Silent North',
      url: 'https://silsyst.com/432hz_audio/upbeat/08.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Tribe Up',
      url: 'https://silsyst.com/432hz_audio/upbeat/09.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
    AudioTrack(
      title: 'Whistle',
      url: 'https://silsyst.com/432hz_audio/upbeat/10.mp3',
      category: 'upbeat',
      artist: 'Silentsystem',
      album: '432Hz Upbeat Collection',
    ),
  ];

  static List<AudioTrack> get allTracks => [
    ...meditationTracks,
    ...upbeatTracks,
  ];
}
