import 'package:flutter/foundation.dart';
import '../models/hunt_report.dart';
import '../services/database_helper.dart';

class HuntReportProvider with ChangeNotifier {
  List<HuntReport> _reports = [];

  List<HuntReport> get reports => List.unmodifiable(_reports);

  HuntReportProvider() {
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final dbHelper = DatabaseHelper();
      _reports = await dbHelper.getAllHuntReports();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading reports from DB: $e');
    }
  }

  Future<void> addReport(HuntReport report) async {
    _reports.add(report);
    final dbHelper = DatabaseHelper();
    await dbHelper.insertHuntReport(report);
    notifyListeners();
  }

  Future<void> updateReport(HuntReport report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index != -1) {
      _reports[index] = report;
      final dbHelper = DatabaseHelper();
      await dbHelper.updateHuntReport(report);
      notifyListeners();
    }
  }

  Future<void> deleteReport(int id) async {
    _reports.removeWhere((r) => r.id == id);
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteHuntReport(id);
    notifyListeners();
  }

  // Future<void> addHuntedAnimal(String reportId, HuntedAnimal huntedAnimal) async {
  //   final index = _reports.indexWhere((r) => r.id == reportId);
  //   if (index != -1) {
  //     final report = _reports[index];
  //     final updatedHuntedAnimals = List<HuntedAnimal>.from(report.huntedAnimals)..add(huntedAnimal);
  //     _reports[index] = report.copyWith(huntedAnimals: updatedHuntedAnimals);
  //     await _saveReports();
  //     notifyListeners();
  //   }
  // }

  // Future<void> updateHuntedAnimal(String reportId, int huntedAnimalIndex, HuntedAnimal huntedAnimal) async {
  //   final index = _reports.indexWhere((r) => r.id == reportId);
  //   if (index != -1 && huntedAnimalIndex < _reports[index].huntedAnimals.length) {
  //     final report = _reports[index];
  //     final updatedHuntedAnimals = List<HuntedAnimal>.from(report.huntedAnimals);
  //     updatedHuntedAnimals[huntedAnimalIndex] = huntedAnimal;
  //     _reports[index] = report.copyWith(huntedAnimals: updatedHuntedAnimals);
  //     await _saveReports();
  //     notifyListeners();
  //   }
  // }

  // Future<void> deleteHuntedAnimal(String reportId, int huntedAnimalIndex) async {
  //   final index = _reports.indexWhere((r) => r.id == reportId);
  //   if (index != -1 && huntedAnimalIndex < _reports[index].huntedAnimals.length) {
  //     final report = _reports[index];
  //     final updatedHuntedAnimals = List<HuntedAnimal>.from(report.huntedAnimals)..removeAt(huntedAnimalIndex);
  //     _reports[index] = report.copyWith(huntedAnimals: updatedHuntedAnimals);
  //     await _saveReports();
  //     notifyListeners();
  //   }
  // }

  // Future<void> deleteImage(String reportId, int huntedAnimalIndex, String imagePath) async {
  //   final index = _reports.indexWhere((r) => r.id == reportId);
  //   if (index != -1 && huntedAnimalIndex < _reports[index].huntedAnimals.length) {
  //     final report = _reports[index];
  //     final huntedAnimal = report.huntedAnimals[huntedAnimalIndex];
  //     final updatedImagePaths = huntedAnimal.imagePaths.where((path) => path != imagePath).toList();
  //     final updatedHuntedAnimal = huntedAnimal.copyWith(imagePaths: updatedImagePaths);
      
  //     final updatedHuntedAnimals = List<HuntedAnimal>.from(report.huntedAnimals);
  //     updatedHuntedAnimals[huntedAnimalIndex] = updatedHuntedAnimal;
  //     _reports[index] = report.copyWith(huntedAnimals: updatedHuntedAnimals);
      
  //     await _saveReports();
  //     notifyListeners();
      
  //     // ファイルを削除
  //     try {
  //       final file = File(imagePath);
  //       if (await file.exists()) {
  //         await file.delete();
  //       }
  //     } catch (e) {
  //       debugPrint('Error deleting image file: $e');
  //     }
  //   }
  // }
}

