import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/auction_item.dart';
import '../models/category.dart';
import '../models/imported_auction_item.dart';

class ExcelImportService {
  static const String _sheetName = 'Template Produk';

  static Future<List<ImportedAuctionItem>> parseFile(
    Uint8List fileBytes,
    List<Category> categories,
  ) async {
    final excel = Excel.decodeBytes(fileBytes);
    final sheet = excel.tables[_sheetName];
    if (sheet == null) {
      throw FormatException('Sheet "$_sheetName" tidak ditemukan dalam file Excel');
    }

    final categoryMap = {for (final c in categories) c.name.toLowerCase().trim(): c.id};
    final results = <ImportedAuctionItem>[];

    // Skip header row at index 0
    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (_isRowEmpty(row)) continue;

      final errors = <String>[];

      final name = _readCell(row, 2);
      final categoryName = _readCell(row, 3);
      final weightText = _readCell(row, 4);
      final condition = _readCell(row, 6);
      final basePriceText = _readCell(row, 7);

      if (name.isEmpty) {
        errors.add('Nama produk wajib diisi');
      }

      final categoryId = categoryMap[categoryName.toLowerCase().trim()];
      if (categoryName.isEmpty) {
        errors.add('Kategori wajib diisi');
      } else if (categoryId == null) {
        errors.add('Kategori "$categoryName" tidak ditemukan');
      }

      final weightGram = double.tryParse(weightText.replaceAll(',', '.')) ?? -1;
      if (weightText.isEmpty || weightGram < 0) {
        errors.add('Berat tidak valid');
      }

      final basePrice = double.tryParse(basePriceText.replaceAll('.', '').replaceAll(',', '')) ?? -1;
      if (basePriceText.isEmpty || basePrice < 0) {
        errors.add('Harga dasar tidak valid');
      }

      final validConditions = ['Baik', 'Cukup Baik', 'Perlu Perbaikan'];
      if (condition.isEmpty) {
        errors.add('Kondisi wajib diisi');
      } else if (!validConditions.contains(condition)) {
        errors.add('Kondisi harus Baik, Cukup Baik, atau Perlu Perbaikan');
      }

      final item = AuctionItem(
        creditNumber: _readCell(row, 1).isEmpty ? null : _readCell(row, 1),
        name: name,
        categoryId: categoryId ?? 0,
        weightGram: weightGram < 0 ? 0 : weightGram,
        karat: _readCell(row, 5).isEmpty ? null : _readCell(row, 5),
        condition: condition.isEmpty ? 'Baik' : condition,
        basePrice: basePrice < 0 ? 0 : basePrice,
        description: _readCell(row, 8).isEmpty ? null : _readCell(row, 8),
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      results.add(ImportedAuctionItem(
        rowIndex: rowIndex + 1,
        item: item,
        validationErrors: errors,
      ));
    }

    return results;
  }

  static bool _isRowEmpty(List<Data?> row) {
    return row.every((cell) => cell?.value == null || _stringValue(cell).trim().isEmpty);
  }

  static String _readCell(List<Data?> row, int columnIndex) {
    if (columnIndex >= row.length) return '';
    return _stringValue(row[columnIndex]).trim();
  }

  static String _stringValue(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text ?? '';
    if (value is DoubleCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    return value.toString();
  }
}
