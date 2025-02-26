import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../../../services/bluetooth_service.dart';
import '../../../utils/bluetooth_constants.dart';

class DashboardController {
  final BluetoothService _bluetoothService = BluetoothService();
  
  Stream<double> get temperatureStream => _bluetoothService.temperatureStream;
  Stream<double> get batteryStream => _bluetoothService.batteryStream;
  Stream<bool> get connectionStream => _bluetoothService.connectionStream;

  Future<void> startScanning() async {
    try {
      await _bluetoothService.startScan();
      
      // Écoute des appareils découverts
      fbp.FlutterBluePlus.scanResults.listen((results) async {
        for (fbp.ScanResult result in results) {
          if (result.device.platformName == BluetoothConstants.DEVICE_NAME) {
            await _bluetoothService.connectToDevice(result.device);
            await fbp.FlutterBluePlus.stopScan();
            break;
          }
        }
      });
    } catch (e) {
      print('Erreur lors du scan: $e');
    }
  }

  Future<void> refreshData() async {
    if (!_bluetoothService.isConnected) {
      await startScanning();
    }
  }

  void dispose() {
    _bluetoothService.dispose();
  }
}
