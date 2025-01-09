创建一个 `BaseModel` 类来封装通用的数据库操作，这样可以让 `User` 类和其他模型类专注于具体的数据结构和业务逻辑，同时复用通用的数据库操作代码。下面是如何实现这个方案的详细步骤：

### 1. 创建 `DatabaseHelper` 类

首先，添加 `sqflite` 依赖到 `pubspec.yaml` 文件中。

```
dependencies:
  sqflite: ^2.0.0+4
  path: ^1.8.1
  sqflite_common_ffi: ^2.0.0+4

```

然后，创建一个 `DatabaseHelper` 类来

`DatabaseHelper` 类将负责数据库的初始化和操作，例如打开数据库、执行 SQL 语句等。

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 正确使用 await 获取路径
    String dbPath = await getDatabasesPath();
    print('Database Path: $dbPath');
    return await openDatabase(
      join(await getDatabasesPath(), 'app_database.db'),
      version: 1,
    );
  }

  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    await db.execute(sql, arguments);
  }

  Future<List<Map<String, dynamic>>> query(String sql, [List<Object?>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }
}

```

### 2. 创建 `BaseModel` 类

`BaseModel` 类封装了通用的 CRUD 操作方法。

```dart
import 'database_helper.dart';

abstract class BaseModel {
  String get tableName;
  String get createTableSQL;
  String get primaryKey; // 子类自定义主键字段名

  Map<String, dynamic> toMap();

  Future<void> createTable() async {
    try {
      await DatabaseHelper().execute(createTableSQL);
    } catch (e) {
      print('Table $tableName already exists or another error occurred: $e');
    }
  }

  Future<void> save() async {
    final db = await DatabaseHelper().database;
    final values = toMap();

    try {
      if (values.containsKey(primaryKey) && values[primaryKey] != null) {
        // 更新操作
        await db.update(
          tableName,
          values,
          where: '$primaryKey = ?',
          whereArgs: [values[primaryKey]],
        );
      } else {
        // 插入操作
        await db.insert(
          tableName,
          values,
        );
        print('add data success.');
      }
    } catch (e) {
      print('Database Error: $e');
      // 你可以在这里进一步处理异常
    }
  }

  Future<void> delete(String whereClause, [List<Object?>? whereArgs]) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete(
        tableName,
        where: whereClause,
        whereArgs: whereArgs,
      );
    } catch (e) {
      print('Database Del Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> query({
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    try {
      final db = await DatabaseHelper().database;
      return await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
    } catch (e) {
      print('Database Query Error: $e');
      return [];
    }
  }
}

```

### 3. 创建 `User` 类

`User` 类继承自 `BaseModel` 并实现特定的 SQL 语句和字段。

```dart
import 'package:flutter_db_demo/db_tool/base_model.dart';

class User extends BaseModel {
  int? id;
  String? token;
  String? name;
  String? avatar;

  User() {
    // 实例化时自动创建表
    createTable();
  }

  @override
  String get tableName => 'users';

  @override
  String get createTableSQL => '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      token TEXT,
      name TEXT,
      avatar TEXT
    )
  ''';

  @override
  String get primaryKey => 'id';

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'token': token,
      'name': name,
      'avatar': avatar
    };
  }

  // 示例方法：根据 token 获取用户
  Future<User?> getUserByToken(String token) async {
    final result = await query(
      where: 'token = ?',
      whereArgs: [token],
    );
    if (result.isNotEmpty) {
      return User()
        ..id = result.first['id'] as int?
        ..token = result.first['token'] as String?
        ..name = result.first['name'] as String?
        ..avatar = result.first['avatar'] as String?;
    }
    return null;
  }
}
```

### 4. 使用示例

你可以通过 `User` 类来操作用户数据：

```dart
void main() async {
  		User user = User();
      user.name = 'Tom';
      user.avatar = 'https://xxxxxxx.xxxxx.xxxxx';
      user.token = 'token_abc';
      user.save();
}
```

### 总结

- **`DatabaseHelper`** 类负责数据库的打开和操作。
- **`BaseModel`** 类封装了通用的数据库操作方法，其中 `save` 方法根据主键字段 `id` 判断是否执行插入或更新操作，简化了用户的代码。。
- **`User`** 类继承自 `BaseModel` 并实现具体的表结构和 SQL 操作。

这样设计的好处是 `BaseModel` 提供了通用的 CRUD 操作，可以被多个模型类继承和使用，而具体的 SQL 语句和数据结构由各个模型类定义。



未完待续。。。