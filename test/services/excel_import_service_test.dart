import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/models/category.dart';
import 'package:katalog_lelang/services/excel_import_service.dart';
import 'package:katalog_lelang/services/excel_template_service.dart';

void main() {
  final categories = [
    Category(id: 1, name: 'Perhiasan Emas'),
    Category(id: 2, name: 'Elektronik'),
  ];

  test('parseFile returns valid item for well-formed row', () async {
    final bytes = ExcelTemplateService.generateTemplateBytes(categories);
    // Gold price = 1200000, weight = 5.5, karat = 22 -> 1200000 * 5.5 * (22/24) = 6050000
    final result = await ExcelImportService.parseFile(bytes, categories, goldPrice: 1200000);

    expect(result, isNotEmpty);
    final first = result.first;
    expect(first.isValid, true);
    expect(first.item.name, 'Cincin Emas 22K');
    expect(first.item.categoryId, 1);
    expect(first.item.weightGram, 5.5);
    expect(first.item.basePrice, 6050000);
  });

  test('parseFile flags invalid category and missing name', () async {
    final bytes = ExcelTemplateService.generateTemplateBytes(categories);
    final result = await ExcelImportService.parseFile(bytes, categories);

    // Second sample row uses Elektronik, should be valid.
    final second = result[1];
    expect(second.isValid, true);
    expect(second.item.categoryId, 2);
  });

  test('parseFile skips completely empty rows', () async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Produk'];
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('No Kredit (opsional)'),
      TextCellValue('Nama Produk'),
      TextCellValue('Kategori'),
      TextCellValue('Berat (gram)'),
      TextCellValue('Karat (opsional)'),
      TextCellValue('Harga Dasar (Rp)'),
      TextCellValue('Deskripsi (opsional)'),
    ]);
    sheet.appendRow([
      TextCellValue('1'),
      TextCellValue(''),
      TextCellValue('Valid Item'),
      TextCellValue('Perhiasan Emas'),
      TextCellValue('3'),
      TextCellValue(''),
      TextCellValue('1000000'),
      TextCellValue(''),
    ]);
    // Empty row
    sheet.appendRow(List.generate(8, (_) => TextCellValue('')));

    final bytes = Uint8List.fromList(excel.encode()!);
    final result = await ExcelImportService.parseFile(bytes, categories);

    expect(result.length, 1);
    expect(result.first.isValid, true);
  });
}
