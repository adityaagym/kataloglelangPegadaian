class AuctionItem {
  final int? id;
  final String? creditNumber;
  final String name;
  final int categoryId;
  final double weightGram;
  final String? karat;
  final String condition;
  final double basePrice;
  final String? description;
  final bool isActive;
  final String? createdAt;

  // Custom field to hold fetched category name if needed
  String? categoryName;

  AuctionItem({
    this.id,
    this.creditNumber,
    required this.name,
    required this.categoryId,
    required this.weightGram,
    this.karat,
    required this.condition,
    required this.basePrice,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.categoryName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'credit_number': creditNumber,
      'name': name,
      'category_id': categoryId,
      'weight_gram': weightGram,
      'karat': karat,
      'condition': condition,
      'base_price': basePrice,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory AuctionItem.fromMap(Map<String, dynamic> map) {
    return AuctionItem(
      id: map['id'],
      creditNumber: map['credit_number'] as String?,
      name: map['name'],
      categoryId: map['category_id'],
      weightGram: (map['weight_gram'] as num).toDouble(),
      karat: map['karat'],
      condition: map['condition'],
      basePrice: (map['base_price'] as num).toDouble(),
      description: map['description'],
      isActive: map['is_active'] == 1,
      createdAt: map['created_at'],
    );
  }
}
