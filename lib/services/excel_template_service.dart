import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/category.dart';

class ExcelTemplateService {
  static const String sheetName = 'Template Produk';

  static final List<String> _headers = [
    'No',
    'No Kredit (opsional)',
    'Nama Produk',
    'Kategori',
    'Berat (gram)',
    'Karat (opsional)',
    'Harga Dasar (opsional)',
    'Deskripsi (opsional)',
  ];

  static final List<String> _sampleRow = [
    '1',
    'KRD-001',
    'Cincin Emas 22K',
    'Perhiasan Emas',
    '5.5',
    '22',
    '',
    'Cincin emas polos (harga dihitung otomatis dari HDLE)',
  ];

  static final List<String> _sampleRow2 = [
    '2',
    '',
    'Laptop ASUS',
    'Elektronik',
    '0',
    '',
    '4500000',
    'Laptop second',
  ];

  static Uint8List generateTemplateBytes(List<Category> categories) {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    // Header row
    for (var i = 0; i < _headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
        ..value = TextCellValue(_headers[i])
        ..cellStyle = CellStyle(
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
    }

    // Sample rows
    _writeRow(sheet, 1, _sampleRow);
    _writeRow(sheet, 2, _sampleRow2);

    // Category legend sheet
    final legendSheet = excel['Daftar Kategori'];
    legendSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Nama Kategori')
      ..cellStyle = CellStyle(bold: true);

    for (var i = 0; i < categories.length; i++) {
      legendSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1),
      ).value = TextCellValue(categories[i].name);
    }

    // Set column widths for Template Produk sheet
    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 28);
    sheet.setColumnWidth(3, 22);
    sheet.setColumnWidth(4, 16);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 22);
    sheet.setColumnWidth(7, 32);

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel template');
    }
    return Uint8List.fromList(bytes);
  }

  static void _writeRow(Sheet sheet, int rowIndex, List<String> values) {
    for (var i = 0; i < values.length; i++) {
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
      ).value = TextCellValue(values[i]);
    }
  }
}
