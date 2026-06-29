import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/auction_item.dart';
import '../models/category.dart';
import '../models/imported_auction_item.dart';
import '../services/financing_calculator.dart';
import '../services/excel_template_service.dart';

class ExcelImportService {
  static const String _templateSheetName = 'Template Produk';

  static Future<List<ImportedAuctionItem>> parseFile(
    Uint8List fileBytes,
    List<Category> categories, {
    double goldPrice = 0,
  }) async {
    final excel = Excel.decodeBytes(fileBytes);
    
    // Check if it's Siscadu report format
    for (final table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.maxRows == 0) continue;
      
      if (sheet.sheetName == ExcelTemplateService.sheetName) {
        return _parseTemplateProduk(sheet, categories, goldPrice);
      }
      
      // Read first few rows to detect headers
      for (var i = 0; i < (sheet.maxRows < 15 ? sheet.maxRows : 15); i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;
        
        final rowString = row.map((e) => _stringValue(e).toLowerCase().replaceAll('\n', ' ')).join(' ');
        if (rowString.contains('no. akad') && rowString.contains('marhun') && rowString.contains('taksiran')) {
          return _parseSiscaduReport(sheet, categories, goldPrice, headerRowIndex: i);
        }
      }
    }
    
    // If not Siscadu, fallback to Template Produk
    final templateSheet = excel.tables[_templateSheetName];
    if (templateSheet != null) {
      return _parseTemplateProduk(templateSheet, categories, goldPrice);
    }
    
