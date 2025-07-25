import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/mock_bluetooth_device.dart';
import '../services/audio_player_service.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsViewModel viewModel;
  late AudioPlayerService audioPlayerService;

  @override
  void initState() {
    super.initState();
    viewModel = SettingsViewModel();
    audioPlayerService = AudioPlayerService.instance;
    // Refresh connected devices when settings screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.refreshConnectedDevices();
    });
  }

  @override
  void dispose() {
    viewModel.dispose();
    // Don't dispose the singleton audio service
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
                        // Music Player Section
                        _buildMusicPlayerSection(),

                        const SizedBox(height: 20),

                        // Bluetooth Device Selection
                        _buildBluetoothSection(),

                        const SizedBox(height: 20),

                        // Language Selection
                        _buildLanguageSection(),

                        const SizedBox(height: 20),

                        // Spotify Playlist
                        _buildSettingItem(
                              icon: Icons.library_music,
                              title: 'Spotify Playlists',
                              subtitle: 'Access curated playlists for HD audio',
                              onTap: _launchSpotifyPlaylist,
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 600.ms)
                            .slideX(begin: -0.2, end: 0),

                        // Website Link
                        _buildSettingItem(
                              icon: Icons.language,
                              title: 'Visit silentsystem.com',
                              subtitle: 'Learn more about our products',
                              onTap: _launchWebsite,
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 650.ms)
                            .slideX(begin: -0.2, end: 0),

                        // EQ Info
                        _buildSettingItem(
                              icon: Icons.info_outline,
                              title: 'EQ Presets Info',
                              subtitle: 'Learn about equalizer presets',
                              onTap: () => _showEQInfoDialog(context),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 700.ms)
                            .slideX(begin: -0.2, end: 0),
                        
                        // Equalizer
                        _buildSettingItem(
                              icon: Icons.equalizer,
                              title: 'Back to Equalizer',
                              subtitle: 'Return to main screen',
                              onTap: () => context.pop(),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 750.ms)
                            .slideX(begin: -0.2, end: 0),

                        // App Version Info
                        _buildSettingItem(
                              icon: Icons.info,
                              title: 'App Information',
                              subtitle: 'Version 1.0.0 - PURE HD AUDIO',
                              onTap: () => _showAboutDialog(context),
                            )
                            .animate()
                            .fadeIn(duration: 800.ms, delay: 750.ms)
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

  Widget _buildMusicPlayerSection() {
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
                  Icons.music_note,
                  color: Colors.white,
                  size: 28,
                ),
                title: const Text(
                  'Music Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '432Hz Audio Tracks',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Current track info
                    ListenableBuilder(
                      listenable: audioPlayerService,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (audioPlayerService.currentTrack != null) ...[
                                Text(
                                  audioPlayerService.currentTrack!.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  audioPlayerService.currentTrack?.artist ?? 'Unknown Artist',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                    activeTrackColor: Colors.white,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: audioPlayerService.progress,
                                    onChanged: (value) {
                                      final position = Duration(
                                        milliseconds: (value * audioPlayerService.duration.inMilliseconds).round(),
                                      );
                                      audioPlayerService.seek(position);
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(audioPlayerService.position),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(audioPlayerService.duration),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.music_off,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No track selected',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Control buttons
                    ListenableBuilder(
                      listenable: audioPlayerService,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Previous button
                            IconButton(
                              onPressed: audioPlayerService.currentPlaylist.isNotEmpty
                                  ? () => audioPlayerService.previousTrack()
                                  : null,
                              icon: const Icon(Icons.skip_previous),
                              color: Colors.white,
                              iconSize: 32,
                            ),
                            
                            // Play/pause button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: audioPlayerService.currentTrack != null
                                    ? () => audioPlayerService.togglePlayPause()
                                    : null,
                                icon: Icon(
                                  audioPlayerService.isLoading 
                                      ? Icons.hourglass_empty
                                      : audioPlayerService.isPlaying 
                                          ? Icons.pause 
                                          : Icons.play_arrow,
                                ),
                                color: Colors.black,
                                iconSize: 32,
                              ),
                            ),
                            
                            // Next button
                            IconButton(
                              onPressed: audioPlayerService.currentPlaylist.isNotEmpty
                                  ? () => audioPlayerService.nextTrack()
                                  : null,
                              icon: const Icon(Icons.skip_next),
                              color: Colors.white,
                              iconSize: 32,
                            ),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Playlist selection buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => audioPlayerService.loadPlaylist('meditation'),
                            icon: const Icon(Icons.self_improvement),
                            label: const Text('Meditation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: audioPlayerService.currentCategory == 'meditation'
                                  ? Colors.blue.shade700
                                  : const Color(0xFF2A2A2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => audioPlayerService.loadPlaylist('upbeat'),
                            icon: const Icon(Icons.flash_on),
                            label: const Text('Upbeat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: audioPlayerService.currentCategory == 'upbeat'
                                  ? Colors.orange.shade700
                                  : const Color(0xFF2A2A2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Track list
                    ListenableBuilder(
                      listenable: audioPlayerService,
                      builder: (context, child) {
                        if (audioPlayerService.currentPlaylist.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: audioPlayerService.currentPlaylist.length,
                            itemBuilder: (context, index) {
                              final track = audioPlayerService.currentPlaylist[index];
                              final isCurrentTrack = audioPlayerService.currentTrack?.url == track.url;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentTrack 
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isCurrentTrack && audioPlayerService.isPlaying
                                        ? Icons.volume_up
                                        : Icons.music_note,
                                    color: isCurrentTrack ? Colors.white : Colors.white54,
                                    size: 16,
                                  ),
                                  title: Text(
                                    track.title,
                                    style: TextStyle(
                                      color: isCurrentTrack ? Colors.white : Colors.white70,
                                      fontSize: 12,
                                      fontWeight: isCurrentTrack ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    track.artist ?? 'Unknown Artist',
                                    style: TextStyle(
                                      color: isCurrentTrack ? Colors.white60 : Colors.white54,
                                      fontSize: 10,
                                    ),
                                  ),
                                  onTap: () => audioPlayerService.playTrack(track),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 800.ms, delay: 300.ms)
        .slideX(begin: -0.2, end: 0);
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
              
              // Permission status indicator - only show when we have demo devices OR no devices and no permissions
              FutureBuilder<bool>(
                future: viewModel.bluetoothService.hasBluetoothPermissions(),
                builder: (context, snapshot) {
                  final hasPermissions = snapshot.data ?? false;
                  final hasOnlyDemoDevices = viewModel.bluetoothService.devicesList.any((d) => d.name.contains('Demo'));
                  final shouldShowWarning = hasOnlyDemoDevices || (!hasPermissions && viewModel.bluetoothService.devicesList.isEmpty);
                  
                  if (!shouldShowWarning) return const SizedBox.shrink();
                  
                  return
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bluetooth permissions needed to detect your connected devices (like AirPods)',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await viewModel.bluetoothService.openSettings();
                                // Refresh devices after user returns from settings
                                Future.delayed(const Duration(seconds: 1), () {
                                  viewModel.refreshConnectedDevices();
                                });
                              },
                              icon: const Icon(Icons.settings, size: 16),
                              label: const Text('Open Settings'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => viewModel.refreshConnectedDevices(),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A2A2A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                },
              ),
              
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
                    // Show devices if we have any
                    if (viewModel.bluetoothService.devicesList.isNotEmpty)
                      ...viewModel.bluetoothService.devicesList.map(
                        (device) => _buildBluetoothDeviceItem(device),
                      )
                    else
                      // Show empty state when permissions granted but no devices
                      FutureBuilder<bool>(
                        future: viewModel.bluetoothService.hasBluetoothPermissions(),
                        builder: (context, snapshot) {
                          final hasPermissions = snapshot.data ?? false;
                          if (!hasPermissions) return const SizedBox.shrink();
                          
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bluetooth_disabled,
                                  color: Colors.white54,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No Bluetooth devices found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Make sure your AirPods or headphones are connected and try scanning again.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
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
    final isSystemDevice = device.id.startsWith('system_');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? Colors.green.withValues(alpha: 0.2)
            : isSystemDevice 
                ? Colors.blue.withValues(alpha: 0.1)
                : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected 
              ? Colors.green 
              : isSystemDevice 
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.white12,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.headphones,
          color: isConnected 
              ? Colors.green 
              : isSystemDevice 
                  ? Colors.blue 
                  : Colors.white60,
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: TextStyle(
            color: isConnected ? Colors.white : Colors.white70,
            fontSize: 16,
            fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.address,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (isSystemDevice)
              Text(
                'System connected (grant permissions for full control)',
                style: TextStyle(color: Colors.blue, fontSize: 10),
              ),
          ],
        ),
        trailing: isConnected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isSystemDevice
                ? const Icon(Icons.smartphone, color: Colors.blue)
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
        onTap: isConnected || isConnecting || isSystemDevice
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
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.1)
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
                          viewModel.setLanguage(language);
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


  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://silentsystem.com');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchSpotifyPlaylist() async {
    final Uri spotifyUrl = Uri.parse('https://open.spotify.com/user/ncw32pmxfr4bl8ng4dmxt96tb');
    if (!await launchUrl(spotifyUrl, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch Spotify playlist: $spotifyUrl');
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
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

  void _showEQInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'EQ Presets Guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEQPresetInfo('🎧 Bass Up', 'Emphasizes deep bass while cutting highs. Perfect for bass lovers and electronic beats.'),
              _buildEQPresetInfo('🎧 Hi-Fi', 'Clear and detailed response with an open high-frequency range. Pure high-definition listening.'),
              _buildEQPresetInfo('🎧 Deep EQ', 'Warm and deep profile. Strong low-end, softened highs for a smooth experience.'),
              _buildEQPresetInfo('🎧 Vibe+', 'Balanced and energetic. Slight boost to bass and treble for vibrant sound.'),
              _buildEQPresetInfo('🎧 Stage', 'Designed for live feel. Accentuates mids and highs for instruments and vocals.'),
              _buildEQPresetInfo('🎧 Warmth', 'Soft and cozy tone. Emphasizes lows and mids for a vintage warmth.'),
              _buildEQPresetInfo('🎧 Clarity', 'Crisp and clean. High-frequency boost ensures maximum detail and sharpness.'),
              _buildEQPresetInfo('🎧 Retro', 'Inspired by analog curves. Smooth and nostalgic with slight mid-cut.'),
            ],
          ),
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
              'Got it!',
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

  Widget _buildEQPresetInfo(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
