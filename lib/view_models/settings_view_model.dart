import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

enum Language { english, italian, spanish }

class SettingsViewModel extends ChangeNotifier {
  Language _selectedLanguage = Language.english;
  final BluetoothService _bluetoothService = BluetoothService();

  // Getters
  Language get selectedLanguage => _selectedLanguage;
  BluetoothService get bluetoothService => _bluetoothService;

  String get languageCode {
    switch (_selectedLanguage) {
      case Language.english:
        return 'EN';
      case Language.italian:
        return 'IT';
      case Language.spanish:
        return 'ES';
    }
  }

  String get languageName {
    switch (_selectedLanguage) {
      case Language.english:
        return 'English';
      case Language.italian:
        return 'Italiano';
      case Language.spanish:
        return 'Español';
    }
  }

  void setLanguage(Language language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  List<String> get availableLanguages {
    return Language.values.map((lang) {
      switch (lang) {
        case Language.english:
          return 'English (EN)';
        case Language.italian:
          return 'Italiano (IT)';
        case Language.spanish:
          return 'Español (ES)';
      }
    }).toList();
  }

  // Refresh connected devices
  Future<void> refreshConnectedDevices() async {
    await _bluetoothService.getPairedDevices();
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}