import 'package:db_demo/db/base_model.dart';

class DeviceInfoModel extends BaseModel {
  String deviceName = ''; // 设备名称
  String deviceSn = ''; // 设备sn
  String mac = ''; // 设备mac

  // ----- about base -----

  // 将模型转换为map
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id, // 注意，这个不要特殊处理。null 或 0 或 其他值 会影响其他逻辑；如果使用插件生成模型要注意下
      'deviceName': deviceName,
      'deviceSn': deviceSn,
      'mac': mac,
    };
  }

  // 从map生成模型实例
  @override
  DeviceInfoModel fromMap(Map<String, dynamic> map) {
    return DeviceInfoModel()
      ..id = map['id']  // 注意，这个不要特殊处理。null 或 0 或 其他值 会影响其他逻辑；如果使用插件生成模型要注意下
      ..deviceName = map['deviceName']
      ..mac = map['mac']??''
      ..deviceSn = map['deviceSn'];
  }


  // ----- about db -----

  @override
  String get tableName => 'device_info';

  @override
  List<String> get uniqueList => ['deviceSn'];

  /// 更新设备名称
  static updateDeviceName(String deviceSn, String name) async {
    DeviceInfoModel model = await getModelWithDeviceSn(deviceSn);
    model.deviceName = name;
    model.save();
  }

  /// 更新设备名称V2
  static updateDeviceNameV2(String deviceSn, String name, String mac) async {
    // 这里不传conflictClause，会根据主键进行唯一处理
    await DeviceInfoModel().saveOrUpdate({
      'deviceSn': deviceSn,
      'deviceName': name,
      'mac': mac,
    }, conflictClause: 'deviceSn');
  }


  /// 通过 deviceSn 查询数据，如果没有初始化一个
  static Future<DeviceInfoModel> getModelWithDeviceSn(String deviceSn) async {
    final result = await DeviceInfoModel().query(
      where: 'deviceSn = ?',
      whereArgs: [deviceSn],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    else {
      return DeviceInfoModel()..deviceSn = deviceSn;
    }
  }

}

