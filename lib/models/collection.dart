class Collection {
  final String id;
  final String name;
  final String description;
  final int rewardMoney;
  final List<String> itemIds;

  const Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardMoney,
    required this.itemIds,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      rewardMoney: (json['rewardMoney'] as num?)?.toInt() ?? 500,
      itemIds:
          (json['itemIds'] as List<dynamic>?)
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
      'rewardMoney': rewardMoney,
      'itemIds': itemIds,
    };
  }

  bool isComplete(Iterable<String> discoveredItemIds) {
    if (itemIds.isEmpty) return false;
    final set = discoveredItemIds.toSet();
    return itemIds.every(set.contains);
  }

  double progress(Iterable<String> discoveredItemIds) {
    if (itemIds.isEmpty) return 0.0;
    final set = discoveredItemIds.toSet();
    final count = itemIds.where(set.contains).length;
    return count / itemIds.length;
  }

  /// Single-pass calculation of completion status to eliminate duplicate set operations.
  ({int found, int total, double progress, bool isComplete}) getStatus(
    Set<String> discoveredItemIds,
  ) {
    if (itemIds.isEmpty) {
      return (found: 0, total: 0, progress: 0.0, isComplete: false);
    }
    int count = 0;
    for (final id in itemIds) {
      if (discoveredItemIds.contains(id)) {
        count++;
      }
    }
    final ratio = count / itemIds.length;
    return (
      found: count,
      total: itemIds.length,
      progress: ratio,
      isComplete: count == itemIds.length,
    );
  }
}
