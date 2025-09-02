

class GameItem {
  final String animalType;
  final int gunCount;        // 銃器での捕獲頭数
  final int snareCount;      // くくりわなでの捕獲頭数
  final int boxTrapCount;    // 箱わなでの捕獲頭数
  final List<String> imagePaths;

  GameItem({
    required this.animalType,
    required this.gunCount,
    required this.snareCount,
    required this.boxTrapCount,
    required this.imagePaths,
  });

  GameItem copyWith({
    String? animalType,
    int? gunCount,
    int? snareCount,
    int? boxTrapCount,
    List<String>? imagePaths,
  }) {
    return GameItem(
      animalType: animalType ?? this.animalType,
      gunCount: gunCount ?? this.gunCount,
      snareCount: snareCount ?? this.snareCount,
      boxTrapCount: boxTrapCount ?? this.boxTrapCount,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  // 総捕獲頭数を取得
  int get totalCount => gunCount + snareCount + boxTrapCount;

  Map<String, dynamic> toJson() {
    return {
      'animalType': animalType,
      'gunCount': gunCount,
      'snareCount': snareCount,
      'boxTrapCount': boxTrapCount,
      'imagePaths': imagePaths,
    };
  }

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      animalType: json['animalType'],
      gunCount: json['gunCount'] ?? 0,
      snareCount: json['snareCount'] ?? 0,
      boxTrapCount: json['boxTrapCount'] ?? 0,
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
    );
  }
}

class HuntReport {
  final String id;
  final String location;
  final DateTime dateTime;
  final List<GameItem> gameItems;
  final double? latitude;
  final double? longitude;

  HuntReport({
    required this.id,
    required this.location,
    required this.dateTime,
    required this.gameItems,
    this.latitude,
    this.longitude,
  });

  HuntReport copyWith({
    String? id,
    String? location,
    DateTime? dateTime,
    List<GameItem>? gameItems,
    double? latitude,
    double? longitude,
  }) {
    return HuntReport(
      id: id ?? this.id,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      gameItems: gameItems ?? this.gameItems,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'gameItems': gameItems.map((item) => item.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory HuntReport.fromJson(Map<String, dynamic> json) {
    return HuntReport(
      id: json['id'],
      location: json['location'],
      dateTime: DateTime.parse(json['dateTime']),
      gameItems: (json['gameItems'] as List)
          .map((item) => GameItem.fromJson(item))
          .toList(),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

