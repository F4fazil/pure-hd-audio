// // ignore_for_file: deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BleScannerPage extends StatefulWidget {
//   const BleScannerPage({super.key});

//   @override
//   State<BleScannerPage> createState() => _BleScannerPageState();
// }

// class _BleScannerPageState extends State<BleScannerPage> {
//   final FlutterBluePlus flutterBlue = FlutterBluePlus();
//   List<ScanResult> scanResults = [];
//   bool isScanning = false;

//   @override
//   void dispose() {
//     FlutterBluePlus.stopScan();
//     super.dispose();
//   }

//   Future<void> startScan() async {
//     // Request permissions
//     await Permission.bluetoothScan.request();
//     await Permission.bluetoothConnect.request();
//     await Permission.location.request();

//     setState(() => isScanning = true);
//     scanResults.clear();

//     FlutterBluePlus.scanResults.listen((results) {
//       setState(() => scanResults = results);
//     });

//     await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
//     setState(() => isScanning = false);
//   }

//   Future<void> connectToDevice(BluetoothDevice device) async {
//     await device.connect(timeout: const Duration(seconds: 15));
//     device.state.listen((state) {
//       if (state == BluetoothDeviceState.connected) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('BLE Scanner')),
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: isScanning ? null : startScan,
//             child: Text(isScanning ? 'Scanning...' : 'Scan'),
//           ),
//           Expanded(
//             child: scanResults.isEmpty
//                 ? const Center(child: Text('No Device Found'))
//                 : ListView.builder(
//                     itemCount: scanResults.length,
//                     itemBuilder: (context, index) {
//                       final result = scanResults[index];
//                       return Card(
//                         child: ListTile(
//                           title: Text(
//                             result.device.name.isNotEmpty
//                                 ? result.device.name
//                                 : 'Unknown Device',
//                           ),
//                           subtitle: Text(result.device.remoteId.str),
//                           trailing: Text(result.rssi.toString()),
//                           onTap: () => connectToDevice(result.device),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
