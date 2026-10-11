class Location {
  final String id;
  final String name;
  final String description;
  final double difficulty;
  final bool unlocked;
  final String themeColor;
  final String waterColor;
  final List<String> availableItemIds;

  const Location({
    required this.id,
    required this.name,
    required this.description,
    this.difficulty = 1.0,
    this.unlocked = true,
    this.themeColor = '0xFF264653',
    this.waterColor = '0xFF2A9D8F',
    required this.availableItemIds,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 1.0,
      unlocked: json['unlocked'] as bool? ?? true,
      themeColor: json['themeColor'] as String? ?? '0xFF264653',
      waterColor: json['waterColor'] as String? ?? '0xFF2A9D8F',
      availableItemIds: (json['availableItemIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'unlocked': unlocked,
      'themeColor': themeColor,
      'waterColor': waterColor,
      'availableItemIds': availableItemIds,
    };
  }
}
