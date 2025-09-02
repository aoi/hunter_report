import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hunt_report.dart';

class HuntReportProvider with ChangeNotifier {
  List<HuntReport> _reports = [];
  static const String _storageKey = 'hunt_reports';

  List<HuntReport> get reports => List.unmodifiable(_reports);

  HuntReportProvider() {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = prefs.getStringList(_storageKey) ?? [];
      _reports = reportsJson
          .map((json) => HuntReport.fromJson(jsonDecode(json)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reports: $e');
    }
  }

  Future<void> _saveReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reportsJson = _reports
          .map((report) => jsonEncode(report.toJson()))
          .toList();
      await prefs.setStringList(_storageKey, reportsJson);
    } catch (e) {
      debugPrint('Error saving reports: $e');
    }
  }

  Future<void> addReport(HuntReport report) async {
    _reports.add(report);
    await _saveReports();
    notifyListeners();
  }

  Future<void> updateReport(HuntReport report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
      await _saveReports();
      notifyListeners();
    }
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    await _saveReports();
    notifyListeners();
  }

  Future<void> addGameItem(String reportId, GameItem gameItem) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      final report = _reports[index];
      final updatedGameItems = List<GameItem>.from(report.gameItems)..add(gameItem);
      _reports[index] = report.copyWith(gameItems: updatedGameItems);
      await _saveReports();
      notifyListeners();
    }
  }

  Future<void> updateGameItem(String reportId, int gameItemIndex, GameItem gameItem) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1 && gameItemIndex < _reports[index].gameItems.length) {
      final report = _reports[index];
      final updatedGameItems = List<GameItem>.from(report.gameItems);
      updatedGameItems[gameItemIndex] = gameItem;
      _reports[index] = report.copyWith(gameItems: updatedGameItems);
      await _saveReports();
      notifyListeners();
    }
  }

  Future<void> deleteGameItem(String reportId, int gameItemIndex) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1 && gameItemIndex < _reports[index].gameItems.length) {
      final report = _reports[index];
      final updatedGameItems = List<GameItem>.from(report.gameItems)..removeAt(gameItemIndex);
      _reports[index] = report.copyWith(gameItems: updatedGameItems);
      await _saveReports();
      notifyListeners();
    }
  }

  Future<void> deleteImage(String reportId, int gameItemIndex, String imagePath) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1 && gameItemIndex < _reports[index].gameItems.length) {
      final report = _reports[index];
      final gameItem = report.gameItems[gameItemIndex];
      final updatedImagePaths = gameItem.imagePaths.where((path) => path != imagePath).toList();
      final updatedGameItem = gameItem.copyWith(imagePaths: updatedImagePaths);
      
      final updatedGameItems = List<GameItem>.from(report.gameItems);
      updatedGameItems[gameItemIndex] = updatedGameItem;
      _reports[index] = report.copyWith(gameItems: updatedGameItems);
      
      await _saveReports();
      notifyListeners();
      
      // ファイルを削除
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting image file: $e');
      }
    }
  }
}

