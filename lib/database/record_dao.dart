import 'package:sqflite/sqflite.dart';
import '../models/divination_record.dart';
import 'database_helper.dart';

/// 起卦记录数据访问对象
/// 提供 CRUD 操作
class RecordDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// 插入新记录
  Future<int> insert(DivinationRecord record) async {
    final db = await _dbHelper.database;
    final json = record.toJson();

    // 移除 id 字段（由数据库自动生成）
    json.remove('id');

    return await db.insert(
      DatabaseHelper.tableRecords,
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 更新记录
  Future<int> update(DivinationRecord record) async {
    if (record.id == null) return 0;

    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableRecords,
      record.toJson(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  /// 更新解卦内容
  Future<int> updateInterpretation(int id, String interpretation) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.tableRecords,
      {'interpretation': interpretation},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除记录
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除多条记录
  Future<int> deleteMultiple(List<int> ids) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.tableRecords,
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// 获取单个记录
  Future<DivinationRecord?> getById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRecords,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return DivinationRecord.fromJson(maps.first);
  }

  /// 获取所有记录（按时间倒序）
  Future<List<DivinationRecord>> getAll() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRecords,
      orderBy: 'createdAt DESC',
    );

    return maps.map((json) => DivinationRecord.fromJson(json)).toList();
  }

  /// 搜索记录（按问题、起卦人姓名）
  Future<List<DivinationRecord>> search(String keyword) async {
    if (keyword.isEmpty) {
      return await getAll();
    }

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRecords,
      // 使用驼峰列名（与数据库表定义一致）
      where: 'question LIKE ? OR querentName LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'createdAt DESC',
    );

    return maps.map((json) => DivinationRecord.fromJson(json)).toList();
  }

  /// 获取记录总数
  Future<int> getCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableRecords}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 获取指定时间范围内的记录
  Future<List<DivinationRecord>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableRecords,
      where: 'div_time >= ? AND div_time <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );

    return maps.map((json) => DivinationRecord.fromJson(json)).toList();
  }
}