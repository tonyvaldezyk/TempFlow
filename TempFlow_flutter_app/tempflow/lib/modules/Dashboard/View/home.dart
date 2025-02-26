import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../services/bluetooth_service.dart';
import '../../../utils/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import '../Controller/controller.dart';
import '../../Bluetooth/View/bluetooth_connection.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BluetoothService _bluetoothService = BluetoothService();
  final DashboardController _controller = DashboardController();
  double _currentTemperature = 0.0;
  double _currentBattery = 0.0;
  List<FlSpot> _temperatureData = [];

  @override
  void initState() {
    super.initState();
    _setupStreams();
    _checkInitialConnection();
  }

  void _checkInitialConnection() async {
    if (!_bluetoothService.isConnected) {
      await _controller.startScanning();
    }
  }

  void _setupStreams() {
    _bluetoothService.temperatureStream.listen((temp) {
      developer.log('HomePage: Température reçue: $temp°C');
      setState(() {
        _currentTemperature = temp;
        _temperatureData.add(FlSpot(
          _temperatureData.length.toDouble(),
          temp,
        ));
        if (_temperatureData.length > 20) {
          _temperatureData.removeAt(0);
        }
      });
    }, onError: (error) {
      developer.log('Erreur stream température: $error');
    });

    _bluetoothService.batteryStream.listen((battery) {
      developer.log('HomePage: Batterie reçue: $battery%');
      setState(() {
        _currentBattery = battery;
      });
    }, onError: (error) {
      developer.log('Erreur stream batterie: $error');
    });

    _bluetoothService.connectionStream.listen((connected) {
      developer.log('HomePage: État de connexion changé: $connected');
      if (!connected) {
        setState(() {
          _currentTemperature = 0.0;
          _currentBattery = 0.0;
          _temperatureData.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    developer.log('Disposing HomePage');
    _bluetoothService.temperatureStream.drain();
    _bluetoothService.batteryStream.drain();
    _bluetoothService.connectionStream.drain();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TempFlow',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_connected, color: Colors.orange),
            onPressed: () async {
              await _bluetoothService.disconnect();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothConnectionScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTemperatureCard(),
              const SizedBox(height: 24),
              _buildBatteryCard(),
              const SizedBox(height: 24),
              _buildTemperatureGraph(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemperatureCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Température',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.thermostat,
                color: Colors.orange.withOpacity(0.8),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentTemperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Batterie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.battery_charging_full,
                color: Colors.orange.withOpacity(0.8),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_currentBattery.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _currentBattery / 100,
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getBatteryColor(_currentBattery),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureGraph() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _temperatureData,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(double level) {
    if (level > 60) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
}
