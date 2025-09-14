import 'dart:io';

import 'package:hunter_report/models/hunter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/hunt_report.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static const String _hunterTable = 'hunter';
  static const String _huntReportTable = 'hunt_reports';
  static const String _huntedAnimalTable = 'hunted_animals';

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hunter_report.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Hunter
        await db.execute('''
          CREATE TABLE $_hunterTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            address TEXT,
            hunterCode TEXT
          )
        ''');

        // HuntReportテーブル
        await db.execute('''
          CREATE TABLE $_huntReportTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            location TEXT,
            meshNumber TEXT,
            dateTime TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');

        // HuntedAnimalテーブル
        await db.execute('''
          CREATE TABLE $_huntedAnimalTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            reportId TEXT,
            animalType TEXT,
            gunCount INTEGER,
            snareCount INTEGER,
            boxTrapCount INTEGER,
            imagePaths TEXT,
            FOREIGN KEY(reportId) REFERENCES $_huntReportTable(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<Hunter?> getHunter() async {
    final db = await database;
    final result = await db.query(_hunterTable, limit: 1);
    if (result.isNotEmpty) {
      return Hunter.fromMap(result.first);
    }
    return null;
  }

  Future<void> upsertHunter({
    required String name,
    required String address,
    required String hunterCode,
  }) async {
    final db = await database;
    // 既存レコードがあるか確認
    final existing = await db.query(_hunterTable, limit: 1);
    if (existing.isNotEmpty) {
      // 既存レコードのidを取得して更新
      final id = existing.first['id'];
      await db.update(
        _hunterTable,
        {
          'name': name,
          'address': address,
          'hunterCode': hunterCode,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // 新規挿入
      await db.insert(
        _hunterTable,
        {
          'name': name,
          'address': address,
          'hunterCode': hunterCode,
        },
      );
    }
  }

  Future<void> insertHuntReport(HuntReport report) async {
    final db = await database;
    final id = await db.insert(
      _huntReportTable,
      {
        'location': report.location,
        'meshNumber': report.meshNumber,
        'dateTime': report.dateTime.toIso8601String(),
        'latitude': report.latitude,
        'longitude': report.longitude,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (id == 0) {
      return;
    }

    // HuntedAnimalsを挿入
    for (final item in report.huntedAnimals) {
      await db.insert(
        _huntedAnimalTable,
        {
          'reportId': id,
          'animalType': item.animalType,
          'gunCount': item.gunCount,
          'snareCount': item.snareCount,
          'boxTrapCount': item.boxTrapCount,
          'imagePaths': item.imagePaths.join(','), // カンマ区切りで保存
        },
      );
    }
  }

  Future<List<HuntReport>> getAllHuntReports() async {
    final db = await database;
    final reportMaps = await db.query(_huntReportTable);

    List<HuntReport> reports = [];
    for (final reportMap in reportMaps) {
      final huntedAnimalMaps = await db.query(
        _huntedAnimalTable,
        where: 'reportId = ?',
        whereArgs: [reportMap['id']],
      );
      final huntedAnimals = huntedAnimalMaps.map((itemMap) {
        return HuntedAnimal(
          animalType: itemMap['animalType'] as String,
          gunCount: itemMap['gunCount'] as int,
          snareCount: itemMap['snareCount'] as int,
          boxTrapCount: itemMap['boxTrapCount'] as int,
          imagePaths: (itemMap['imagePaths'] as String).isEmpty
              ? []
              : (itemMap['imagePaths'] as String).split(','),
        );
      }).toList();

      reports.add(
        HuntReport(
          id: reportMap['id'] as int,
          location: reportMap['location'] as String,
          meshNumber: reportMap['meshNumber'] as String?,
          dateTime: DateTime.parse(reportMap['dateTime'] as String),
          huntedAnimals: huntedAnimals,
          latitude: reportMap['latitude'] as double,
          longitude: reportMap['longitude'] as double,
        ),
      );
    }
    return reports;
  }

  Future<void> updateHuntReport(HuntReport report) async {
    final db = await database;

    // 画像ファイルの削除処理
    // 1. 既存のHuntedAnimalのimagePathsを取得
    final oldHuntedAnimalRows = await db.query(
      _huntedAnimalTable,
      where: 'reportId = ?',
      whereArgs: [report.id],
    );

    final oldImagePaths = <String>{};
    for (final row in oldHuntedAnimalRows) {
      final imagePathsString = row['imagePaths'] as String?;
      if (imagePathsString != null && imagePathsString.isNotEmpty) {
        oldImagePaths.addAll(imagePathsString.split(',').where((p) => p.trim().isNotEmpty));
      }
    }

    await db.update(
      _huntReportTable,
      {
        'location': report.location,
        'meshNumber': report.meshNumber,
        'dateTime': report.dateTime.toIso8601String(),
        'latitude': report.latitude,
        'longitude': report.longitude,
      },
      where: 'id = ?',
      whereArgs: [report.id],
    );

    // 既存のHuntedAnimalsを削除して再挿入
    await db.delete(_huntedAnimalTable, where: 'reportId = ?', whereArgs: [report.id]);
    for (final item in report.huntedAnimals) {
      await db.insert(
        _huntedAnimalTable,
        {
          'reportId': report.id,
          'animalType': item.animalType,
          'gunCount': item.gunCount,
          'snareCount': item.snareCount,
          'boxTrapCount': item.boxTrapCount,
          'imagePaths': item.imagePaths.join(','),
        },
      );
    }

    // 2. 新しいHuntedAnimalのimagePathsを取得
    final newImagePaths = <String>{};
    for (final item in report.huntedAnimals) {
      newImagePaths.addAll(item.imagePaths.where((p) => p.trim().isNotEmpty));
    }

    // 3. oldImagePathsからnewImagePathsに存在しないものを削除対象とする
    final deletedImagePaths = oldImagePaths.difference(newImagePaths);

    for (final path in deletedImagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error deleting image file: $e');
      }
    }
  }

  Future<void> deleteHuntReport(int id) async {
    final db = await database;
    await db.delete(_huntReportTable, where: 'id = ?', whereArgs: [id]);
    // HuntedAnimalsはON DELETE CASCADEで自動削除

    // HuntReportに紐づくHuntedAnimalの画像ファイルも削除
    final huntedAnimalRows = await db.query(
      _huntedAnimalTable,
      where: 'reportId = ?',
      whereArgs: [id],
    );

    for (final huntedAnimal in huntedAnimalRows) {
      final imagePathsString = huntedAnimal['imagePaths'] as String?;
      if (imagePathsString != null && imagePathsString.isNotEmpty) {
        final imagePaths = imagePathsString.split(',');
        for (final path in imagePaths) {
          if (path.trim().isNotEmpty) {
            try {
              final file = File(path);
              if (await file.exists()) {
                await file.delete();
              }
            } catch (e) {
              // ignore: avoid_print
              print('Error deleting image file: $e');
            }
          }
        }
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
