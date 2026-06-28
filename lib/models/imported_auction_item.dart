import 'auction_item.dart';

class ImportedAuctionItem {
  final int rowIndex;
  final AuctionItem item;
  final List<String> validationErrors;
  final bool isSelected;

  ImportedAuctionItem({
    required this.rowIndex,
    required this.item,
    this.validationErrors = const [],
    this.isSelected = true,
  });

  bool get isValid => validationErrors.isEmpty;

  ImportedAuctionItem copyWith({
    int? rowIndex,
    AuctionItem? item,
    List<String>? validationErrors,
    bool? isSelected,
  }) {
    return ImportedAuctionItem(
      rowIndex: rowIndex ?? this.rowIndex,
      item: item ?? this.item,
      validationErrors: validationErrors ?? this.validationErrors,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
