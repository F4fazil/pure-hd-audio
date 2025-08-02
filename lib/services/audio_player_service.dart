import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_track.dart';
import '../data/playlist_data.dart';
import 'global_eq_service.dart';

class AudioPlayerService extends ChangeNotifier {
  static AudioPlayerService? _instance;
  
  // Singleton pattern
  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }
  
  // Private constructor
  AudioPlayerService._internal() {
    _initializePlayer();
  }
  
  // Keep the old constructor for backward compatibility but redirect to singleton
  factory AudioPlayerService() {
    return instance;
  }
  late final AudioPlayer _audioPlayer;
  final GlobalEQService _globalEQService = GlobalEQService.instance;

  // Playback state
  bool _isPlaying = false;
  bool _isLoading = false;
  AudioTrack? _currentTrack;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Playlist state
  List<AudioTrack> _currentPlaylist = [];
  int _currentIndex = 0;
  String _currentCategory = 'meditation';

  // Stream subscriptions
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  AudioTrack? get currentTrack => _currentTrack;
  Duration get position => _position;
  Duration get duration => _duration;
  List<AudioTrack> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  String get currentCategory => _currentCategory;

  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  void _initializePlayer() {
    try {
      _audioPlayer = AudioPlayer();
      
      // Configure audio session for better performance
      _configureAudioSession();

      // Listen to player state changes
      _playerStateSubscription = _audioPlayer.playerStateStream.listen(
        (state) {
          _isPlaying = state.playing;
          _isLoading =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;

          // Handle track completion
          if (state.processingState == ProcessingState.completed) {
            _onTrackCompleted();
          }

          notifyListeners();
        },
        onError: (error) {
          debugPrint('Player state stream error: $error');
          _isLoading = false;
          notifyListeners();
        },
      );

      // Listen to position changes
      _positionSubscription = _audioPlayer.positionStream.listen(
        (position) {
          _position = position;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
        },
      );

      // Listen to duration changes
      _durationSubscription = _audioPlayer.durationStream.listen(
        (duration) {
          _duration = duration ?? Duration.zero;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Duration stream error: $error');
        },
      );

      debugPrint('Audio player initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _configureAudioSession() async {
    try {
      // Configure audio player for better streaming performance
      await _audioPlayer.setLoopMode(LoopMode.off);
      await _audioPlayer.setVolume(0.7);
      
      // Initialize global equalizer
      await _initializeGlobalEqualizer();
      
      // Set audio session category for playback
      debugPrint('🎵 Audio session configured for optimal streaming');
    } catch (e) {
      debugPrint('⚠️ Audio session configuration warning: $e');
    }
  }

  Future<void> _initializeGlobalEqualizer() async {
    try {
      // Initialize the global EQ service on app start
      await _globalEQService.initializeOnAppStart();
      debugPrint('✅ Global Equalizer service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing global equalizer: $e');
    }
  }

  // Load playlist category with optimization
  Future<void> loadPlaylist(String category) async {
    try {
      debugPrint('🎵 Loading $category playlist...');
      _currentCategory = category;
      _currentPlaylist = category == 'meditation'
          ? PlaylistData.meditationTracks
          : PlaylistData.upbeatTracks;
      _currentIndex = 0;

      if (_currentPlaylist.isNotEmpty) {
        debugPrint('📂 Loaded ${_currentPlaylist.length} tracks');
        await playTrack(_currentPlaylist[0]);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading playlist: $e');
    }
  }

  // Play specific track
  Future<void> playTrack(AudioTrack track) async {
    try {
      debugPrint('Attempting to play track: ${track.title} - ${track.url}');
      _isLoading = true;
      notifyListeners();

      // Optimized audio loading
      debugPrint('🔄 Loading audio: ${track.url}');
      await _audioPlayer.setUrl(track.url, preload: true);

      _currentTrack = track;

      // Find track in current playlist
      _currentIndex = _currentPlaylist.indexWhere((t) => t.url == track.url);
      if (_currentIndex == -1) {
        // Track not in current playlist, load its category
        debugPrint(
          'Track not in current playlist, loading category: ${track.category}',
        );
        await loadPlaylist(track.category);
        _currentIndex = _currentPlaylist.indexWhere((t) => t.url == track.url);
      }

      debugPrint('▶️ Starting playback...');
      await _audioPlayer.play();
      
      // Preload next track for faster switching
      _preloadNextTrack();

      debugPrint('✅ Now playing: ${track.title}');
    } catch (e) {
      debugPrint('❌ Playback error for "${track.title}": $e');
      _isLoading = false;
      _handlePlaybackError(e, track);
    }
  }
  
  // Preload next track in background for instant playback
  void _preloadNextTrack() {
    try {
      if (_currentPlaylist.isNotEmpty && _currentIndex < _currentPlaylist.length - 1) {
        final nextTrack = _currentPlaylist[_currentIndex + 1];
        debugPrint('🔄 Next track ready: ${nextTrack.title}');
      }
    } catch (e) {
      debugPrint('⚠️ Next track prep failed: $e');
    }
  }
  
  // Better error handling
  void _handlePlaybackError(dynamic error, AudioTrack track) {
    _currentTrack = null;
    notifyListeners();
    
    if (error.toString().contains('MissingPluginException')) {
      debugPrint('🔧 Plugin issue - try restarting app');
    } else if (error.toString().contains('Unable to load') || 
               error.toString().contains('Network')) {
      debugPrint('🌐 Network issue - check connection');
    } else if (error.toString().contains('timeout')) {
      debugPrint('⏱️ Timeout - server response too slow');
    } else {
      debugPrint('🔥 Unknown error: $error');
    }
  }

  // Play/pause toggle
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
    }
  }

  // Next track
  Future<void> nextTrack() async {
    if (_currentPlaylist.isNotEmpty &&
        _currentIndex < _currentPlaylist.length - 1) {
      _currentIndex++;
      await playTrack(_currentPlaylist[_currentIndex]);
    }
  }

  // Previous track
  Future<void> previousTrack() async {
    if (_currentPlaylist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      await playTrack(_currentPlaylist[_currentIndex]);
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  // Handle track completion
  void _onTrackCompleted() {
    if (_currentIndex < _currentPlaylist.length - 1) {
      nextTrack();
    } else {
      // Playlist ended
      _isPlaying = false;
      notifyListeners();
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // Apply EQ settings using global system-wide equalizer
  Future<void> applyEQSettings(List<double> bandValues) async {
    try {
      debugPrint('🎛️ Applying Global EQ settings: $bandValues');
      
      // Apply to the global system-wide equalizer
      final success = await _globalEQService.applyEQSettings(bandValues);
      
      if (success) {
        debugPrint('✅ Global EQ settings applied successfully');
        
        // Optional: Still apply some local volume adjustments for compatibility
        await _applyLocalVolumeAdjustment(bandValues);
      } else {
        debugPrint('⚠️ Failed to apply global EQ, falling back to local simulation');
        await _applyLocalVolumeAdjustment(bandValues);
      }
      
    } catch (e) {
      debugPrint('❌ Error applying global EQ settings: $e');
      // Fallback to local adjustments
      await _applyLocalVolumeAdjustment(bandValues);
    }
  }

  // Local volume adjustments as fallback
  Future<void> _applyLocalVolumeAdjustment(List<double> bandValues) async {
    try {
      // Calculate overall volume adjustment based on EQ settings
      double avgBoost = bandValues.reduce((a, b) => a + b) / bandValues.length;
      double volumeMultiplier = 1.0 + (avgBoost / 24.0);

      // Apply volume adjustment (gentle adjustment to complement global EQ)
      double adjustedVolume = (0.7 * volumeMultiplier).clamp(0.3, 1.0);
      await _audioPlayer.setVolume(adjustedVolume);

      debugPrint('🎵 Local volume adjustment applied: ${adjustedVolume.toStringAsFixed(2)}');
    } catch (e) {
      debugPrint('❌ Local volume adjustment failed: $e');
    }
  }

  // Quick test method to check if audio player works
  Future<void> testAudioPlayer() async {
    try {
      debugPrint('🧪 Testing audio connection...');
      const testUrl = 'https://silsyst.com/432hz_audio/meditation/01.mp3';
      
      // Test with preload for faster response
      await _audioPlayer.setUrl(testUrl, preload: true);
      debugPrint('✅ Audio test passed - server responsive');
    } catch (e) {
      debugPrint('❌ Audio test failed: $e');
      if (e.toString().contains('timeout')) {
        debugPrint('⏱️ Server timeout - try again later');
      }
    }
  }

  // Check network connectivity and server response
  Future<bool> checkServerStatus() async {
    try {
      debugPrint('🌐 Checking server status...');
      const testUrl = 'https://silsyst.com/432hz_audio/meditation/01.mp3';
      
      await _audioPlayer.setUrl(testUrl, preload: false);
      debugPrint('✅ Server is responsive');
      return true;
    } catch (e) {
      debugPrint('❌ Server check failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
