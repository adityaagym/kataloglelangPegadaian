class ItemPhoto {
  final int? id;
  final int itemId;
  final String localPath;
  final bool isPrimary;
  final int sortOrder;

  ItemPhoto({
    this.id,
    required this.itemId,
    required this.localPath,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'local_path': localPath,
      'is_primary': isPrimary ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory ItemPhoto.fromMap(Map<String, dynamic> map) {
    return ItemPhoto(
      id: map['id'],
      itemId: map['item_id'],
      localPath: map['local_path'],
      isPrimary: map['is_primary'] == 1,
      sortOrder: map['sort_order'],
    );
  }
}
