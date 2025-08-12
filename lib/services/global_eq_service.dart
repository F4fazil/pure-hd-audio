import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GlobalEQService extends ChangeNotifier {
  static GlobalEQService? _instance;
  
  static GlobalEQService get instance {
    _instance ??= GlobalEQService._internal();
    return _instance!;
  }
  
  GlobalEQService._internal() {
    _initializeService();
  }
  
  factory GlobalEQService() {
    return instance;
  }

  static const MethodChannel _channel = MethodChannel('global_equalizer');
  
  bool _isServiceRunning = false;
  bool _isEQEnabled = false;
  Map<String, dynamic>? _equalizerInfo;
  
  // Getters
  bool get isServiceRunning => _isServiceRunning;
  bool get isEQEnabled => _isEQEnabled;
  Map<String, dynamic>? get equalizerInfo => _equalizerInfo;
  
  Future<void> _initializeService() async {
    try {
      debugPrint('🎛️ Initializing Global EQ Service...');
      
      // Check if EQ is already enabled
      await _checkEQStatus();
      
      // Get equalizer info
      await _getEqualizerInfo();
      
      debugPrint('✅ Global EQ Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Global EQ Service: $e');
    }
  }
  
  /// Start the global EQ service (foreground service)
  Future<bool> startGlobalEQ() async {
    try {
      debugPrint('🎛️ Starting Global EQ Service...');
      
      final result = await _channel.invokeMethod('startGlobalEQ');
      
      // Update service state based on actual result from native code
      _isServiceRunning = result == true;
      
      if (_isServiceRunning) {
        // Wait a moment for service to initialize
        await Future.delayed(Duration(milliseconds: 500));
        
        // Check status and get info
        await _checkEQStatus();
        await _getEqualizerInfo();
        
        debugPrint('✅ Global EQ Service started successfully');
      } else {
        debugPrint('❌ Global EQ Service failed to start');
      }
      
      notifyListeners();
      return _isServiceRunning;
    } catch (e) {
      debugPrint('❌ Error starting Global EQ Service: $e');
      _isServiceRunning = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Stop the global EQ service
  Future<bool> stopGlobalEQ() async {
    try {
      debugPrint('🎛️ Stopping Global EQ Service...');
      
      final result = await _channel.invokeMethod('stopGlobalEQ');
      _isServiceRunning = false;
      _isEQEnabled = false;
      
      notifyListeners();
      
      debugPrint('✅ Global EQ Service stopped: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error stopping Global EQ Service: $e');
      return false;
    }
  }
  
  /// Apply EQ settings to the global system-wide equalizer
  Future<bool> applyEQSettings(List<double> bandValues) async {
    try {
      debugPrint('🎛️ Applying global EQ settings: $bandValues');
      
      final result = await _channel.invokeMethod('applyEQSettings', {
        'bandValues': bandValues,
      });
      
      debugPrint('✅ Global EQ settings applied: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error applying global EQ settings: $e');
      return false;
    }
  }
  
  /// Enable or disable the global EQ
  Future<bool> setEQEnabled(bool enabled) async {
    try {
      debugPrint('🎛️ Setting Global EQ enabled: $enabled');
      
      final result = await _channel.invokeMethod('setEQEnabled', {
        'enabled': enabled,
      });
      
      _isEQEnabled = enabled;
      notifyListeners();
      
      debugPrint('✅ Global EQ enabled set: $result');
      return true;
    } catch (e) {
      debugPrint('❌ Error setting Global EQ enabled: $e');
      return false;
    }
  }
  
  /// Check if global EQ is currently enabled
  Future<void> _checkEQStatus() async {
    try {
      final enabled = await _channel.invokeMethod('isEQEnabled');
      _isEQEnabled = enabled ?? false;
      debugPrint('🎛️ Global EQ enabled status: $_isEQEnabled');
    } catch (e) {
      debugPrint('❌ Error checking EQ status: $e');
      _isEQEnabled = false;
    }
  }
  
  /// Get equalizer information (bands, frequencies, etc.)
  Future<void> _getEqualizerInfo() async {
    try {
      final info = await _channel.invokeMethod('getEqualizerInfo');
      _equalizerInfo = info != null ? Map<String, dynamic>.from(info) : null;
      
      if (_equalizerInfo != null) {
        debugPrint('🎛️ Equalizer Info:');
        debugPrint('   Enabled: ${_equalizerInfo!['enabled']}');
        debugPrint('   Bands: ${_equalizerInfo!['numberOfBands']}');
        debugPrint('   Range: ${_equalizerInfo!['bandLevelRange']}');
        debugPrint('   Frequencies: ${_equalizerInfo!['frequencies']}');
      }
    } catch (e) {
      debugPrint('❌ Error getting equalizer info: $e');
      _equalizerInfo = null;
    }
  }
  
  /// Get the number of EQ bands available
  int get numberOfBands {
    return _equalizerInfo?['numberOfBands'] ?? 8;
  }
  
  /// Get the frequency range for each band
  List<int> get frequencies {
    final freqs = _equalizerInfo?['frequencies'];
    if (freqs is List) {
      return freqs.cast<int>();
    }
    // Default 8-band frequencies if not available
    return [60, 170, 310, 600, 1000, 3000, 6000, 12000];
  }
  
  /// Get the band level range (min, max in milliBel)
  List<int> get bandLevelRange {
    final range = _equalizerInfo?['bandLevelRange'];
    if (range is List && range.length >= 2) {
      return [range[0], range[1]];
    }
    // Default range: -1200 to +1200 milliBel (-12dB to +12dB)
    return [-1200, 1200];
  }
  
  /// Convert frequencies to display labels
  List<String> get frequencyLabels {
    return frequencies.map((freq) {
      if (freq >= 1000) {
        return '${(freq / 1000).toStringAsFixed(freq % 1000 == 0 ? 0 : 1)}kHz';
      } else {
        return '${freq}Hz';
      }
    }).toList();
  }
  
  /// Refresh EQ status and info
  Future<void> refresh() async {
    await _checkEQStatus();
    await _getEqualizerInfo();
    notifyListeners();
  }
  
  /// Play test tone to verify EQ is working (iOS only)
  Future<bool> playTestTone({double frequency = 1000.0, double duration = 2.0}) async {
    try {
      debugPrint('🎵 Playing test tone: ${frequency}Hz for ${duration}s');
      
      final result = await _channel.invokeMethod('playTestTone', {
        'frequency': frequency,
        'duration': duration,
      });
      
      debugPrint('🎵 Test tone result: $result');
      return result == true;
    } catch (e) {
      debugPrint('❌ Error playing test tone: $e');
      return false;
    }
  }
  
  /// Initialize the global EQ when app starts
  Future<void> initializeOnAppStart() async {
    try {
      debugPrint('🎛️ Auto-starting Global EQ on app launch...');
      
      // Start the service automatically
      final started = await startGlobalEQ();
      
      if (started) {
        // Enable EQ by default
        await setEQEnabled(true);
        debugPrint('✅ Global EQ auto-started and enabled');
      } else {
        debugPrint('❌ Failed to auto-start Global EQ');
      }
    } catch (e) {
      debugPrint('❌ Error auto-starting Global EQ: $e');
    }
  }
  
  
  @override
  void dispose() {
    // Don't dispose the singleton service
    super.dispose();
  }
}