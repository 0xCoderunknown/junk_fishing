class Item {
  final String id;
  final String name;
  final String flavorText;
  final int rarity; // 1 to 5 stars
  final int estimatedValue;
  final String collectionTag;
  final String locationId;
  final String icon;
  final double weightKg;

  const Item({
    required this.id,
    required this.name,
    required this.flavorText,
    required this.rarity,
    required this.estimatedValue,
    required this.collectionTag,
    required this.locationId,
    this.icon = 'category',
    this.weightKg = 0.5,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      flavorText:
          json['flavorText'] as String? ?? 'A mysterious piece of scrap.',
      rarity: (json['rarity'] as num?)?.toInt() ?? 1,
      estimatedValue: (json['estimatedValue'] as num?)?.toInt() ?? 10,
      collectionTag: json['collectionTag'] as String? ?? 'General Flotsam',
      locationId: json['locationId'] as String? ?? '',
      icon: json['icon'] as String? ?? 'category',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'flavorText': flavorText,
      'rarity': rarity,
      'estimatedValue': estimatedValue,
      'collectionTag': collectionTag,
      'locationId': locationId,
      'icon': icon,
      'weightKg': weightKg,
    };
  }

  String get rarityStars => '★' * rarity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          rarity == other.rarity &&
          estimatedValue == other.estimatedValue;

  @override
  int get hashCode => Object.hash(id, name, rarity, estimatedValue);
}
