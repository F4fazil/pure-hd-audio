import 'package:flutter/material.dart';

enum EQPreset {
  flat,
  bassBoost,
  trebleBoost,
  rock,
  jazz,
  classical,
  vocalBoost,
}

class EqualizerViewModel extends ChangeNotifier {
  bool _isEQOn = true;
  EQPreset _currentPreset = EQPreset.flat;
  
  // 5-band EQ frequencies: 60Hz, 170Hz, 1kHz, 6kHz, 16kHz
  List<double> _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0]; // -12dB to +12dB range (0 = no change)
  
  final List<String> _frequencyLabels = [
    '60Hz', '170Hz', '1kHz', '6kHz', '16kHz'
  ];

  // Getters
  bool get isEQOn => _isEQOn;
  EQPreset get currentPreset => _currentPreset;
  List<double> get bandValues => List.unmodifiable(_bandValues);
  List<String> get frequencyLabels => List.unmodifiable(_frequencyLabels);

  // Toggle EQ on/off
  void toggleEQ() {
    _isEQOn = !_isEQOn;
    notifyListeners();
  }

  // Update individual band value
  void updateBandValue(int index, double value) {
    if (index >= 0 && index < _bandValues.length) {
      _bandValues[index] = value.clamp(-12.0, 12.0);
      _currentPreset = EQPreset.flat; // Reset to custom when manually adjusted
      notifyListeners();
    }
  }

  // Reset all bands to 0
  void resetEQ() {
    _bandValues = List.filled(5, 0.0);
    _currentPreset = EQPreset.flat;
    notifyListeners();
  }

  // Apply preset
  void applyPreset(EQPreset preset) {
    _currentPreset = preset;
    
    switch (preset) {
      case EQPreset.flat:
        _bandValues = [0.0, 0.0, 0.0, 0.0, 0.0];
        break;
      case EQPreset.bassBoost:
        _bandValues = [8.0, 6.0, 0.0, 0.0, 0.0];
        break;
      case EQPreset.trebleBoost:
        _bandValues = [0.0, 0.0, 0.0, 6.0, 8.0];
        break;
      case EQPreset.rock:
        _bandValues = [5.0, 3.0, 1.0, 5.0, 6.0];
        break;
      case EQPreset.jazz:
        _bandValues = [3.0, 2.0, 2.0, 2.0, 4.0];
        break;
      case EQPreset.classical:
        _bandValues = [4.0, 3.0, -1.0, 2.0, 4.0];
        break;
      case EQPreset.vocalBoost:
        _bandValues = [-1.0, 0.0, 5.0, 3.0, 0.0];
        break;
    }
    notifyListeners();
  }

  // Get preset name
  String getPresetName(EQPreset preset) {
    switch (preset) {
      case EQPreset.flat:
        return 'Flat';
      case EQPreset.bassBoost:
        return 'Bass Boost';
      case EQPreset.trebleBoost:
        return 'Treble Boost';
      case EQPreset.rock:
        return 'Rock';
      case EQPreset.jazz:
        return 'Jazz';
      case EQPreset.classical:
        return 'Classical';
      case EQPreset.vocalBoost:
        return 'Vocal Boost';
    }
  }
}