import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../services/global_eq_service.dart';
import '../models/eq_preset.dart';

class EqualizerViewModel extends ChangeNotifier {
  bool _isEQOn = true;
  int _currentPresetIndex = 0;
  
  // 8-band EQ system loaded from JSON
  List<double> _bandValues = List.filled(8, 0.0); // -12dB to +12dB range (0 = no change)
  List<String> _frequencyLabels = [];
  List<EQPresetData> _presets = [];
  EQConfiguration? _eqConfig;

  // Services (singletons)
  final AudioPlayerService _audioPlayerService = AudioPlayerService.instance;
  final GlobalEQService _globalEQService = GlobalEQService.instance;

  // Getters
  bool get isEQOn => _isEQOn;
  int get currentPresetIndex => _currentPresetIndex;
  EQPresetData? get currentPreset => _presets.isNotEmpty ? _presets[_currentPresetIndex] : null;
  List<double> get bandValues => List.unmodifiable(_bandValues);
  List<String> get frequencyLabels => List.unmodifiable(_frequencyLabels);
  List<EQPresetData> get presets => List.unmodifiable(_presets);
  AudioPlayerService get audioPlayerService => _audioPlayerService;

  // Toggle EQ on/off
  void toggleEQ() async {
    _isEQOn = !_isEQOn;
    
    // Apply to global EQ service
    await _globalEQService.setEQEnabled(_isEQOn);
    
    // Also apply current settings to player
    await _applyEQToPlayer();
    
    notifyListeners();
  }

  // Initialize with JSON data
  Future<void> initialize() async {
    await _loadEQConfiguration();
    
    // Initialize global EQ service
    await _initializeGlobalEQ();
  }
  
  // Initialize global EQ service
  Future<void> _initializeGlobalEQ() async {
    try {
      // Ensure global EQ service is running
      if (!_globalEQService.isServiceRunning) {
        await _globalEQService.startGlobalEQ();
      }
      
      // Apply current EQ settings to global service
      await _applyEQToPlayer();
      
      debugPrint('✅ Global EQ initialized in EqualizerViewModel');
    } catch (e) {
      debugPrint('❌ Error initializing global EQ: $e');
    }
  }

  // Load EQ configuration from JSON
  Future<void> _loadEQConfiguration() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/EQ/presets.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _eqConfig = EQConfiguration.fromJson(jsonData);
      _frequencyLabels = _eqConfig!.frequencies;
      _presets = _eqConfig!.presets;
      _bandValues = List.filled(_eqConfig!.bandCount, 0.0);
      
      // Set default to first preset (Flat)
      if (_presets.isNotEmpty) {
        _currentPresetIndex = 0;
        _bandValues = List.from(_presets[0].values);
      }
      
      debugPrint('✅ EQ configuration loaded successfully: ${_presets.length} presets');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading EQ configuration: $e');
      // Fallback to default 8-band configuration
      _setDefaultConfiguration();
      // Re-throw the error so the UI can handle it
      rethrow;
    }
  }

  void _setDefaultConfiguration() {
    _frequencyLabels = ['60Hz', '170Hz', '310Hz', '600Hz', '1kHz', '3kHz', '6kHz', '12kHz'];
    _bandValues = List.filled(8, 0.0);
    _presets = [
      EQPresetData(id: 'flat', name: 'Flat', description: 'No EQ adjustment', values: List.filled(8, 0.0))
    ];
    _currentPresetIndex = 0;
  }

  // Update individual band value
  void updateBandValue(int index, double value) {
    if (index >= 0 && index < _bandValues.length) {
      _bandValues[index] = value.clamp(-12.0, 12.0);
      _currentPresetIndex = 0; // Reset to flat preset when manually adjusted
      _applyEQToPlayer();
      notifyListeners();
    }
  }

  // Reset all bands to 0
  void resetEQ() {
    _bandValues = List.filled(_bandValues.length, 0.0);
    _currentPresetIndex = 0; // Set to flat preset
    _applyEQToPlayer();
    notifyListeners();
  }

  // Apply preset by index
  void applyPreset(int presetIndex) {
    if (presetIndex >= 0 && presetIndex < _presets.length) {
      _currentPresetIndex = presetIndex;
      _bandValues = List.from(_presets[presetIndex].values);
      _applyEQToPlayer();
      notifyListeners();
    }
  }

  // Apply preset by EQPresetData object
  void applyPresetData(EQPresetData preset) {
    final index = _presets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      applyPreset(index);
    }
  }

  // Get preset name by index
  String getPresetName(int index) {
    if (index >= 0 && index < _presets.length) {
      return _presets[index].name;
    }
    return 'Unknown';
  }

  // Apply EQ settings to global EQ and audio player
  Future<void> _applyEQToPlayer() async {
    try {
      List<double> settingsToApply;
      
      if (_isEQOn) {
        settingsToApply = _bandValues;
      } else {
        // Apply flat EQ when disabled
        settingsToApply = List.filled(_bandValues.length, 0.0);
      }
      
      // Apply to global system-wide EQ
      await _globalEQService.applyEQSettings(settingsToApply);
      
      // Also apply to audio player (for compatibility and local adjustments)
      await _audioPlayerService.applyEQSettings(settingsToApply);
      
      debugPrint('🎛️ EQ settings applied to both global and local services');
    } catch (e) {
      debugPrint('❌ Error applying EQ settings: $e');
    }
  }

  // Quick playlist controls
  Future<void> loadMeditationPlaylist() async {
    await _audioPlayerService.loadPlaylist('meditation');
    notifyListeners();
  }

  Future<void> loadUpbeatPlaylist() async {
    await _audioPlayerService.loadPlaylist('upbeat');
    notifyListeners();
  }

  @override
  void dispose() {
    // Don't dispose the singleton audio service
    super.dispose();
  }
}