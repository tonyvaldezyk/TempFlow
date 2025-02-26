# TempFlow

A smart temperature monitoring system combining a Flutter mobile application and an ESP32 microcontroller equipped with an LM35 temperature sensor. The system enables real-time temperature monitoring via Bluetooth Low Energy (BLE).

![TempFlow App](android/assets/images/logo.png)

## Features

- Intuitive user interface built with Flutter
- Real-time temperature measurement using LM35 sensor
- Graphical display of temperature data
- Battery level monitoring
- Bluetooth Low Energy (BLE) communication
- Configurable temperature alerts
- Measurement history

## Technologies Used

### Mobile Application (Flutter)
- Flutter 3.x
- Dart 3.x
- flutter_blue_plus: ^1.x.x
- fl_chart: ^0.x.x
- provider: ^6.x.x
- shared_preferences: ^2.x.x

### Microcontroller (ESP32)
- Arduino Framework
- PlatformIO
- ESP32 BLE Arduino
- FreeRTOS

## Prerequisites

- Flutter SDK
- Android Studio / VS Code
- PlatformIO IDE
- ESP32 DevKit
- LM35 Temperature Sensor
- Git

## Installation

### Flutter Application

1. Clone the repository:
```bash
git clone https://github.com/your-username/TempFlow.git
cd TempFlow/tempflow
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### ESP32 Firmware

1. Open the project in PlatformIO
2. Configure your ESP32's serial port
3. Build and upload the code:
```bash
pio run -t upload
```

## Configuration

### ESP32 Connections
- LM35 Signal -> GPIO34
- Red LED -> GPIO33
- Green LED -> GPIO25

### Bluetooth Configuration
Service and characteristic UUIDs are defined in:
- `lib/utils/bluetooth_constants.dart` (Flutter)
- `src/main.cpp` (ESP32)

## Testing

```bash
# Flutter unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

## Contributing

Contributions are welcome! Feel free to:
1. Fork the project
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Credits

Developed by [Tony Yonke](https://github.com/tonyvaldezyk/)

### Contact
- GitHub: [[tonyvaldezyk/](https://github.com/tonyvaldezyk)]
- LinkedIn: [[Tony Yonke](https://www.linkedin.com/in/tony-yonke-001a59225/)]

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Documentation

For more implementation details, check out:
- [Flutter Documentation](docs/flutter.md)
- [ESP32 Documentation](docs/esp32.md)
- [BLE Protocol](docs/ble_protocol.md)
