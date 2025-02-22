import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> _getDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'downloads.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE downloads(exerciseId TEXT PRIMARY KEY, title TEXT, description TEXT, totalQuestions INTEGER)',
        );
        await db.execute(
          'CREATE TABLE questions(id INTEGER PRIMARY KEY AUTOINCREMENT, exerciseId TEXT, questionText TEXT, A TEXT, B TEXT, C TEXT, D TEXT, correctAnswer TEXT, FOREIGN KEY(exerciseId) REFERENCES downloads(exerciseId))',
        );
      },
      version: 1,
    );
  }

  static Future<bool> isDownloaded(String exerciseId) async {
    final db = await _getDatabase();
    final result = await db.query('downloads', where: 'exerciseId = ?', whereArgs: [exerciseId]);
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getDownloadedExercises() async {
    final db = await _getDatabase();
    return await db.query('downloads');
  }

  static Future<List<Map<String, dynamic>>> getExerciseQuestions(String exerciseId) async {
    final db = await _getDatabase();
    return await db.query('questions', where: 'exerciseId = ?', whereArgs: [exerciseId]);
  }

  static Future<void> saveDownloadedExercise(Map<String, dynamic> exercise, List<Map<String, dynamic>> questions) async {
    final db = await _getDatabase();
    await db.transaction((txn) async {
      await txn.insert('downloads', exercise, conflictAlgorithm: ConflictAlgorithm.replace);
      for (var question in questions) {
        await txn.insert('questions', {
          'exerciseId': exercise['exerciseId'],
          ...question,
        });
      }
    });
  }

 static Future<void> removeDownloadedExercise(String exerciseId) async {
  final db = await _getDatabase();
  await db.transaction((txn) async {
    int rowsDeleted = await txn.delete('downloads', where: 'exerciseId = ?', whereArgs: [exerciseId]);
    await txn.delete('questions', where: 'exerciseId = ?', whereArgs: [exerciseId]);
    debugPrint("Rows deleted from downloads: $rowsDeleted"); // Add this to DatabaseHelper
  });
}
}