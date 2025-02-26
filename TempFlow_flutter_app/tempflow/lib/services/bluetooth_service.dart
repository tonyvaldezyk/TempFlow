import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import '../utils/bluetooth_constants.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  fbp.BluetoothDevice? device;
  fbp.BluetoothCharacteristic? _temperatureCharacteristic;
  fbp.BluetoothCharacteristic? _batteryCharacteristic;

  final _temperatureController = StreamController<double>.broadcast();
  final _batteryController = StreamController<double>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  bool _isConnected = false;

  Stream<double> get temperatureStream => _temperatureController.stream;
  Stream<double> get batteryStream => _batteryController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
      ].request();

      developer.log('Statuts des permissions: $statuses');

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          developer.log('Permission non accordée: $permission');
          allGranted = false;
        }
      });

      return allGranted;
    } catch (e) {
      developer.log('Erreur lors de la demande des permissions: $e');
      return false;
    }
  }

  Future<bool> isBluetoothAvailable() async {
    try {
      final isAvailable = await fbp.FlutterBluePlus.isAvailable;
      developer.log('Bluetooth disponible: $isAvailable');
      return isAvailable;
    } catch (e) {
      developer.log('Erreur lors de la vérification de la disponibilité Bluetooth: $e');
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      final state = await fbp.FlutterBluePlus.adapterState.first;
      developer.log('État Bluetooth: $state');
      return state == fbp.BluetoothAdapterState.on;
    } catch (e) {
      developer.log('Erreur lors de la vérification de l\'état Bluetooth: $e');
      return false;
    }
  }

  Future<void> enableBluetooth() async {
    try {
      await fbp.FlutterBluePlus.turnOn();
      developer.log('Demande d\'activation Bluetooth envoyée');
    } catch (e) {
      developer.log('Erreur lors de l\'activation Bluetooth: $e');
      throw Exception("Impossible d'activer le Bluetooth");
    }
  }

  Future<bool> startScan() async {
    try {
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        developer.log('Permissions non accordées');
        throw Exception("Permissions Bluetooth non accordées");
      }

      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        developer.log('Bluetooth non activé');
        throw Exception("Bluetooth is turned off");
      }

      developer.log('Démarrage du scan Bluetooth...');
      await fbp.FlutterBluePlus.startScan(
        timeout: Duration(seconds: BluetoothConstants.SCAN_TIMEOUT),
        withServices: [
          fbp.Guid(BluetoothConstants.SERVICE_UUID),
        ],
        androidUsesFineLocation: true,
      );

      fbp.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          developer.log('Périphérique trouvé: ${result.device.platformName} (${result.device.remoteId}), RSSI: ${result.rssi}');
        }
      }, onError: (error) {
        developer.log('Erreur lors de l\'écoute des résultats du scan: $error');
      });

      return true;
    } catch (e) {
      developer.log('Erreur lors du scan: $e');
      throw Exception("Erreur de scan: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
      developer.log('Scan Bluetooth arrêté');
    } catch (e) {
      developer.log('Erreur lors de l\'arrêt du scan: $e');
    }
  }

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    try {
      await device.connect();
      this.device = device;
      _isConnected = true;
      _connectionController.add(true);
      developer.log('Connecté au périphérique: ${device.platformName}');

      final services = await device.discoverServices();
      developer.log('Services découverts: ${services.length}');

      for (var service in services) {
        developer.log('Service trouvé: ${service.uuid.str}');
        if (service.uuid.str == BluetoothConstants.SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.str == BluetoothConstants.TEMPERATURE_CHARACTERISTIC_UUID) {
              _temperatureCharacteristic = characteristic;
              await setupTemperatureNotifications();
            } else if (characteristic.uuid.str == BluetoothConstants.BATTERY_CHARACTERISTIC_UUID) {
              _batteryCharacteristic = characteristic;
              await setupBatteryNotifications();
            }
          }
        }
      }
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      developer.log('Erreur lors de la connexion: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<void> setupTemperatureNotifications() async {
    if (_temperatureCharacteristic != null) {
      developer.log('Configuration des notifications de température');
      _temperatureCharacteristic!.value.listen(
        (value) {
          developer.log('Données brutes température reçues: ${value.toString()}');
          if (value.length >= 2) {
            try {
              // Lecture du SINT16 (LSB first)
              int tempRaw = (value[1] << 8) | value[0];
              // Conversion en température (division par 100 car multiplié par 100 côté ESP32)
              double temp = tempRaw / 100.0;
              developer.log('Température parsée avec succès: $temp°C (raw: $tempRaw)');
              _temperatureController.add(temp);
            } catch (e) {
              developer.log('Erreur lors du traitement de la température: $e');
            }
          } else {
            developer.log('Données de température invalides (longueur < 2 bytes)');
          }
        },
        onError: (error) {
          developer.log('Erreur sur le stream de température: $error');
        },
      );
      await _temperatureCharacteristic!.setNotifyValue(true);
      developer.log('Notifications de température activées');
    } else {
      developer.log('Erreur: Caractéristique de température non initialisée');
      throw Exception(BluetoothConstants.ERROR_READING_TEMPERATURE);
    }
  }

  Future<void> setupBatteryNotifications() async {
    if (_batteryCharacteristic != null) {
      developer.log('Configuration des notifications de batterie');
      _batteryCharacteristic!.value.listen(
        (value) {
          developer.log('Données brutes batterie reçues: ${value.toString()}');
          if (value.isNotEmpty) {
            try {
              // Lecture directe du UINT8
              int battery = value[0];
              developer.log('Niveau de batterie parsé avec succès: $battery%');
              _batteryController.add(battery.toDouble());
            } catch (e) {
              developer.log('Erreur lors du traitement du niveau de batterie: $e');
            }
          } else {
            developer.log('Données de batterie vides reçues');
          }
        },
        onError: (error) {
          developer.log('Erreur sur le stream de batterie: $error');
        },
      );
      await _batteryCharacteristic!.setNotifyValue(true);
      developer.log('Notifications de batterie activées');
    } else {
      developer.log('Erreur: Caractéristique de batterie non initialisée');
      throw Exception(BluetoothConstants.ERROR_READING_BATTERY);
    }
  }

  Future<void> disconnect() async {
    if (device != null) {
      await device!.disconnect();
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void dispose() {
    _temperatureController.close();
    _batteryController.close();
    _connectionController.close();
    disconnect();
  }
}
