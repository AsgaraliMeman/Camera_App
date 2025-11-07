import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static Database? _database;
  static const String imagesTable = "images";
  static const String recentlyDeletedTable = "recently_deleted";

  Future<Database> get database async {
    if (_database != null) return _database!;
    return await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'images.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE $imagesTable(id INTEGER PRIMARY KEY AUTOINCREMENT, imagePath TEXT)"
        );
        await db.execute(
          "CREATE TABLE $recentlyDeletedTable(id INTEGER PRIMARY KEY AUTOINCREMENT, imagePath TEXT, deleted_at INTEGER)"
        );
      },
    );
  }

  Future<void> insertImage(String imagePath) async {
    final db = await database;
    await db.insert(imagesTable, {"imagePath": imagePath});
  }

  Future<List<Map<String, dynamic>>> getImages() async {
    final db = await database;
    return await db.query(imagesTable);
  }

  // Move image to Recently Deleted
  Future<void> addToRecentlyDeleted(String imagePath) async {
    final db = await database;
    await db.insert(
      recentlyDeletedTable,
      {'imagePath': imagePath, 'deleted_at': DateTime.now().millisecondsSinceEpoch},
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyDeleted() async {
    final db = await database;
    return await db.query(recentlyDeletedTable);
  }

  // Automatically delete images older than 7 days
  Future<void> deleteExpiredImages() async {
    final db = await database;
    int sevenDaysAgo = DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch;

    List<Map<String, dynamic>> expiredImages = await db.query(
      recentlyDeletedTable,
      where: 'deleted_at < ?',
      whereArgs: [sevenDaysAgo],
    );

    for (var image in expiredImages) {
      String imagePath = image['imagePath'] as String;
      _deleteFileFromStorage(imagePath);
    }

    await db.delete(
      recentlyDeletedTable,
      where: 'deleted_at < ?',
      whereArgs: [sevenDaysAgo],
    );
  }

  // Permanently delete an image from all locations
  Future<void> deleteImagePermanently(String imagePath) async {
    final db = await database;

    await db.delete(recentlyDeletedTable, where: "imagePath = ?", whereArgs: [imagePath]);
    await db.delete(imagesTable, where: "imagePath = ?", whereArgs: [imagePath]);

    _deleteFileFromStorage(imagePath);
  }

  // Restore an image from Recently Deleted back to the main gallery
  Future<void> restoreImage(String imagePath) async {
    final db = await database;

    await db.delete(recentlyDeletedTable, where: "imagePath = ?", whereArgs: [imagePath]);

    List<Map<String, dynamic>> existingImage = await db.query(
      imagesTable,
      where: "imagePath = ?",
      whereArgs: [imagePath],
    );

    if (existingImage.isEmpty) {
      await db.insert(imagesTable, {"imagePath": imagePath});
    }
  }

  // Helper function to delete image file from storage
  void _deleteFileFromStorage(String imagePath) {
    File file = File(imagePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}
