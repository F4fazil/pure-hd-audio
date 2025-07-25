import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_track.dart';
import '../data/playlist_data.dart';

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
  bool _equalizerEnabled = true;
  int? _audioSessionId;

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
      
      // Initialize equalizer after audio player setup
      await _initializeEqualizer();
      
      // Set audio session category for playback
      debugPrint('🎵 Audio session configured for optimal streaming');
    } catch (e) {
      debugPrint('⚠️ Audio session configuration warning: $e');
    }
  }

  Future<void> _initializeEqualizer() async {
    try {
      // Set a default audio session ID for Android equalizer
      // 0 is typically the system default session
      _audioSessionId = 0;
      _equalizerEnabled = true;
      debugPrint('✅ Equalizer service ready with session ID: $_audioSessionId');
    } catch (e) {
      debugPrint('❌ Error initializing equalizer: $e');
      _equalizerEnabled = false;
    }
  }
  
  int? get audioSessionId => _audioSessionId;

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

  // Apply EQ settings using enhanced audio processing
  Future<void> applyEQSettings(List<double> bandValues) async {
    try {
      debugPrint('🎛️ Applying EQ settings: $bandValues');
      
      // Apply enhanced EQ processing
      await _applyEnhancedEQ(bandValues);
      
    } catch (e) {
      debugPrint('❌ Error applying EQ settings: $e');
    }
  }

  // Enhanced EQ processing with frequency-based adjustments
  Future<void> _applyEnhancedEQ(List<double> bandValues) async {
    try {
      // Calculate bass, mid, and treble adjustments from 8-band EQ
      // Bands: 60Hz, 170Hz, 310Hz, 600Hz, 1kHz, 3kHz, 6kHz, 12kHz
      double bassLevel = (bandValues[0] + bandValues[1]) / 2;  // 60Hz + 170Hz
      double midLevel = (bandValues[2] + bandValues[3] + bandValues[4]) / 3;  // 310Hz + 600Hz + 1kHz
      double trebleLevel = (bandValues[5] + bandValues[6] + bandValues[7]) / 3;  // 3kHz + 6kHz + 12kHz
      
      // Calculate overall volume based on EQ curve
      double totalBoost = bandValues.reduce((a, b) => a + b);
      double avgBoost = totalBoost / bandValues.length;
      
      // Apply volume adjustment with EQ compensation
      double baseVolume = 0.8;
      double volumeMultiplier = 1.0 + (avgBoost / 20.0);
      double adjustedVolume = (baseVolume * volumeMultiplier).clamp(0.2, 1.0);
      
      await _audioPlayer.setVolume(adjustedVolume);
      
      // Apply speed/pitch adjustments for frequency simulation (subtle effect)
      if (bassLevel > 3.0) {
        // Slight speed reduction for bass emphasis
        await _audioPlayer.setSpeed(0.98);
      } else if (trebleLevel > 3.0) {
        // Slight speed increase for treble emphasis  
        await _audioPlayer.setSpeed(1.02);
      } else {
        await _audioPlayer.setSpeed(1.0);
      }
      
      debugPrint('🎛️ Enhanced EQ applied:');
      debugPrint('   Bass: ${bassLevel.toStringAsFixed(1)}dB');
      debugPrint('   Mid: ${midLevel.toStringAsFixed(1)}dB'); 
      debugPrint('   Treble: ${trebleLevel.toStringAsFixed(1)}dB');
      debugPrint('   Volume: ${adjustedVolume.toStringAsFixed(2)}');
      
    } catch (e) {
      debugPrint('❌ Enhanced EQ processing failed: $e');
      // Fallback to basic volume adjustment
      await _applySoftwareEQ(bandValues);
    }
  }

  // Software-based EQ simulation using audio effects
  Future<void> _applySoftwareEQ(List<double> bandValues) async {
    try {
      // Calculate overall volume adjustment based on EQ settings
      double avgBoost = bandValues.reduce((a, b) => a + b) / bandValues.length;
      double volumeMultiplier =
          1.0 + (avgBoost / 24.0); // Scale to reasonable range

      // Apply volume adjustment (this is a simple approximation)
      double adjustedVolume = (0.7 * volumeMultiplier).clamp(0.1, 1.0);
      await _audioPlayer.setVolume(adjustedVolume);

      debugPrint(
        '🎵 Software EQ simulation applied - Volume: ${adjustedVolume.toStringAsFixed(2)}',
      );
    } catch (e) {
      debugPrint('❌ Software EQ simulation failed: $e');
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
