class MockBluetoothDevice {
  final String id;
  final String name;
  final String address;
  final bool isPaired;
  bool isConnected;

  MockBluetoothDevice({
    required this.id,
    required this.name,
    required this.address,
    this.isPaired = false,
    this.isConnected = false,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MockBluetoothDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}