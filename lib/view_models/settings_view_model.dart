import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

enum Language { english }

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
    }
  }

  String get languageName {
    switch (_selectedLanguage) {
      case Language.english:
        return 'English';
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
      }
    }).toList();
  }

  // Refresh connected devices
  Future<void> refreshConnectedDevices() async {
    await _bluetoothService.refreshWithPermissions();
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    super.dispose();
  }
}