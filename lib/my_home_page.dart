import 'package:flutter/material.dart';
import 'dart:math';

import 'package:db_demo/device_info_model.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late DeviceInfoModel deviceModel;
  String deviceName = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    deviceModel = await DeviceInfoModel.getModelWithDeviceSn('sn20250106');
    setState(() {
      deviceName = deviceModel.deviceName;
    });
  }

  updateDeviceInfo() {
    int randomInt = Random().nextInt(100);
    String name = 'test$randomInt';
    // DeviceInfoModel.updateDeviceName(deviceModel.deviceSn, name);
    // DeviceInfoModel.updateDeviceNameV2(deviceModel.deviceSn, name, 'mac${Random().nextInt(100)}');
    DeviceInfoModel.updateDeviceNameV2('sn20250107', name, 'mac${Random().nextInt(100)}');
    setState(() {
      deviceName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Text(
          deviceName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: updateDeviceInfo,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
