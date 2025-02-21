import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'downloads.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE downloads(exerciseId TEXT PRIMARY KEY, title TEXT, description TEXT, totalQuestions INTEGER)',
        );
      },
      version: 1,
    );
  }

  /// ✅ **Check if an exercise is downloaded**
  static Future<bool> isDownloaded(String exerciseId) async {
    final db = await _getDatabase();
    final result = await db.query('downloads', where: 'exerciseId = ?', whereArgs: [exerciseId]);
    return result.isNotEmpty;
  }

  /// ✅ **Get all downloaded exercises**
  static Future<List<Map<String, dynamic>>> getDownloadedExercises() async {
    final db = await _getDatabase();
    return await db.query('downloads');
  }

  /// ✅ **Save an exercise to local storage**
  static Future<void> saveDownloadedExercise(Map<String, dynamic> exercise) async {
    final db = await _getDatabase();
    await db.insert('downloads', exercise, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// ✅ **Remove a downloaded exercise**
  static Future<void> removeDownloadedExercise(String exerciseId) async {
    final db = await _getDatabase();
    await db.delete('downloads', where: 'exerciseId = ?', whereArgs: [exerciseId]);
  }
}