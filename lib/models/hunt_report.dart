

class HuntedAnimal {
  final String animalType;
  final int gunCount;        // 銃器での捕獲頭数
  final int snareCount;      // くくりわなでの捕獲頭数
  final int boxTrapCount;    // 箱わなでの捕獲頭数
  final List<String> imagePaths;

  HuntedAnimal({
    required this.animalType,
    required this.gunCount,
    required this.snareCount,
    required this.boxTrapCount,
    required this.imagePaths,
  });

  HuntedAnimal copyWith({
    String? animalType,
    int? gunCount,
    int? snareCount,
    int? boxTrapCount,
    List<String>? imagePaths,
  }) {
    return HuntedAnimal(
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

  factory HuntedAnimal.fromJson(Map<String, dynamic> json) {
    return HuntedAnimal(
      animalType: json['animalType'],
      gunCount: json['gunCount'] ?? 0,
      snareCount: json['snareCount'] ?? 0,
      boxTrapCount: json['boxTrapCount'] ?? 0,
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
    );
  }
}

class HuntReport {
  final int? id;
  final String location;
  final String? meshNumber;
  final DateTime dateTime;
  final List<HuntedAnimal> huntedAnimals;
  final double? latitude;
  final double? longitude;

  HuntReport({
    this.id,
    required this.location,
    this.meshNumber,
    required this.dateTime,
    required this.huntedAnimals,
    this.latitude,
    this.longitude,
  });

  HuntReport copyWith({
    int? id,
    String? location,
    String? meshNumber,
    DateTime? dateTime,
    List<HuntedAnimal>? huntedAnimals,
    double? latitude,
    double? longitude,
  }) {
    return HuntReport(
      id: id ?? this.id,
      location: location ?? this.location,
      meshNumber: meshNumber ?? this.meshNumber,
      dateTime: dateTime ?? this.dateTime,
      huntedAnimals: huntedAnimals ?? this.huntedAnimals,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'meshNumber': meshNumber,
      'dateTime': dateTime.toIso8601String(),
      'huntedAnimals': huntedAnimals.map((item) => item.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory HuntReport.fromJson(Map<String, dynamic> json) {
    return HuntReport(
      id: json['id'],
      location: json['location'],
      meshNumber: json['meshNumber'],
      dateTime: DateTime.parse(json['dateTime']),
      huntedAnimals: (json['huntedAnimals'] as List)
          .map((item) => HuntedAnimal.fromJson(item))
          .toList(),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

