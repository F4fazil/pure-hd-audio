class MockBluetoothDevice {
  final String id;
  final String name;
  final String address;
  final int? rssi;
  bool isPaired;
  bool isConnected;
  final dynamic realDevice;
  final bool isClassicBluetooth; // Add flag for Classic Bluetooth

  MockBluetoothDevice({
    required this.id,
    required this.name,
    required this.address,
    this.rssi,
    this.isPaired = false,
    this.isConnected = false,
    this.realDevice,
    this.isClassicBluetooth = false, // Default to false (BLE)
  });

  // If you have a copyWith method, update it too:
  MockBluetoothDevice copyWith({
    String? id,
    String? name,
    String? address,
    int? rssi,
    bool? isPaired,
    bool? isConnected,
    dynamic realDevice,
    bool? isClassicBluetooth,
  }) {
    return MockBluetoothDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      isPaired: isPaired ?? this.isPaired,
      isConnected: isConnected ?? this.isConnected,
      realDevice: realDevice ?? this.realDevice,
      isClassicBluetooth: isClassicBluetooth ?? this.isClassicBluetooth,
    );
  }
}
