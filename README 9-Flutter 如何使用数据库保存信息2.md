# Flutter 如何使用数据库保存信息2

 **这篇是对「 Flutter 如何使用数据库保存信息1」 的进一步优化 。**

主要优化点如下：

* **1.增加属性追加功能；**
* **2.增加属性唯一约束设置逻辑；**
* **3.修改创建表sql语句在base_model里面实现；**
* 4.增加配置文件 [db_config.dart](lib%2Fdb%2Fdb_config.dart)；
* 5.增加清空所有属性值方法clearModel；
* 6.增加 通用的 SQL 查询方法；
* 7.增加 插入或更新记录 - 不管数据库存在与否，存在更新、不存在就插入；
  这里说下 save方法 ，是通过判断主键是否有值来决定使用保存还是更新。
* 8.删除不必要依赖`sqflite_common_ffi`；

---------

接下来我们以 [device_info_model.dart](lib%2Fdevice_info_model.dart) 为例说说上面的修改点。



#### 1.增加属性追加功能

新增 `_addMissingColumnsIfNeeded` 方法，在 `createTable` 方法里面执行。方法逻辑读取表字段对比当前模型字段，通过执行sql语句添加缺失的字段。

```dart
  /// 添加缺失的属性
  _addMissingColumnsIfNeeded() async {
    List result = await DatabaseHelper().query("PRAGMA table_info($tableName);");
    List<String> columnNames = [];
    for (var column in result) {
      columnNames.add(column['name'] as String);
    }

    Map<String, String> keyMap = getAllPropertiesWithType();
    keyMap.forEach((key, value) async {
      if (!columnNames.contains(key)) {
        String columnType = dbTypeStrWithType(value); // 根据类型映射获取数据库的列类型
        String alterTableSQL = 'ALTER TABLE $tableName ADD COLUMN $key $columnType';
        await DatabaseHelper().execute(alterTableSQL);
        print('Added missing column: $key $columnType');
      }
    });
  }
```



#### 2.增加属性唯一约束设置逻辑

BaseModel 添加属性 uniqueList , 子类需要重写，然后添加需要设置为唯一的字段。组装创建表sql语句方法里面会判断字段是否为唯一。

注意：目前只支持初始属性唯一约束设置，追加属性无法设置唯一约束，sqllite有限制。尝试过添加唯一索引，失败。

```dart
List<String> get uniqueList => <String>[]; // UNIQUE 唯一约束数组，子类可实现
```

```dart
  /// 创建表sql
  String get createTableSQL => createTableSQL_(tableName, primaryKey);
  String createTableSQL_(String tableName, String primaryKey) {
    Map<String, String> keyMap = getAllPropertiesWithType();
    List<String> columns = [];

    keyMap.forEach((key, value) {
      if (key != primaryKey && value != 'Null') {
        if (uniqueList.contains(key)) {
          columns.add('$key ${dbTypeStrWithType(value)} UNIQUE');
        } else {
          columns.add('$key ${dbTypeStrWithType(value)}');
        }
      }
    });

    String columnsSQL = columns.join(', ');

    return '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $primaryKey INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnsSQL
    );
  ''';
  }
```



#### 3.修改创建表sql语句在base_model里面实现

上一个修改点说明里面的方法 `createTableSQL_` 即为组装创建表sql。通过获取所有字段，以及对应类型和是否唯一。

这里要说的是如何获取所有字段和字段对应类型。下面的三个方法即实现了这个功能，需要注意的是所有字段需要赋初始值，字段类型是根据初始值读取而来。

```dart
  /// 获取所有属性及其类型的方法
  Map<String, String> getAllPropertiesWithType() {
    // 获取子类的 toJson 方法返回的 Map
    final Map<String, dynamic> properties = toMap();

    // 手动定义属性类型映射表
    final Map<String, String> propertyTypes = {
      for (var entry in properties.entries) entry.key: _getType(entry.value),
    };

    return propertyTypes;
  }

  /// 获取属性类型的辅助方法
  String _getType(dynamic value) {
    return value.runtimeType.toString();
  }

  /// 根据数据类型返回对应表类型
  String dbTypeStrWithType(String type) {
    if (type == 'int') {
      return 'INTEGER';
    } else if (type == 'String') {
      return 'TEXT';
    } else if (type == 'double') {
      return 'REAL';
    } else if (type == 'bool') {
      return 'INTEGER';
    }
    return '';
  }
```



#### 4.增加配置文件

 增加配置文件 `db_config.dart` ，目前只配置了表名。



#### 5.增加清空所有属性值方法clearModel

有些单例里面需要通过这种方法清空数据。



#### 6.增加 通用的 SQL 查询方法



#### 7.增加 插入或更新记录

`saveOrUpdate` 首先执行插入操作，如果有 **主键** 或 **唯一字段** 冲突，执行更新；`conflictClause` 参数默认为 `id` ，调用的时候可以指定其他唯一字段。

这里说下 `save` 方法 ，是通过判断主键是否有值来决定使用保存还是更新。两者逻辑上是有区别的。



#### 8.删除不必要依赖`sqflite_common_ffi`

pc平台的插件，暂时不用。






## 其他

模型的创建可通过 JsonToDartBeanAction 这个插件实现，具体用法见：48-Flutter Json转模型-FlutterJsonBeanFactory介绍。

创建好Model之后，修改类继承为BaseModel：
```dart
class XNameModel extends BaseModel
```

继承BaseModel之后会提示需要实现指定方法：
```dart
// ----- about db -----

	@override
	String get tableName => 't_name'; // 表名

	@override
	List<String> get uniqueList => ['valueNo']; // 唯一字段

	@override
  fromMap(Map<String, dynamic> map) {
		XNameModel model = $XNameModelFromJson(map);
		model.id = map.containsKey('id') ? map['id'] as int? : 0;
		return model;
  }

  @override
  Map<String, dynamic> toMap() {
		Map<String, dynamic> map = $XNameModelToJson(this);
		map['id'] = id ?? 0;
		return map;
  }

```
