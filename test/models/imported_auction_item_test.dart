import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/models/imported_auction_item.dart';
import 'package:katalog_lelang/models/auction_item.dart';

void main() {
  test('ImportedAuctionItem initializes with empty errors and selected true', () {
    final item = AuctionItem(
      name: 'Cincin Emas',
      categoryId: 1,
      weightGram: 5.0,
      condition: 'Baik',
      basePrice: 1000000,
    );
    final imported = ImportedAuctionItem(
      rowIndex: 2,
      item: item,
    );

    expect(imported.rowIndex, 2);
    expect(imported.validationErrors, isEmpty);
    expect(imported.isSelected, true);
    expect(imported.item.name, 'Cincin Emas');
  });

  test('copyWith updates fields without mutating original', () {
    final imported = ImportedAuctionItem(
      rowIndex: 2,
      item: AuctionItem(
        name: 'Cincin Emas',
        categoryId: 1,
        weightGram: 5.0,
        condition: 'Baik',
        basePrice: 1000000,
      ),
    );

    final updated = imported.copyWith(
      isSelected: false,
      validationErrors: ['Kategori tidak ditemukan'],
    );

    expect(updated.isSelected, false);
    expect(updated.validationErrors, ['Kategori tidak ditemukan']);
    expect(imported.isSelected, true);
    expect(imported.validationErrors, isEmpty);
  });
}
