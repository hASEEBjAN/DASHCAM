import 'dart:async';
import 'dart:convert' show utf8;
import '../../models/wifi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../image_streaming/main.dart';

class WifiSetter extends StatefulWidget {
  final String appBarTitle;
  final Wifi wifi;

  WifiSetter(this.wifi, this.appBarTitle);

  @override
  _WifiSetterState createState() =>
      _WifiSetterState(this.wifi, this.appBarTitle);
}

class _WifiSetterState extends State<WifiSetter> {
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String TARGET_DEVICE_NAME = "ESP32 THAT PROJECT";

  String appBarTitle;
  Wifi wifi;
  _WifiSetterState(this.wifi, this.appBarTitle);

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubscription;

  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;

  String connectionText = "";
  @override
  void initState() {
    super.initState();
    startScan();
  }

  startScan() {
    setState(() {
      connectionText = "Start Scanning";
    });

    scanSubscription = flutterBlue.scan().listen((scanResult) {
      print(scanResult.device.name);
      if (scanResult.device.name.contains(TARGET_DEVICE_NAME)) {
        stopScan();

        setState(() {
          connectionText = "Found Target Device";
        });

        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: () => stopScan());
  }

  stopScan(){

    scanSubscription?.cancel();
    scanSubscription = null;
  }

  connectToDevice() async {
    if (targetDevice == null) {
      return;
    }

    setState(() {
      connectionText = "Device Connecting";
    });

    await targetDevice.connect();

    setState(() {
      connectionText = "Device Connected";
    });

    discoverServices();
  }

  disconnectFromDeivce() {
    if (targetDevice == null) {
      return;
    }

    targetDevice.disconnect();

    setState(() {
      connectionText = "Device Disconnected";
    });
  }

  discoverServices() async {
    if (targetDevice == null) {
      return;
    }

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristics) {
          if (characteristics.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristics;
            setState(() {
              connectionText = "All Ready with ${targetDevice.name}";
              writeData('${wifi.ssid},${wifi.password}');
              Navigator.pop(context, true);
            });
          }
        });
      }
    });
  }

  writeData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
  }

  @override
  void dispose() {
    super.dispose();
    if (targetDevice != null){
    targetDevice.disconnect();}
    flutterBlue.stopScan();
    flutterBlue = null;
    debugPrint('dispose ble');
  }

  @override
  Widget build(BuildContext context) {
    return  new Scaffold(
        appBar: AppBar(
          title: Text("ESP BLE Configuration"),
        ),
        body: Container(
          child: targetCharacteristic == null
              ? Center(
                  child: Text(
                    "Waiting...",
                    style: TextStyle(fontSize: 34, color: Colors.red),
                  ),
                )
              : Center(
                  child: Text(
                    connectionText,
                    style: TextStyle(fontSize: 34, color: Colors.green),
                  ),
                ),
        ),
    );
  }
}
