import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import '../models/mock_bluetooth_device.dart';

class BluetoothService extends ChangeNotifier {
  bool _isConnecting = false;
  bool _isConnected = false;
  MockBluetoothDevice? _connectedDevice;
  fbp.BluetoothDevice? _connectedBluetoothDevice;
  List<MockBluetoothDevice> _devicesList = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<fbp.ScanResult>>? _scanResultsSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>?
  _connectionStateSubscription;
  fbp.BluetoothAdapterState _adapterState = fbp.BluetoothAdapterState.unknown;
  String? _connectingDeviceId;
  String? get connectingDeviceId => _connectingDeviceId;

  // Platform channel for native Bluetooth
  static const MethodChannel _channel = MethodChannel('bluetooth_discovery');

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isDiscovering => _isDiscovering;
  MockBluetoothDevice? get connectedDevice => _connectedDevice;
  List<MockBluetoothDevice> get devicesList => List.unmodifiable(_devicesList);
  fbp.BluetoothAdapterState get adapterState => _adapterState;

  BluetoothService() {
    _initializeBluetooth();
    _setupNativeDiscovery();
    // Load paired devices after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _loadPairedDevicesSimple();
    });
  }

  void _setupNativeDiscovery() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceFound':
          final deviceData = call.arguments as Map<dynamic, dynamic>;
          _handleNativeDeviceFound(deviceData);
          break;
        case 'onDiscoveryFinished':
          debugPrint('📡 Native discovery finished');
          break;
      }
    });
  }

  // Simplified device loading
  Future<void> _loadPairedDevicesSimple() async {
    try {
      debugPrint('🚀 Loading paired devices...');

      // Clear existing devices
      _devicesList.clear();

      // Get bonded devices from Flutter Blue Plus
      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
      debugPrint('✅ Found ${bondedDevices.length} bonded devices');

      for (var device in bondedDevices) {
        final deviceName = device.platformName.isNotEmpty 
            ? device.platformName 
            : 'Unknown Device';
            
        final mockDevice = MockBluetoothDevice(
          id: device.remoteId.str,
          name: deviceName,
          address: device.remoteId.str,
          rssi: -50,
          isPaired: true,
          isConnected: false,
          realDevice: device,
          isClassicBluetooth: true, // All paired devices should be treated as Classic Bluetooth for connection
        );

        _devicesList.add(mockDevice);
        debugPrint('✅ Added paired device: $deviceName');
      }

      notifyListeners();
      debugPrint('✅ Loaded ${_devicesList.length} paired devices');
      
    } catch (e) {
      debugPrint('❌ Error loading paired devices: $e');
    }
  }

  void _handleNativeDeviceFound(Map<dynamic, dynamic> deviceData) {
    debugPrint('📱 Native device found: ${deviceData['name']}');

    final device = MockBluetoothDevice(
      id: deviceData['address'] as String,
      name: deviceData['name'] as String,
      address: deviceData['address'] as String,
      rssi: deviceData['rssi'] as int? ?? -50,
      isPaired: deviceData['isPaired'] as bool? ?? false,
      isConnected: false,
      isClassicBluetooth: true,
    );

    // Add if not already in list
    if (!_devicesList.any((d) => d.id == device.id)) {
      _devicesList.add(device);
      debugPrint('✅ Added native device: ${device.name}');
      notifyListeners();
    }
  }

  void _handleNativeBondedDevice(Map<dynamic, dynamic> deviceData) {
    debugPrint('🔗 Native bonded device: ${deviceData['name']}');

    final device = MockBluetoothDevice(
      id: deviceData['address'] as String,
      name: deviceData['name'] as String,
      address: deviceData['address'] as String,
      rssi: deviceData['rssi'] as int? ?? -50,
      isPaired: true,
      isConnected: false,
      isClassicBluetooth: true,
    );

    // Add if not already in list
    if (!_devicesList.any((d) => d.id == device.id)) {
      _devicesList.add(device);
      debugPrint('✅ Added native bonded device: ${device.name}');
      notifyListeners();
    }
  }

  Future<void> _initializeBluetooth() async {
    try {
      debugPrint('🚀 Initializing Bluetooth service...');

      // Setup adapter state listener
      _adapterStateSubscription = fbp.FlutterBluePlus.adapterState.listen((
        state,
      ) {
        _adapterState = state;
        debugPrint('📶 Bluetooth adapter state changed: $state');
        notifyListeners();
      });

      // Get initial adapter state
      _adapterState = await fbp.FlutterBluePlus.adapterState.first;
      debugPrint('📶 Initial Bluetooth state: $_adapterState');

      // Request permissions
      await _requestPermissions();
    } catch (e) {
      debugPrint('❌ Error initializing Bluetooth: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      debugPrint('🔐 Requesting Bluetooth permissions...');
      
      if (Platform.isAndroid) {
        // Request all necessary permissions
        final permissions = [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ];
        
        final statuses = await permissions.request();
        
        // Log permission results
        for (var permission in permissions) {
          debugPrint('🔐 ${permission.toString()}: ${statuses[permission]}');
        }

        // Check if Bluetooth is enabled
        try {
          final isOn = await fbp.FlutterBluePlus.isOn;
          debugPrint('📶 Bluetooth is on: $isOn');
          
          if (!isOn) {
            debugPrint('⚠️ Requesting to turn on Bluetooth...');
            await fbp.FlutterBluePlus.turnOn();
          }
        } catch (e) {
          debugPrint('⚠️ Error checking/turning on Bluetooth: $e');
        }
      }

      // Load paired devices after permissions
      await _loadPairedDevicesSimple();
      
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      // Continue anyway - try to load what we can
      await _loadPairedDevicesSimple();
    }
  }

  Future<void> _attemptRealDeviceDetection() async {
    try {
      debugPrint('🔍 Attempting to detect real connected devices...');

      // Check if we have permissions first
      bool hasPermissions = await hasBluetoothPermissions();
      debugPrint('🔐 Has Bluetooth permissions: $hasPermissions');

      List<fbp.BluetoothDevice> realDevices = [];

      // Try to get connected devices
      try {
        final connectedDevices = fbp.FlutterBluePlus.connectedDevices;
        realDevices.addAll(connectedDevices);
        debugPrint('✅ Found ${realDevices.length} connected devices');

        for (var device in connectedDevices) {
          debugPrint(
            '📱 Connected device: ${device.platformName} (${device.remoteId.str})',
          );
        }
      } catch (e) {
        debugPrint('❌ connectedDevices failed: $e');
      }

      // Process real devices found
      if (realDevices.isNotEmpty) {
        await _processRealDevices(realDevices);
      } else {
        debugPrint('ℹ️ No devices detected');
        _devicesList.clear();
        _connectedDevice = null;
        _isConnected = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Real device detection failed: $e');
      _devicesList.clear();
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
    }
  }

  Future<void> _processRealDevices(List<fbp.BluetoothDevice> devices) async {
    try {
      // Remove duplicates
      Map<String, fbp.BluetoothDevice> uniqueDevices = {};
      for (var device in devices) {
        uniqueDevices[device.remoteId.str] = device;
      }

      // Convert to MockBluetoothDevice format
      _devicesList = uniqueDevices.values.map((device) {
        String deviceName = _getDeviceName(device);

        return MockBluetoothDevice(
          id: device.remoteId.str,
          name: deviceName,
          address: device.remoteId.str,
          isPaired: true,
          isConnected: true,
        );
      }).toList();

      // Auto-connect to first device
      if (_devicesList.isNotEmpty) {
        _connectedDevice = _devicesList.first;
        _isConnected = true;
        debugPrint('🎯 Real device connected: ${_connectedDevice!.name}');
      }

      debugPrint('📱 Processed ${_devicesList.length} real devices');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error processing real devices: $e');
    }
  }

  // Simplified refresh method with connection status check
  Future<void> refreshPairedDevices() async {
    try {
      debugPrint('🔄 Refreshing paired devices...');
      await _loadPairedDevicesSimple();
      
      // Check connection status for all paired devices
      await _updateConnectionStatus();
      
    } catch (e) {
      debugPrint('❌ Error refreshing paired devices: $e');
    }
  }

  // Check connection status for all devices
  Future<void> _updateConnectionStatus() async {
    try {
      debugPrint('🔍 Checking connection status for all devices...');
      
      for (var device in _devicesList) {
        if (device.isPaired) {
          try {
            final statusMap = await checkConnectionStatus(device.address);
            if (statusMap != null) {
              final wasConnected = device.isConnected;
              device.isConnected = statusMap['isConnected'] ?? false;
              
              // Update global connection state if needed
              if (device.isConnected && !wasConnected) {
                _isConnected = true;
                _connectedDevice = device;
                debugPrint('✅ Found connected device: ${device.name}');
              } else if (!device.isConnected && wasConnected && _connectedDevice?.id == device.id) {
                _isConnected = false;
                _connectedDevice = null;
                debugPrint('📱 Device disconnected: ${device.name}');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Error checking status for ${device.name}: $e');
          }
        }
      }
      
      notifyListeners();
      
    } catch (e) {
      debugPrint('❌ Error updating connection status: $e');
    }
  }

  // Update connection status for all devices in the list
  Future<void> _updateConnectionStatusForAllDevices() async {
    if (!Platform.isAndroid) return;

    try {
      for (var device in _devicesList) {
        if (device.isPaired && device.isClassicBluetooth) {
          final statusMap = await checkConnectionStatus(device.address);
          if (statusMap != null) {
            final wasConnected = device.isConnected;
            device.isConnected = statusMap['isConnected'] ?? false;

            // Update global connection state
            if (device.isConnected && !wasConnected) {
              _isConnected = true;
              _connectedDevice = device;
              debugPrint('📱 Found connected device: ${device.name}');
            } else if (!device.isConnected &&
                wasConnected &&
                _connectedDevice?.id == device.id) {
              _isConnected = false;
              _connectedDevice = null;
              debugPrint('📱 Device disconnected: ${device.name}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating connection status: $e');
    }
  }

  String _getDeviceName(fbp.BluetoothDevice device) {
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }

    String deviceId = device.remoteId.str;
    String shortId = deviceId.substring(0, 8);
    return 'Bluetooth Device ($shortId)';
  }

  // Simplified Bluetooth discovery
  Future<void> startDiscovery() async {
    if (_isDiscovering) {
      debugPrint('⚠️ Already scanning, ignoring request');
      return;
    }

    debugPrint('🔍 Starting Bluetooth scan...');

    try {
      _isDiscovering = true;
      notifyListeners();

      // Stop any ongoing scan
      await fbp.FlutterBluePlus.stopScan();
      
      // Check permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        debugPrint('❌ Missing permissions for Bluetooth scan');
        _isDiscovering = false;
        notifyListeners();
        return;
      }

      // Start scanning for new devices
      debugPrint('🔵 Starting BLE scan for new devices...');
      
      _scanResultsSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final deviceName = result.device.platformName.isNotEmpty
              ? result.device.platformName
              : "Device ${result.device.remoteId.str.substring(0, 6)}";

          // Skip if already in list
          if (_devicesList.any((d) => d.id == result.device.remoteId.str)) {
            continue;
          }

          final device = MockBluetoothDevice(
            id: result.device.remoteId.str,
            name: deviceName,
            address: result.device.remoteId.str,
            rssi: result.rssi,
            isPaired: false,
            isConnected: false,
            realDevice: result.device,
            isClassicBluetooth: false,
          );

          _devicesList.add(device);
          debugPrint('✅ Found new device: $deviceName (${result.rssi} dBm)');
          notifyListeners();
        }
      });

      // Start scan
      await fbp.FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

      // Auto-stop after timeout
      _discoveryTimer = Timer(Duration(seconds: 12), () {
        if (_isDiscovering) {
          stopDiscovery();
        }
      });

    } catch (e) {
      debugPrint('❌ Scan error: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<bool> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.status;
        final connectStatus = await Permission.bluetoothConnect.status;
        final locationStatus = await Permission.location.status;
        
        return scanStatus.isGranted && connectStatus.isGranted && locationStatus.isGranted;
      }
      return true; // iOS handles permissions automatically
    } catch (e) {
      debugPrint('❌ Permission check error: $e');
      return false;
    }
  }

  void stopDiscovery() {
    if (!_isDiscovering) {
      debugPrint('⚠️ Not discovering, ignoring stop request');
      return;
    }

    debugPrint('🛑 Stopping Bluetooth discovery...');
    try {
      _discoveryTimer?.cancel();
      _scanResultsSubscription?.cancel();
      fbp.FlutterBluePlus.stopScan();

      // Stop native discovery
      if (Platform.isAndroid) {
        _channel
            .invokeMethod('stopDiscovery')
            .then((result) {
              debugPrint('🤖 Native discovery stopped: $result');
            })
            .catchError((e) {
              debugPrint('⚠️ Error stopping native discovery: $e');
            });
      }

      _isDiscovering = false;
      notifyListeners();
      debugPrint('✅ Bluetooth discovery stopped');
    } catch (e) {
      debugPrint('❌ Error stopping discovery: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  // Check actual connection status using native method
  Future<Map<String, dynamic>?> checkConnectionStatus(
    String deviceAddress,
  ) async {
    try {
      final result = await _channel.invokeMethod('checkConnectionStatus', {
        'address': deviceAddress,
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      debugPrint('❌ Error checking connection status: $e');
      return null;
    }
  }

  // Use native Android connection for audio devices
  Future<bool> connectToDevice(MockBluetoothDevice device) async {
    if (_isConnecting) {
      debugPrint('⚠️ Already connecting to another device');
      return false;
    }

    try {
      _isConnecting = true;
      _connectingDeviceId = device.id;
      notifyListeners();

      debugPrint('🔗 Attempting connection to: ${device.name}');
      debugPrint('🔍 Device details - isPaired: ${device.isPaired}, isClassicBluetooth: ${device.isClassicBluetooth}, hasRealDevice: ${device.realDevice != null}');

      // For paired devices, always use native Android method first
      if (device.isPaired) {
        debugPrint('🎧 Connecting to paired device via native Android...');
        
        try {
          final result = await _channel.invokeMethod('connectToDevice', {
            'address': device.address,
          });
          
          debugPrint('✅ Native connection result: $result');
          
          // Update device state
          device.isConnected = true;
          _isConnected = true;
          _connectedDevice = device;
          
          _isConnecting = false;
          _connectingDeviceId = null;
          notifyListeners();
          
          return true;
          
        } catch (e) {
          debugPrint('❌ Native connection failed: $e');
          _isConnecting = false;
          _connectingDeviceId = null;
          notifyListeners();
          return false;
        }
      }

      // For BLE devices, use Flutter Blue Plus
      if (device.realDevice != null) {
        debugPrint('🔵 Connecting to BLE device...');
        
        final realDevice = device.realDevice as fbp.BluetoothDevice;

        // Stop any ongoing scans
        await fbp.FlutterBluePlus.stopScan();

        // Attempt BLE connection
        await realDevice.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );

        // Update states
        device.isConnected = true;
        _isConnected = true;
        _connectedDevice = device;
        _connectedBluetoothDevice = realDevice;

        // Listen for disconnection
        _connectionStateSubscription?.cancel();
        _connectionStateSubscription = realDevice.connectionState.listen((state) {
          if (state == fbp.BluetoothConnectionState.disconnected) {
            _handleDisconnect();
          }
        });

        _isConnecting = false;
        _connectingDeviceId = null;
        notifyListeners();

        debugPrint('✅ BLE connection successful: ${device.name}');
        return true;
      }

      // No connection method available
      debugPrint('❌ No connection method available for device');
      _isConnecting = false;
      _connectingDeviceId = null;
      notifyListeners();
      return false;

    } catch (e) {
      debugPrint('❌ Connection failed for ${device.name}: $e');
      
      _isConnecting = false;
      _connectingDeviceId = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> _processAndroidScanResults(List<fbp.ScanResult> results) async {
    for (fbp.ScanResult result in results) {
      String deviceName = result.device.platformName;

      // Check if it's a paired device first
      bool isPairedDevice = false;
      try {
        final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
        for (var bonded in bondedDevices) {
          if (bonded.remoteId.str == result.device.remoteId.str) {
            isPairedDevice = true;
            deviceName = bonded.platformName.isNotEmpty
                ? bonded.platformName
                : deviceName;
            break;
          }
        }
      } catch (e) {
        // Ignore errors checking bonded devices
      }

      // SHOW ALL DEVICES - NO FILTERING
      final discoveredDevice = MockBluetoothDevice(
        id: result.device.remoteId.str,
        name: deviceName.isNotEmpty
            ? deviceName
            : 'Device (${result.device.remoteId.str.substring(0, 8)})',
        address: result.device.remoteId.str,
        rssi: result.rssi,
        isPaired: isPairedDevice,
        isConnected: false,
        realDevice: result.device,
        isClassicBluetooth: _isLikelyAudioDeviceClassic(deviceName),
      );

      // Add only if not already in list
      if (!_devicesList.any((d) => d.id == discoveredDevice.id)) {
        _devicesList.add(discoveredDevice);
        notifyListeners();
        debugPrint(
          '✅ Added device: ${discoveredDevice.name} (${result.rssi} dBm)',
        );
      }
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice == null) {
      debugPrint('⚠️ No device connected to disconnect from');
      return;
    }

    final deviceToDisconnect = _connectedDevice!;
    debugPrint('🔌 Disconnecting from: ${deviceToDisconnect.name}');

    try {
      bool disconnectionAttempted = false;
      
      // For Classic Bluetooth audio devices, use native Android method
      if (deviceToDisconnect.isClassicBluetooth || _isLikelyAudioDeviceClassic(deviceToDisconnect.name)) {
        debugPrint('🎧 Disconnecting audio device via native Android...');
        
        try {
          await _channel.invokeMethod('disconnectFromDevice', {
            'address': deviceToDisconnect.address,
          });
          debugPrint('✅ Native disconnection command sent');
          disconnectionAttempted = true;
        } catch (e) {
          debugPrint('❌ Native disconnection failed: $e');
        }
      }
      
      // For BLE devices
      if (_connectedBluetoothDevice != null) {
        await _connectedBluetoothDevice!.disconnect();
        debugPrint('✅ BLE disconnection command sent');
        disconnectionAttempted = true;
      }

      if (disconnectionAttempted) {
        // Wait for disconnection to take effect
        await Future.delayed(Duration(milliseconds: 1000));
        
        // Check actual connection status
        try {
          final statusMap = await checkConnectionStatus(deviceToDisconnect.address);
          final isStillConnected = statusMap?['isConnected'] ?? false;
          
          if (!isStillConnected) {
            debugPrint('✅ Device actually disconnected');
            deviceToDisconnect.isConnected = false;
            _connectedDevice = null;
            _connectedBluetoothDevice = null;
            _isConnected = false;
          } else {
            debugPrint('⚠️ Device may still be connected according to system');
            // Don't update the UI state if still connected
          }
        } catch (e) {
          debugPrint('❌ Error checking disconnection status: $e');
          // If we can't check, assume disconnected
          deviceToDisconnect.isConnected = false;
          _connectedDevice = null;
          _connectedBluetoothDevice = null;
          _isConnected = false;
        }
      }

      _connectionStateSubscription?.cancel();
      notifyListeners();
      debugPrint('🔌 Disconnect process completed for: ${deviceToDisconnect.name}');
      
    } catch (e) {
      debugPrint('❌ Error disconnecting: $e');
      // Force disconnect in UI even if there was an error
      deviceToDisconnect.isConnected = false;
      _connectedDevice = null;
      _connectedBluetoothDevice = null;
      _isConnected = false;
      notifyListeners();
    }
  }

  // Public method for backward compatibility
  Future<void> getPairedDevices() async {
    await _attemptRealDeviceDetection();
  }

  // Check if we have the necessary permissions
  Future<bool> hasBluetoothPermissions() async {
    try {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;

      debugPrint('🔍 Scan permission: $scanStatus');
      debugPrint('🔗 Connect permission: $connectStatus');

      // On iOS, permissions might not be explicitly granted but still work
      bool hasPermissions =
          (scanStatus == PermissionStatus.granted &&
              connectStatus == PermissionStatus.granted) ||
          (scanStatus != PermissionStatus.denied &&
              connectStatus != PermissionStatus.denied);

      debugPrint('📱 Calculated permissions: $hasPermissions');
      return hasPermissions;
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      // If permission checking fails, assume we have permissions and let the scan try
      return true;
    }
  }

  // Force refresh permissions and device detection
  Future<void> refreshWithPermissions() async {
    debugPrint('🔄 Forcing refresh with permission check...');
    await _requestPermissions();
  }

  // Open app settings if permissions are denied
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  // Android-optimized EQ data transmission
  Future<void> sendData(String data) async {
    if (_connectedBluetoothDevice != null &&
        _connectedDevice?.isConnected == true) {
      try {
        debugPrint('🎵 Sending EQ data to ${_connectedDevice!.name}: $data');

        if (Platform.isAndroid) {
          await _sendAndroidEQData(data);
        } else {
          debugPrint('🎵 EQ data simulation for non-Android: $data');
        }
      } catch (e) {
        debugPrint('❌ Error sending EQ data: $e');
      }
    } else {
      debugPrint('⚠️ No connected device for EQ data transmission');
    }
  }

  // Android-specific EQ data transmission
  Future<void> _sendAndroidEQData(String data) async {
    try {
      if (_connectedBluetoothDevice == null) return;

      // Discover services if not already done
      List<fbp.BluetoothService> services = await _connectedBluetoothDevice!
          .discoverServices();

      for (fbp.BluetoothService service in services) {
        String serviceUuid = service.serviceUuid.toString().toLowerCase();

        // Look for custom EQ service or generic attribute service
        if (serviceUuid.contains('1801') || // Generic Attribute
            serviceUuid.contains('1800') || // Generic Access
            serviceUuid.contains('180f')) {
          // Battery (often used for custom data)

          for (fbp.BluetoothCharacteristic characteristic
              in service.characteristics) {
            // Check if characteristic supports write operations
            if (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse) {
              debugPrint(
                '🎵 Found writable characteristic: ${characteristic.characteristicUuid}',
              );

              try {
                // Convert EQ data to bytes
                List<int> dataBytes = data.codeUnits;

                // Write EQ data to characteristic
                await characteristic.write(
                  dataBytes,
                  withoutResponse:
                      characteristic.properties.writeWithoutResponse,
                );
                debugPrint('✅ Android EQ data sent successfully');
                return;
              } catch (writeError) {
                debugPrint(
                  '❌ Write failed for ${characteristic.characteristicUuid}: $writeError',
                );
              }
            }
          }
        }
      }

      debugPrint('⚠️ No suitable characteristic found for EQ data');
    } catch (e) {
      debugPrint('❌ Android EQ data transmission failed: $e');
    }
  }

  // Send EQ preset to connected Android device
  Future<void> sendEQPreset(Map<String, dynamic> eqPreset) async {
    if (!Platform.isAndroid) {
      debugPrint('🎵 EQ preset simulation for non-Android');
      return;
    }

    try {
      // Convert EQ preset to JSON string
      String eqData =
          '''
{
  "type": "eq_preset",
  "name": "${eqPreset['name'] ?? 'Custom'}",
  "bands": ${eqPreset['bands'] ?? '[]'},
  "timestamp": "${DateTime.now().toIso8601String()}"
}
''';

      debugPrint('🎵 Sending Android EQ preset: ${eqPreset['name']}');
      await sendData(eqData);
    } catch (e) {
      debugPrint('❌ Android EQ preset transmission failed: $e');
    }
  }

  // Android-specific permission checking
  Future<bool> _checkAndroidPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final scanStatus = await Permission.bluetoothScan.status;
      final connectStatus = await Permission.bluetoothConnect.status;
      final locationStatus = await Permission.location.status;

      debugPrint('🤖 Android Scan: $scanStatus');
      debugPrint('🤖 Android Connect: $connectStatus');
      debugPrint('🤖 Android Location: $locationStatus');

      return scanStatus.isGranted && connectStatus.isGranted;
    } catch (e) {
      debugPrint('❌ Android permission check failed: $e');
      return false;
    }
  }

  // Android-specific permission requesting
  Future<bool> _requestAndroidPermissions() async {
    try {
      // Request location permission first - VERY IMPORTANT for BLE scanning
      var locationStatus = await Permission.locationWhenInUse.request();
      debugPrint('📍 Location permission request result: $locationStatus');

      // Show alert if denied
      if (!locationStatus.isGranted) {
        debugPrint(
          '⚠️ Location permission denied - Bluetooth scanning will fail',
        );
      }

      // Then request Bluetooth permissions
      var bluetoothScan = await Permission.bluetoothScan.request();
      var bluetoothConnect = await Permission.bluetoothConnect.request();

      return locationStatus.isGranted &&
          bluetoothScan.isGranted &&
          bluetoothConnect.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting Android permissions: $e');
      return false;
    }
  }

  // Android-specific connected device detection
  Future<void> _getAndroidConnectedDevices() async {
    try {
      final connectedDevices = fbp.FlutterBluePlus.connectedDevices;
      debugPrint('🤖 Android connected devices: ${connectedDevices.length}');

      for (var device in connectedDevices) {
        String deviceName = device.platformName.isNotEmpty
            ? device.platformName
            : 'Android Device';

        final connectedDevice = MockBluetoothDevice(
          id: device.remoteId.str,
          name: '$deviceName (Connected)',
          address: device.remoteId.str,
          isPaired: true,
          isConnected: true,
        );

        if (!_devicesList.any((d) => d.id == connectedDevice.id)) {
          _devicesList.add(connectedDevice);
          debugPrint('✅ Android connected: $deviceName');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Android connected devices error: $e');
    }
  }

  // Android-specific scan result processing

  Future<void> _findPairedDevices() async {
    try {
      debugPrint('🔄 Looking for paired (bonded) devices...');

      // Get Classic Bluetooth paired devices first (for audio devices)
      await _findClassicBluetoothDevices();

      // Then get BLE bonded devices, but skip any that are already found as Classic devices
      try {
        final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
        debugPrint('✅ Found ${bondedDevices.length} BLE bonded devices');

        // Process each BLE paired device
        for (final device in bondedDevices) {
          debugPrint(
            '🔵 BLE Paired device: ${device.platformName} (${device.remoteId.str})',
          );

          // Skip if this device is already added as a Classic Bluetooth device
          if (_devicesList.any(
            (d) => d.address.toUpperCase() == device.remoteId.str.toUpperCase(),
          )) {
            debugPrint(
              '⚠️ Skipping ${device.platformName} - already found as Classic Bluetooth device',
            );
            continue;
          }

          final name = device.platformName.isNotEmpty
              ? device.platformName
              : 'BLE Device (${device.remoteId.str.substring(0, 8)})';

          // Only add if it's likely NOT an audio device (since audio devices should be Classic)
          if (!_isLikelyAudioDeviceClassic(name)) {
            final pairedDevice = MockBluetoothDevice(
              id: device.remoteId.str,
              name: name,
              address: device.remoteId.str,
              rssi: -50, // Default RSSI for paired devices
              isPaired: true,
              isConnected: false,
              realDevice: device,
              isClassicBluetooth: false,
            );

            // Add only if not already in list
            if (!_devicesList.any((d) => d.id == pairedDevice.id)) {
              _devicesList.add(pairedDevice);
              debugPrint('✅ Added BLE paired device: $name');
            }
          } else {
            debugPrint(
              '⚠️ Skipping audio device $name from BLE list - should be Classic Bluetooth',
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error getting BLE bonded devices: $e');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error finding paired devices: $e');
    }
  }

  Future<void> _findClassicBluetoothDevices() async {
    try {
      debugPrint('🎧 Looking for Bluetooth audio devices...');

      // Check if Bluetooth is available and enabled
      final isEnabled = await fbp.FlutterBluePlus.isOn;

      debugPrint('📶 Bluetooth enabled: $isEnabled');

      if (!isEnabled) {
        debugPrint('⚠️ Bluetooth is disabled');
        return;
      }

      // For audio devices, we'll just use the bonded (paired) devices from FlutterBluePlus
      final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;

      debugPrint('✅ Found ${bondedDevices.length} bonded devices to check');

      // Process each bonded device
      for (final device in bondedDevices) {
        final deviceName = device.platformName;
        debugPrint('🔍 Checking bonded device: "$deviceName"');

        // Check if it's likely an audio device
        if (_isLikelyAudioDeviceClassic(deviceName)) {
          debugPrint('✅ "$deviceName" identified as audio device');

          final audioDevice = MockBluetoothDevice(
            id: device.remoteId.str,
            name: deviceName.isNotEmpty
                ? deviceName
                : 'Audio Device (${device.remoteId.str.substring(0, 8)})',
            address: device.remoteId.str,
            rssi: -50, // Default RSSI for paired devices
            isPaired: true,
            isConnected: false,
            realDevice: device,
            isClassicBluetooth:
                true, // We'll still mark audio devices as "classic" for the UI
          );

          // Add only if not already in list
          if (!_devicesList.any((d) => d.id == audioDevice.id)) {
            _devicesList.add(audioDevice);
            debugPrint('✅ Added audio device: $deviceName');
          } else {
            debugPrint('ℹ️ Audio device already in list: $deviceName');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error finding audio devices: $e');
      debugPrint('❌ Stack trace: ${e.toString()}');
    }
  }

  // Update the _connectToClassicBluetoothDevice method to use BLE
  Future<bool> _connectToClassicBluetoothDevice(
    MockBluetoothDevice device,
  ) async {
    try {
      debugPrint('🎧 Connecting to audio device: ${device.name}');

      // Check if the device has a real BLE device reference
      if (device.realDevice == null) {
        debugPrint('⚠️ No real device reference for audio device');

        // Try to find the device in the bonded devices
        final bondedDevices = await fbp.FlutterBluePlus.bondedDevices;
        for (final bondedDevice in bondedDevices) {
          if (bondedDevice.remoteId.str == device.id) {
            debugPrint('✅ Found bonded device with matching ID');

            // Try to connect using the bonded device
            await bondedDevice.connect(
              timeout: const Duration(seconds: 10),
              autoConnect: false,
            );

            _isConnected = true;
            _connectedDevice = device;
            _connectedBluetoothDevice = bondedDevice;
            _isConnecting = false;
            notifyListeners();

            debugPrint('✅ Connected to audio device: ${device.name}');
            return true;
          }
        }

        debugPrint('⚠️ Could not find audio device in bonded devices');
        _isConnecting = false;
        notifyListeners();
        return false;
      } else {
        // Connect using the real device reference
        final realDevice = device.realDevice as fbp.BluetoothDevice;

        await realDevice.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );

        _isConnected = true;
        _connectedDevice = device;
        _connectedBluetoothDevice = realDevice;
        _isConnecting = false;
        notifyListeners();

        debugPrint('✅ Connected to audio device: ${device.name}');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Audio device connection error: $e');
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> testPermissions() async {
    try {
      // Check all relevant permissions
      final locationStatus = await Permission.locationWhenInUse.status;
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;

      debugPrint('📱 PERMISSIONS STATUS:');
      debugPrint('📍 Location permission: $locationStatus');
      debugPrint('🔍 Bluetooth scan permission: $bluetoothScan');
      debugPrint('🔌 Bluetooth connect permission: $bluetoothConnect');

      // Request any missing permissions
      if (!locationStatus.isGranted ||
          !bluetoothScan.isGranted ||
          !bluetoothConnect.isGranted) {
        await _requestAndroidPermissions();
      }
    } catch (e) {
      debugPrint('❌ Permission test error: $e');
    }
  }

  // Helper to identify likely audio devices (Classic Bluetooth)
  bool _isLikelyAudioDeviceClassic(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.contains('audio') ||
        lowerName.contains('headset') ||
        lowerName.contains('speaker') ||
        lowerName.contains('earbuds') ||
        lowerName.contains('car') ||
        lowerName.contains('handsfree') ||
        lowerName.contains('stereo') ||
        lowerName.contains('sound') ||
        lowerName.contains('music');
  }

  // Helper to identify likely audio devices from BLE scan results
  bool _isLikelyAudioDevice(
    String name,
    fbp.AdvertisementData advertisementData,
  ) {
    // Debug the actual device that was found
    debugPrint(
      '📱 Checking device: "$name" with UUIDs: ${advertisementData.serviceUuids}',
    );

    // First check the name like we do for Classic Bluetooth
    if (_isLikelyAudioDeviceClassic(name)) {
      debugPrint('✅ "$name" passed name check');
      return true;
    }

    // IMPORTANT: Show SirBuds or any earbuds specifically
    if (name.toLowerCase().contains('bud') ||
        name.toLowerCase().contains('sir') ||
        name.toLowerCase().contains('earbud')) {
      debugPrint('✅ "$name" matched earbuds keyword');
      return true;
    }

    // Check service UUIDs in advertisement data
    if (advertisementData.serviceUuids.isNotEmpty) {
      for (fbp.Guid uuid in advertisementData.serviceUuids) {
        final lowerUuid = uuid.toString().toLowerCase();
        debugPrint('🔍 Checking UUID: $lowerUuid');

        // Check for audio-related service UUIDs - expanded list
        if (lowerUuid.contains('110a') || // Audio Service
            lowerUuid.contains('110b') || // A2DP
            lowerUuid.contains('110c') || // AVRCP
            lowerUuid.contains('110e') || // Handsfree
            lowerUuid.contains('111e') || // Headset
            lowerUuid.contains('18') || // Any Bluetooth standard service
            lowerUuid.contains('fd')) {
          // Common for earbuds
          debugPrint('✅ "$name" has audio-related UUID: $lowerUuid');
          return true;
        }
      }
    }

    if (advertisementData.manufacturerData.isNotEmpty) {
      debugPrint('✅ "$name" has manufacturer data');
      return true; // Most BLE audio devices have manufacturer data
    }

    // If device has a meaningful name, show it for user to decide
    if (name.isNotEmpty && name != 'N/A' && !name.startsWith('Unknown')) {
      debugPrint('✅ "$name" has meaningful name - showing for user decision');
      return true;
    }

    debugPrint('❌ "$name" did not pass any audio device checks');
    return false;
  }

  // Handle device disconnection events
  void _handleDisconnect() {
    debugPrint('📱 Device disconnected: ${_connectedDevice?.name}');
    _isConnected = false;
    _connectedDevice = null;
    _connectedBluetoothDevice = null;
    notifyListeners();
  }
}
