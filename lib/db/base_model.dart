// base_model.dart
export 'package:db_demo/db/data_base_helper.dart';
import 'package:db_demo/db/data_base_helper.dart';

abstract class BaseModel<T> {
  int? id;
  String get tableName; // 表名，子类中实现
  String get primaryKey => 'id'; // 子类自定义主键字段名（不过最好不要改）
  List<String> get uniqueList => <String>[]; // UNIQUE 唯一约束数组，子类可实现

  BaseModel() {
    // 初始化逻辑
    createTable(); // 创建表
  }

  /// 创建表
  Future<void> createTable() async {
    try {
      await DatabaseHelper().execute(createTableSQL);
      await _addMissingColumnsIfNeeded();
    } catch (e) {
      print('Table $tableName already exists or another error occurred: $e');
    }
  }

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

  // ----- 增删改查 -----

  /// 保存 或 插入
  Future<void> save() async {
    print('db insert or update : ${_getType(this)}');
    final db = await DatabaseHelper().database;
    final values = toMap();
    print('db values info : ${values.toString()}');

    try {
      if (values.containsKey(primaryKey) && values[primaryKey] != null) {
        // 更新操作
        await db.update(
          tableName,
          values,
          where: '$primaryKey = ?',
          whereArgs: [values[primaryKey]],
        );
        print('db update data success. id: $id');
      }
      else {
        // 插入操作
        id = await db.insert(
          tableName,
          values,
        );
        print('db insert data success. id: $id');
      }
    } catch (e) {
      print('db insert or update error: $e');
    }
  }

  /// 插入或更新记录 - 不管数据库存在与否，存在更新、不存在就插入；values 是需要更新的数据，调用层需要移除空数据
  Future<void> saveOrUpdate(Map<String, dynamic> values, {String conflictClause = ''}) async {
    print('db insert or update : ${runtimeType.toString()}');
    final db = await DatabaseHelper().database;

    // 获取动态的列名和参数
    final columns = values.keys.join(', ');
    final placeholders = values.keys.map((key) => ':$key').join(', ');
    final updates = values.keys.map((key) => '$key = excluded.$key').join(', ');
    final arguments = values.values.toList();
    conflictClause = conflictClause.isEmpty ? primaryKey : conflictClause;

    try {
      await db.execute('''
      INSERT INTO $tableName ($columns)
      VALUES ($placeholders)
      ON CONFLICT($conflictClause) DO UPDATE SET $updates;
    ''', arguments);

      print('db insert or update data success. id:$id');
    } catch (e) {
      print('db insert or update error: $e');
    }
  }

  /// 默认根据 id 删除
  Future<void> deleteById() async {
    await delete('id = ?', [this.id]);
  }

  /// 删除
  Future<void> delete(String whereClause, [List<Object?>? whereArgs]) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('$tableName db del Error: $e');
    }
  }

  /// 通用的 SQL 查询方法
  Future<List<T>> query({String? where, List<Object?>? whereArgs, String? orderBy,}) async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> result =  await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );

      return result.map((map) => fromMap(map)).toList();
    }
    catch (e) {
      print('$tableName db Query Error: $e');
      return [];
    }
  }

  /// 通用的 SQL 查询方法
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    try {
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> result =  await db.rawQuery(sql);
      return result;
    }
    catch (e) {
      print('$tableName db rawQuery Error: $e');
      return [];
    }
  }

  // ----- about toMap fromMap -----

  /// toMap 方法需要在子类中实现
  Map<String, dynamic> toMap();

  /// 用于从 Map 构造实例的方法，需要在子类中实现
  T fromMap(Map<String, dynamic> map);

  // ----- about Tool -----

  /// 清空所有属性
  void clearModel() {
    Map<String, dynamic> map = toMap();
    map.forEach((key, value) {
      map[key] = null;
    });
    this.fromMap(map);
  }

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

}