import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/mock_bluetooth_device.dart';

class BluetoothService extends ChangeNotifier {
  bool _isConnecting = false;
  bool _isConnected = false;
  MockBluetoothDevice? _connectedDevice;
  List<MockBluetoothDevice> _devicesList = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  bool get isDiscovering => _isDiscovering;
  MockBluetoothDevice? get connectedDevice => _connectedDevice;
  List<MockBluetoothDevice> get devicesList => List.unmodifiable(_devicesList);

  BluetoothService() {
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      debugPrint('Initializing mock Bluetooth service');
      
      // Simulate getting paired devices
      await getPairedDevices();
    } catch (e) {
      debugPrint('Error initializing Bluetooth: $e');
    }
  }

  Future<void> getPairedDevices() async {
    try {
      // Mock paired devices
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
      debugPrint('Found ${_devicesList.length} paired devices');
    } catch (e) {
      debugPrint('Error getting paired devices: $e');
    }
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    try {
      _isDiscovering = true;
      _devicesList.clear();
      notifyListeners();

      debugPrint('Starting Bluetooth device discovery...');

      // First get paired devices
      await getPairedDevices();

      // Simulate discovering new devices over time
      _discoveryTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        if (timer.tick <= 3) { // Discover 3 additional devices
          _addMockDevice(timer.tick + 2); // Start from ID 3
        }
      });

      // Auto-stop scanning after 8 seconds
      Timer(const Duration(seconds: 8), () {
        stopDiscovery();
      });
    } catch (e) {
      _isDiscovering = false;
      notifyListeners();
      debugPrint('Error during discovery: $e');
    }
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
      _isDiscovering = false;
      notifyListeners();
      debugPrint('Stopped Bluetooth device discovery');
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
    }
  }

  Future<bool> connectToDevice(MockBluetoothDevice device) async {
    if (_isConnecting || _isConnected) return false;

    try {
      _isConnecting = true;
      notifyListeners();

      // Simulate connection delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful connection
      device.isConnected = true;
      _connectedDevice = device;
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
      if (_connectedDevice?.isConnected == true) {
        _connectedDevice!.isConnected = false;
      }
      
      _connectedDevice = null;
      _isConnected = false;
      notifyListeners();
      
      debugPrint('Disconnected from Bluetooth device');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<void> sendData(String data) async {
    if (_connectedDevice?.isConnected == true) {
      try {
        debugPrint('Sending data to ${_connectedDevice!.name}: $data');
        // Simulate sending EQ data to connected device
      } catch (e) {
        debugPrint('Error sending data: $e');
      }
    }
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    disconnect();
    super.dispose();
  }
}