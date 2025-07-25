import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/mock_bluetooth_device.dart';

class BluetoothService extends ChangeNotifier {
  bool _isConnecting = false;
  bool _isConnected = false;
  MockBluetoothDevice? _connectedDevice;
  BluetoothDevice? _connectedBluetoothDevice;
  List<MockBluetoothDevice> _devicesList = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isDiscovering => _isDiscovering;
  MockBluetoothDevice? get connectedDevice => _connectedDevice;
  List<MockBluetoothDevice> get devicesList => List.unmodifiable(_devicesList);
  BluetoothAdapterState get adapterState => _adapterState;

  BluetoothService() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      debugPrint('Initializing Flutter Blue Plus service');
      
      // Request permissions
      await _requestPermissions();
      
      // Setup adapter state listener
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        _adapterState = state;
        debugPrint('Bluetooth adapter state: $state');
        notifyListeners();
        
        // Always try to get real devices when adapter state changes
        _getConnectedDevices();
      });
      
      // Check initial adapter state
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.unknown) {
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // Always try to get real connected devices first
      await _getConnectedDevices();
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Check current permissions first
      Map<Permission, PermissionStatus> currentStatuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();
      
      debugPrint('Bluetooth permissions: $currentStatuses');
      
      // Always try to get real devices first, regardless of permissions
      // Many iOS/Android system functions work without explicit permissions
      await _attemptRealDeviceDetection();
      
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      // Still try to detect real devices
      await _attemptRealDeviceDetection();
    }
  }

  Future<void> _attemptRealDeviceDetection() async {
    try {
      debugPrint('🔍 Attempting to detect real connected devices...');
      
      List<BluetoothDevice> realDevices = [];
      
      // Method 1: Try to get connected devices (works on some platforms without permissions)
      try {
        realDevices.addAll(FlutterBluePlus.connectedDevices);
        debugPrint('✅ Found ${realDevices.length} connected devices via connectedDevices');
      } catch (e) {
        debugPrint('❌ connectedDevices failed: $e');
      }
      
      // Method 2: Try system devices with audio UUIDs (often works without scan permission)
      try {
        List<Guid> audioUuids = [
          Guid("0000110B-0000-1000-8000-00805F9B34FB"), // Audio Sink
          Guid("0000110A-0000-1000-8000-00805F9B34FB"), // Audio Source
          Guid("0000111E-0000-1000-8000-00805F9B34FB"), // Handsfree
          Guid("0000180F-0000-1000-8000-00805F9B34FB"), // Battery Service
        ];
        
        List<BluetoothDevice> systemDevices = await FlutterBluePlus.systemDevices(audioUuids);
        realDevices.addAll(systemDevices);
        debugPrint('✅ Found ${systemDevices.length} system audio devices');
        
      } catch (e) {
        debugPrint('❌ systemDevices failed: $e');
      }
      
      // Process real devices found
      if (realDevices.isNotEmpty) {
        await _processRealDevices(realDevices);
      } else {
        debugPrint('ℹ️ No real devices detected, checking if any are already connected...');
        // Only show "no devices" if we truly can't detect anything
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

  Future<void> _processRealDevices(List<BluetoothDevice> devices) async {
    try {
      // Remove duplicates
      Map<String, BluetoothDevice> uniqueDevices = {};
      for (var device in devices) {
        uniqueDevices[device.remoteId.str] = device;
      }
      
      // Convert to MockBluetoothDevice format (keeping the same interface)
      _devicesList = uniqueDevices.values.map((device) {
        String deviceName = _getDeviceName(device);
            
        return MockBluetoothDevice(
          id: device.remoteId.str,
          name: deviceName,
          address: device.remoteId.str,
          isPaired: true,
          isConnected: true, // If we can see it, assume it's connected
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

  Future<void> _getConnectedDevices() async {
    // Use the new real device detection method instead
    await _attemptRealDeviceDetection();
  }

  Future<void> _addSystemConnectedDevices() async {
    debugPrint('Adding system-connected devices (based on common connected device patterns)');
    
    // Since we can't detect actual system connections without permissions,
    // we'll add commonly connected devices as "likely connected"
    final systemDevices = [
      MockBluetoothDevice(
        id: 'system_iphone',
        name: 'Fazil\'s iPhone (Connected)',
        address: 'XX:XX:XX:XX:XX:XX',
        isPaired: true,
        isConnected: true,
      ),
      MockBluetoothDevice(
        id: 'system_airpods',
        name: 'AirPods (System Connected)',
        address: 'XX:XX:XX:XX:XX:XX',
        isPaired: true,
        isConnected: true,
      ),
      MockBluetoothDevice(
        id: 'system_headphones',
        name: 'Bluetooth Headphones (System)',
        address: 'XX:XX:XX:XX:XX:XX',  
        isPaired: true,
        isConnected: true,
      ),
    ];
    
    _devicesList.addAll(systemDevices);
    debugPrint('Added ${systemDevices.length} system reference devices');
  }

  bool _isAudioDevice(BluetoothDevice device) {
    // Check if device is likely an audio device based on name
    if (device.platformName.isEmpty) return false;
    
    String name = device.platformName.toLowerCase();
    return name.contains('headphones') ||
           name.contains('headset') ||
           name.contains('earbuds') ||
           name.contains('speaker') ||
           name.contains('audio') ||
           name.contains('beats') ||
           name.contains('airpods') ||
           name.contains('sony') ||
           name.contains('bose') ||
           name.contains('jbl') ||
           name.contains('sennheiser') ||
           name.contains('buds') ||
           name.contains('pods');
  }

  bool _isConnectedDevice(BluetoothDevice device) {
    // Check for connected devices that can stream audio (like iPhones)
    if (device.platformName.isEmpty) return false;
    
    String name = device.platformName.toLowerCase();
    return name.contains('iphone') ||        // iPhone detection
           name.contains('ipad') ||          // iPad detection  
           name.contains('phone') ||         // Generic phone detection
           name.contains('mobile') ||        // Mobile device detection
           name.contains('apple') ||         // Apple device detection
           name.startsWith('fazil\'s') ||    // Personal device naming pattern
           name.contains('\'s iphone') ||    // Common iPhone naming
           name.contains('\'s phone') ||     // Common phone naming
           name.contains('android') ||       // Android device detection
           name.contains('samsung') ||       // Samsung device detection
           name.contains('pixel');           // Google Pixel detection
  }

  String _getDeviceName(BluetoothDevice device) {
    // Return the best available name for the device
    if (device.platformName.isNotEmpty) {
      return device.platformName;
    }
    
    // Fallback to a descriptive name based on device ID
    String deviceId = device.remoteId.str;
    String shortId = deviceId.substring(0, 8);
    
    // Try to determine device type from characteristics
    if (_isAudioDevice(device)) {
      return 'Audio Device ($shortId)';
    } else if (_isConnectedDevice(device)) {
      return 'Mobile Device ($shortId)';
    } else {
      return 'Bluetooth Device ($shortId)';
    }
  }

  Future<void> _loadMockDevices() async {
    _devicesList = [
      MockBluetoothDevice(
        id: '1',
        name: 'SX-839 Headphones',
        address: '00:11:22:33:44:55',
        isPaired: true,
      ),
      MockBluetoothDevice(
        id: '2',
        name: 'Audio Pro Speaker',
        address: '00:11:22:33:44:66',
        isPaired: true,
      ),
    ];
    notifyListeners();
  }

  Future<void> _loadMockDevicesWithConnection() async {
    _devicesList = [
      MockBluetoothDevice(
        id: 'system_iphone',
        name: 'Fazil\'s iPhone (Connected)',
        address: 'XX:XX:XX:XX:XX:XX',
        isPaired: true,
        isConnected: true,
      ),
      MockBluetoothDevice(
        id: 'system_airpods',
        name: 'AirPods (System Connected)',
        address: 'XX:XX:XX:XX:XX:XX',
        isPaired: true,
        isConnected: true,
      ),
      MockBluetoothDevice(
        id: '1',
        name: 'SX-839 Headphones',
        address: '00:11:22:33:44:55',
        isPaired: true,
        isConnected: false,
      ),
    ];
    
    // Auto-connect to the iPhone
    _connectedDevice = _devicesList.first;
    _isConnected = true;
    debugPrint('✅ Auto-connected to: ${_connectedDevice!.name}');
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    try {
      _isDiscovering = true;
      _devicesList.clear();
      notifyListeners();

      debugPrint('Starting Bluetooth device discovery...');

      // First get real connected devices
      await _getConnectedDevices();

      // Check if Bluetooth is enabled
      if (_adapterState != BluetoothAdapterState.on) {
        debugPrint('Bluetooth adapter is not on, cannot discover new devices');
        _isDiscovering = false;
        notifyListeners();
        return;
      }

      // Start scanning for new devices
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // Listen to scan results
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          for (ScanResult result in results) {
            if (_isAudioDevice(result.device)) {
              final newDevice = MockBluetoothDevice(
                id: result.device.remoteId.str,
                name: result.device.platformName.isNotEmpty 
                    ? result.device.platformName 
                    : result.advertisementData.advName.isNotEmpty
                        ? result.advertisementData.advName
                        : 'Unknown Device',
                address: result.device.remoteId.str,
                isPaired: false,
              );
              
              // Add only if not already in list
              if (!_devicesList.any((d) => d.id == newDevice.id)) {
                _devicesList.add(newDevice);
                notifyListeners();
                debugPrint('Discovered audio device: ${newDevice.name}');
              }
            }
          }
        },
        onError: (error) {
          debugPrint('Scan results error: $error');
        },
      );

      // Auto-stop scanning after 10 seconds
      Timer(const Duration(seconds: 10), () {
        stopDiscovery();
      });
    } catch (e) {
      _isDiscovering = false;
      notifyListeners();
      debugPrint('Error during discovery: $e');
      // Fallback: try to get any real devices we can detect
      await _getConnectedDevices();
    }
  }

  Future<void> _mockDiscovery() async {
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (timer.tick <= 3) {
        _addMockDevice(timer.tick + 2);
      }
    });

    Timer(const Duration(seconds: 8), () {
      stopDiscovery();
    });
  }

  Future<void> _mockDiscoveryWithConnection() async {
    // Ensure we have connected devices during mock discovery
    if (_devicesList.isEmpty || _connectedDevice == null) {
      await _loadMockDevicesWithConnection();
    }
    
    _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (timer.tick <= 3) {
        _addMockDevice(timer.tick + 2);
      }
    });

    Timer(const Duration(seconds: 8), () {
      stopDiscovery();
    });
  }

  void _addMockDevice(int index) {
    final mockDevices = [
      MockBluetoothDevice(
        id: '3',
        name: 'Wireless Earbuds Pro',
        address: '00:11:22:33:44:77',
        isPaired: false,
      ),
      MockBluetoothDevice(
        id: '4',
        name: 'HD Audio Headset',
        address: '00:11:22:33:44:88',
        isPaired: false,
      ),
      MockBluetoothDevice(
        id: '5',
        name: 'Bluetooth Speaker',
        address: '00:11:22:33:44:99',
        isPaired: false,
      ),
    ];

    if (index - 3 < mockDevices.length) {
      final device = mockDevices[index - 3];
      if (!_devicesList.any((d) => d.id == device.id)) {
        _devicesList.add(device);
        notifyListeners();
        debugPrint('Discovered device: ${device.name}');
      }
    }
  }

  Future<void> stopDiscovery() async {
    try {
      _discoveryTimer?.cancel();
      _scanResultsSubscription?.cancel();
      await FlutterBluePlus.stopScan();
      _isDiscovering = false;
      notifyListeners();
      debugPrint('Stopped Bluetooth device discovery');
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  Future<bool> connectToDevice(MockBluetoothDevice device) async {
    if (_isConnecting || _isConnected) return false;

    try {
      _isConnecting = true;
      notifyListeners();

      // Find the actual Bluetooth device
      BluetoothDevice? bluetoothDevice;
      
      // Try to create BluetoothDevice from device ID (MAC address)
      try {
        bluetoothDevice = BluetoothDevice.fromId(device.id);
      } catch (e) {
        debugPrint('Could not create device from ID: $e');
      }
      
      // If not found in scan results, try to get from connected devices
      if (bluetoothDevice == null) {
        final connectedDevices = FlutterBluePlus.connectedDevices;
        for (final connectedDevice in connectedDevices) {
          if (connectedDevice.remoteId.str == device.id) {
            bluetoothDevice = connectedDevice;
            break;
          }
        }
      }
      
      if (bluetoothDevice == null) {
        debugPrint('Bluetooth device not found');
        _isConnecting = false;
        notifyListeners();
        return false;
      }

      // Connect to the device
      await bluetoothDevice.connect(timeout: const Duration(seconds: 15));
      
      // Update connection state
      device.isConnected = true;
      _connectedDevice = device;
      _connectedBluetoothDevice = bluetoothDevice;
      _isConnected = true;
      _isConnecting = false;
      notifyListeners();
      
      debugPrint('Connected to ${device.name}');
      return true;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
    }

    _isConnecting = false;
    notifyListeners();
    return false;
  }

  Future<void> disconnect() async {
    try {
      if (_connectedBluetoothDevice != null) {
        await _connectedBluetoothDevice!.disconnect();
      }
      
      if (_connectedDevice?.isConnected == true) {
        _connectedDevice!.isConnected = false;
      }
      
      _connectedDevice = null;
      _connectedBluetoothDevice = null;
      _isConnected = false;
      notifyListeners();
      
      debugPrint('Disconnected from Bluetooth device');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  // Public method for backward compatibility
  Future<void> getPairedDevices() async {
    await _attemptRealDeviceDetection();
  }

  // Check if we have the necessary permissions
  Future<bool> hasBluetoothPermissions() async {
    try {
      final status = await Permission.bluetoothConnect.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // Open app settings if permissions are denied
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  Future<void> sendData(String data) async {
    if (_connectedBluetoothDevice != null && _connectedDevice?.isConnected == true) {
      try {
        debugPrint('Sending data to ${_connectedDevice!.name}: $data');
        // Note: Actual data sending would require discovering services and characteristics
        // This is a placeholder for EQ data transmission
      } catch (e) {
        debugPrint('Error sending data: $e');
      }
    }
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    disconnect();
    super.dispose();
  }
}