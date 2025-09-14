class Hunter {
  final int id;
  final String? name;
  final String? address;
  final String? hunterCode;

  Hunter({
    required this.id,
    required this.name,
    this.address,
    this.hunterCode,
  });

  factory Hunter.fromMap(Map<String, dynamic> map) {
    return Hunter(
      id: map['id'] as int,
      name: map['name'] as String?,
      address: map['address'] as String?,
      hunterCode: map['hunterCode'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'hunterCode': hunterCode,
    };
  }
}
