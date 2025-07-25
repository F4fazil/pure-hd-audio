import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_player_service.dart';
import '../models/eq_preset.dart';

class EqualizerViewModel extends ChangeNotifier {
  bool _isEQOn = true;
  int _currentPresetIndex = 0;
  
  // 8-band EQ system loaded from JSON
  List<double> _bandValues = List.filled(8, 0.0); // -12dB to +12dB range (0 = no change)
  List<String> _frequencyLabels = [];
  List<EQPresetData> _presets = [];
  EQConfiguration? _eqConfig;

  // Audio player service (singleton)
  final AudioPlayerService _audioPlayerService = AudioPlayerService.instance;

  // Getters
  bool get isEQOn => _isEQOn;
  int get currentPresetIndex => _currentPresetIndex;
  EQPresetData? get currentPreset => _presets.isNotEmpty ? _presets[_currentPresetIndex] : null;
  List<double> get bandValues => List.unmodifiable(_bandValues);
  List<String> get frequencyLabels => List.unmodifiable(_frequencyLabels);
  List<EQPresetData> get presets => List.unmodifiable(_presets);
  AudioPlayerService get audioPlayerService => _audioPlayerService;

  // Toggle EQ on/off
  void toggleEQ() {
    _isEQOn = !_isEQOn;
    _applyEQToPlayer();
    notifyListeners();
  }

  // Initialize with JSON data
  Future<void> initialize() async {
    await _loadEQConfiguration();
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
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading EQ configuration: $e');
      // Fallback to default 8-band configuration
      _setDefaultConfiguration();
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

  // Apply EQ settings to audio player
  Future<void> _applyEQToPlayer() async {
    try {
      if (_isEQOn) {
        await _audioPlayerService.applyEQSettings(_bandValues);
      } else {
        // Apply flat EQ when disabled
        await _audioPlayerService.applyEQSettings(List.filled(_bandValues.length, 0.0));
      }
    } catch (e) {
      debugPrint('Error applying EQ to player: $e');
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