    throw const FormatException('Format file tidak dikenali. Gunakan "Template Produk" atau "Laporan Siscadu Pegadaian".');
  }

  // --- Parser for Siscadu Report ---
  static List<ImportedAuctionItem> _parseSiscaduReport(
    Sheet sheet,
    List<Category> categories,
    double goldPrice, {
    required int headerRowIndex,
  }) {
    final categoryMap = {for (final c in categories) c.name.toLowerCase().trim(): c.id};
    final results = <ImportedAuctionItem>[];
    
    final headerRow = sheet.rows[headerRowIndex];
    int noCol = -1, akadCol = -1, marhunCol = -1, taksiranCol = -1;
    
    for (var i = 0; i < headerRow.length; i++) {
      final cellStr = _stringValue(headerRow[i]).toLowerCase().replaceAll('\n', ' ').trim();
      if (cellStr.contains('no. akad')) akadCol = i;
      if (cellStr.contains('marhun') && !cellStr.contains('bih')) marhunCol = i;
      if (cellStr.contains('taksiran')) taksiranCol = i;
      if (cellStr == 'no.') noCol = i;
    }

    if (akadCol == -1 || marhunCol == -1 || taksiranCol == -1) {
      throw const FormatException('Kolom wajib Siscadu (No. Akad, Marhun, Taksiran) tidak ditemukan.');
    }

    String? currentNo;
    String currentAkad = '';
    String currentMarhun = '';
    double currentTaksiran = 0;
    int currentRowIndex = 0;
    
    void processGroup() {
      if (currentNo == null || currentNo.isEmpty) return;
      if (currentAkad.isEmpty && currentMarhun.isEmpty) return;
      
      final errors = <String>[];
      
      String name = currentMarhun;
      final upperMarhun = currentMarhun.toUpperCase();
      final ditaksirIndex = upperMarhun.indexOf('DITAKSIR');
      if (ditaksirIndex != -1) {
        name = currentMarhun.substring(0, ditaksirIndex).trim();
      } else {
        final lines = currentMarhun.split('\n');
        if (lines.isNotEmpty) name = lines[0].trim();
      }
      
      final flatMarhun = upperMarhun.replaceAll(RegExp(r'\s+'), ' ');
      
      String categoryName = '';
      int categoryId = 0;
      if (flatMarhun.contains('PERHIASAN EMAS')) {
        categoryName = 'Perhiasan Emas';
        categoryId = categoryMap['perhiasan emas'] ?? 0;
      } else if (flatMarhun.contains('LOGAM MULIA')) {
        categoryName = 'Logam Mulia';
        categoryId = categoryMap['logam mulia'] ?? 0;
      } else if (flatMarhun.contains('ELEKTRONIK')) {
        categoryName = 'Elektronik';
        categoryId = categoryMap['elektronik'] ?? 0;
      } else if (flatMarhun.contains('KENDARAAN')) {
        categoryName = 'Kendaraan';
        categoryId = categoryMap['kendaraan'] ?? 0;
      }
      
      if (categoryName.isEmpty || categoryId == 0) {
        errors.add('Kategori gagal diekstrak dari deskripsi');
      }

      String karat = '';
      final karatMatch = RegExp(r'(\d+)\s*KARAT').firstMatch(upperMarhun);
      if (karatMatch != null) {
        karat = karatMatch.group(1) ?? '';
      }
      
      double weightGram = 0;
      final weightMatch = RegExp(r'BERAT\s*([\d\.,]+)(?:/([\d\.,]+))?').firstMatch(upperMarhun);
      if (weightMatch != null) {
        String wStr = (weightMatch.group(2) ?? weightMatch.group(1) ?? '').replaceAll(',', '.');
        weightGram = double.tryParse(wStr) ?? 0;
      }
      if (weightGram <= 0) {
        errors.add('Berat gagal diekstrak atau tidak valid');
      }
      
      if (currentAkad == '-' || currentAkad.isEmpty) {
        errors.add('Nomor Akad tidak valid');
      }

      double finalTaksiran = currentTaksiran < 0 ? 0 : currentTaksiran;
      if (categoryId > 0) {
        final category = categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(id: 0, name: ''));
        if (category.name.toLowerCase().contains('emas') || category.name.toLowerCase().contains('logam mulia')) {
          final karatVal = FinancingCalculator.parseKarat(karat);
          finalTaksiran = FinancingCalculator.hitungHargaEmas(
            hdlePrice: goldPrice,
            weightGram: weightGram,
            karatVal: karatVal > 0 ? karatVal : 24.0,
          ).toDouble();
        }
      }

      final item = AuctionItem(
        creditNumber: currentAkad.isEmpty || currentAkad == '-' ? null : currentAkad,
        name: name.isEmpty ? 'Barang Lelang' : name,
        categoryId: categoryId,
        weightGram: weightGram < 0 ? 0 : weightGram,
        karat: karat.isEmpty ? null : karat,
        basePrice: finalTaksiran,
        description: currentMarhun,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      );

      results.add(ImportedAuctionItem(
        rowIndex: currentRowIndex,
        item: item,
        validationErrors: errors,
      ));
    }

    for (var i = headerRowIndex + 1; i < sheet.maxRows; i++) {
      final row = sheet.rows[i];
      if (_isRowEmpty(row)) continue;
      
      final noValue = noCol != -1 ? _stringValue(row[noCol]).trim() : '';
      final isNewGroup = noValue.isNotEmpty && (int.tryParse(noValue) != null || RegExp(r'^\d+$').hasMatch(noValue));
      
      if (isNewGroup) {
        processGroup();
        
        currentNo = noValue;
        currentAkad = _stringValue(row[akadCol]).trim();
        currentMarhun = _stringValue(row[marhunCol]).trim();
        
        final rawTaksiran = _stringValue(row[taksiranCol]);
        final taksiranStr = rawTaksiran.replaceAll(RegExp(r'[^\d\.]'), '');
        final lastDotIndex = taksiranStr.lastIndexOf('.');
        double parsedTaksiran = 0;
        if (lastDotIndex != -1) {
            final cleanTaksiran = '${taksiranStr.substring(0, lastDotIndex).replaceAll('.', '')}.${taksiranStr.substring(lastDotIndex + 1)}';
            parsedTaksiran = double.tryParse(cleanTaksiran) ?? 0;
        } else {
            parsedTaksiran = double.tryParse(taksiranStr) ?? 0;
        }

        if (parsedTaksiran == 0 && rawTaksiran.isNotEmpty) {
           final justDigits = rawTaksiran.replaceAll(RegExp(r'[^\d]'), '');
           parsedTaksiran = double.tryParse(justDigits) ?? 0;
        }
        
        currentTaksiran = parsedTaksiran;
        currentRowIndex = i + 1;
      } else {
        if (currentNo != null && currentNo.isNotEmpty) {
          final akadExtra = _stringValue(row[akadCol]).trim();
          if (akadExtra.isNotEmpty && akadExtra != '-') currentAkad += '\n$akadExtra';
          
          final marhunExtra = _stringValue(row[marhunCol]).trim();
          if (marhunExtra.isNotEmpty) {
            currentMarhun += '${currentMarhun.isNotEmpty ? '\n' : ''}$marhunExtra';
          }
        }
      }
    }
    
    processGroup();
    
    return results;
  }

  // --- Parser for Template Produk ---
  static List<ImportedAuctionItem> _parseTemplateProduk(
    Sheet sheet,
    List<Category> categories,
    double goldPrice,
  ) {
    final categoryMap = {for (final c in categories) c.name.toLowerCase().trim(): c.id};
    final results = <ImportedAuctionItem>[];

    for (var rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final row = sheet.rows[rowIndex];
      if (_isRowEmpty(row)) continue;

      final errors = <String>[];

      final name = _readCell(row, 2);
      final categoryName = _readCell(row, 3);
      final weightText = _readCell(row, 4);
      final basePriceText = _readCell(row, 6);

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

      final basePrice = double.tryParse(basePriceText.replaceAll('.', '').replaceAll(',', '')) ?? 0;

      double finalBasePrice = basePrice < 0 ? 0 : basePrice;
      if (categoryId != null) {
        final category = categories.firstWhere((c) => c.id == categoryId, orElse: () => Category(id: 0, name: ''));
        if (category.name.toLowerCase().contains('emas') || category.name.toLowerCase().contains('logam mulia')) {
          final karatStr = _readCell(row, 5);
          final karatVal = FinancingCalculator.parseKarat(karatStr);
          finalBasePrice = FinancingCalculator.hitungHargaEmas(
            hdlePrice: goldPrice,
            weightGram: weightGram,
            karatVal: karatVal > 0 ? karatVal : 24.0,
          ).toDouble();
        }
      }

      final officialCategory = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => Category(id: 0, name: categoryName),
      );

      final item = AuctionItem(
        creditNumber: _readCell(row, 1).isEmpty ? null : _readCell(row, 1),
        name: name,
        categoryId: categoryId ?? 0,
        weightGram: weightGram < 0 ? 0 : weightGram,
        karat: _readCell(row, 5).isEmpty ? null : _readCell(row, 5),
        basePrice: finalBasePrice,
        description: _readCell(row, 7).isEmpty ? null : _readCell(row, 7),
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        categoryName: officialCategory.name,
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
    return value.toString();
  }
}
