import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../services/bluetooth_service.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/bluetooth_constants.dart';
import '../../Dashboard/View/home.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionScreen> createState() => _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> with SingleTickerProviderStateMixin {
  final BluetoothService _bluetoothService = BluetoothService();
  bool _isScanning = false;
  String _status = 'Vérification du Bluetooth...';
  List<fbp.ScanResult> _devicesList = [];
  bool _isBluetoothEnabled = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBluetoothStatus();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final isAvailable = await _bluetoothService.isBluetoothAvailable();
      if (!isAvailable) {
        setState(() => _status = 'Bluetooth non disponible sur cet appareil');
        return;
      }

      final isEnabled = await _bluetoothService.isBluetoothEnabled();
      setState(() => _isBluetoothEnabled = isEnabled);
      
      if (!isEnabled) {
        setState(() => _status = 'Bluetooth désactivé. Veuillez l\'activer.');
        return;
      }

      _startScan();
    } catch (e) {
      developer.log('Erreur lors de la vérification du statut Bluetooth: $e');
      setState(() => _status = 'Erreur: ${e.toString()}');
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _status = 'Recherche de périphériques...';
      _devicesList.clear();
    });

    try {
      await _bluetoothService.startScan();

      // Écouter les résultats du scan
      fbp.FlutterBluePlus.scanResults.listen((results) {
        developer.log('Résultats du scan reçus: ${results.length} périphériques');
        setState(() {
          _devicesList = results;
          if (_devicesList.isEmpty) {
            _status = 'Aucun périphérique trouvé';
          } else {
            _status = '${_devicesList.length} périphérique(s) trouvé(s)';
          }
        });
      }, onError: (error) {
        developer.log('Erreur lors de l\'écoute des résultats: $error');
        setState(() => _status = 'Erreur de scan: $error');
      });

      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        await _bluetoothService.stopScan();
        setState(() => _isScanning = false);
      }
    } catch (e) {
      developer.log('Erreur lors du scan: $e');
      setState(() {
        _isScanning = false;
        _status = 'Erreur de scan: ${e.toString()}';
      });
    }
  }

  Future<void> _enableBluetooth() async {
    try {
      await _bluetoothService.enableBluetooth();
      await _checkBluetoothStatus();
    } catch (e) {
      developer.log('Erreur lors de l\'activation du Bluetooth: $e');
      setState(() => _status = 'Impossible d\'activer le Bluetooth');
    }
  }

  Future<void> _connectToDevice(fbp.ScanResult result) async {
    setState(() {
      _status = 'Connexion en cours...';
    });

    try {
      await _bluetoothService.connectToDevice(result.device);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
              const HomePage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 1.5,
                    end: 1.0,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Erreur de connexion';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  _isBluetoothEnabled ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                  size: 80,
                  color: _isBluetoothEnabled ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  _isBluetoothEnabled ? 'Recherche de périphériques' : 'Bluetooth désactivé',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 32),
                if (!_isBluetoothEnabled)
                  TextButton(
                    onPressed: _enableBluetooth,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Activer le Bluetooth',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (_isScanning)
                  const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _devicesList.length,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemBuilder: (context, index) {
                      final result = _devicesList[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(
                            result.device.platformName.isEmpty
                                ? 'Inconnu'
                                : result.device.platformName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'Signal: ${result.rssi} dBm',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => _connectToDevice(result),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange.withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Connecter',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!_isScanning && _isBluetoothEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: TextButton(
                      onPressed: _startScan,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Rechercher à nouveau',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
