import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mock_bluetooth_device.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SettingsViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with back button and title
              Row(
                children: [
                  IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(width: 25),

                  Center(
                    child:
                        Text(
                              'Settings',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 200.ms)
                            .slideX(begin: -0.3, end: 0),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Settings options
              Expanded(
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, child) {
                    return ListView(
                      children: [
                        // Bluetooth Device Selection
                        _buildBluetoothSection(),

                        const SizedBox(height: 20),

                        // Language Selection
                        _buildLanguageSection(),

                        const SizedBox(height: 20),

                        // Website Link
                        _buildSettingItem(
                              icon: Icons.language,
                              title: 'Visit silentsystem.com',
                              subtitle: 'Learn more about our products',
                              onTap: _launchWebsite,
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 600.ms)
                            .slideX(begin: -0.2, end: 0),

                        // Equalizer
                        _buildSettingItem(
                              icon: Icons.equalizer,
                              title: 'Back to Equalizer',
                              subtitle: 'Return to main screen',
                              onTap: () => context.pop(),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 700.ms)
                            .slideX(begin: -0.2, end: 0),

                        // App Version Info
                        _buildSettingItem(
                              icon: Icons.info,
                              title: 'App Information',
                              subtitle: 'Version 1.0.0 - PURE HD AUDIO',
                              onTap: () => _showAboutDialog(context),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 800.ms)
                            .slideX(begin: -0.2, end: 0),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBluetoothSection() {
    return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.bluetooth,
                  color: Colors.white,
                  size: 28,
                ),
                title: const Text(
                  'Bluetooth Devices',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  viewModel.bluetoothService.connectedDevice?.name ??
                      'No device connected',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                trailing: viewModel.bluetoothService.isConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(
                        Icons.bluetooth_searching,
                        color: Colors.white54,
                      ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: viewModel.bluetoothService.isDiscovering
                                ? null
                                : () => viewModel.bluetoothService
                                      .startDiscovery(),
                            icon: viewModel.bluetoothService.isDiscovering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              viewModel.bluetoothService.isDiscovering
                                  ? 'Searching...'
                                  : 'Scan Devices',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A2A2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (viewModel.bluetoothService.isConnected)
                          ElevatedButton(
                            onPressed: () =>
                                viewModel.bluetoothService.disconnect(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Disconnect'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (viewModel.bluetoothService.devicesList.isNotEmpty)
                      ...viewModel.bluetoothService.devicesList.map(
                        (device) => _buildBluetoothDeviceItem(device),
                      ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 400.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildBluetoothDeviceItem(MockBluetoothDevice device) {
    final isConnected =
        viewModel.bluetoothService.connectedDevice?.id == device.id;
    final isConnecting = viewModel.bluetoothService.isConnecting;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withOpacity(0.2)
            : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.white12,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.headphones,
          color: isConnected ? Colors.green : Colors.white60,
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: TextStyle(
            color: isConnected ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          device.address,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.bluetooth, color: Colors.white54),
        onTap: isConnected || isConnecting
            ? null
            : () => viewModel.bluetoothService.connectToDevice(device),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.translate,
                  color: Colors.white,
                  size: 28,
                ),
                title: const Text(
                  'Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Current: ${viewModel.languageName}',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: Language.values.map((language) {
                    final isSelected = viewModel.selectedLanguage == language;
                    String languageText;
                    switch (language) {
                      case Language.english:
                        languageText = 'English (EN)';
                        break;
                      case Language.italian:
                        languageText = 'Italiano (IT)';
                        break;
                      case Language.spanish:
                        languageText = 'Español (ES)';
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white12,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          languageText,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              )
                            : null,
                        onTap: () {
                          if (language == Language.english) {
                            viewModel.setLanguage(language);
                          } else {
                            _showComingSoonSnackbar(language);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }

  void _showComingSoonSnackbar(Language language) {
    String languageName;
    switch (language) {
      case Language.italian:
        languageName = 'Italian';
        break;
      case Language.spanish:
        languageName = 'Spanish';
        break;
      default:
        languageName = 'Language';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$languageName support coming soon!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.grey.shade900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://silentsystem.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'PURE HD AUDIO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Advanced equalizer for premium audio experience with Bluetooth connectivity.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Features:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '• 7-band equalizer\n• Bluetooth device pairing\n• Multiple audio presets\n• Dark theme interface',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
