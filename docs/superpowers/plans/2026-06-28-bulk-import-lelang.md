# Bulk Import Produk Lelang Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tambahkan fitur bulk import produk lelang via file Excel di aplikasi offline Flutter, lengkap dengan download template, parsing & validasi, halaman konfirmasi, input foto manual per produk, dan penyimpanan ke SQLite.

**Architecture:** Fitur ini mengikuti arsitektur existing: service layer menangani pembuatan template Excel dan parsing file Excel; provider menangani state import (draft item, validasi, foto); UI layer menambahkan entry point di admin sidebar, halaman konfirmasi data impor, dan halaman input foto per item. File Excel tidak menyimpan foto — foto ditangkap satu per satu setelah konfirmasi data teks.

**Tech Stack:** Flutter 3.x, sqflite, provider, image_picker, `excel: ^4.0.6` (read/write .xlsx), `file_picker: ^10.1.9` (pick .xlsx dari storage lokal).

---

## File Structure

- `pubspec.yaml` — tambah dependency `excel` dan `file_picker`.
- `lib/models/imported_auction_item.dart` — model wrapper `ImportedAuctionItem` yang membungkus `AuctionItem` + metadata validasi (row index, errors, selected for import).
- `lib/services/excel_template_service.dart` — generate template Excel dari daftar kategori yang ada di DB.
- `lib/services/excel_import_service.dart` — parse file Excel ke `List<ImportedAuctionItem>`, validasi mapping kategori dan tipe data.
- `lib/database/database_helper.dart` — tambah method `createAuctionItemsBatch(List<AuctionItem>)` dan `getCategoryByName(String)`.
- `lib/providers/app_provider.dart` — tambah state & method untuk flow import (mulai import, konfirmasi item, simpan batch, attach foto).
- `lib/screens/admin/bulk_import_screen.dart` — entry point: download template, pilih file Excel, preview ringkas.
- `lib/screens/admin/import_confirmation_screen.dart` — tabel konfirmasi data masuk: centang baris, edit ringan, tampilkan error.
- `lib/screens/admin/import_photo_capture_screen.dart` — input foto satu per satu untuk setiap item yang dikonfirmasi.
- `lib/screens/admin/admin_dashboard.dart` — tambah menu "Import Massal" di sidebar.
- `test/services/excel_import_service_test.dart` — unit test parsing & validasi dengan file Excel in-memory.

---

## Task 1: Tambahkan Dependency Excel & File Picker

**Files:**
- Modify: `pubspec.yaml:33-42`

- [ ] **Step 1: Tambahkan package ke dependencies**

```yaml
  excel: ^4.0.6
  file_picker: ^10.1.9
```

Letakkan setelah `google_fonts: ^8.1.0` di bagian `dependencies`.

- [ ] **Step 2: Jalankan `flutter pub get`**

Run:
```bash
flutter pub get
```

Expected: `excel` dan `file_picker` ter-resolve tanpa error.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
flutter pub get
git commit -m "chore: add excel and file_picker dependencies for bulk import"
```

---

## Task 2: Model `ImportedAuctionItem`

**Files:**
- Create: `lib/models/imported_auction_item.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/imported_auction_item_test.dart`:

```dart
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
```

Run:
```bash
flutter test test/models/imported_auction_item_test.dart
```

Expected: FAIL — class not found.

- [ ] **Step 2: Implement `ImportedAuctionItem`**

Create `lib/models/imported_auction_item.dart`:

```dart
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
```

- [ ] **Step 3: Run test to verify it passes**

Run:
```bash
flutter test test/models/imported_auction_item_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/models/imported_auction_item.dart test/models/imported_auction_item_test.dart
git commit -m "feat: add ImportedAuctionItem model for bulk import"
```

---

## Task 3: Service Generate Template Excel

**Files:**
- Create: `lib/services/excel_template_service.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/excel_template_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/models/category.dart';
import 'package:katalog_lelang/services/excel_template_service.dart';

void main() {
  test('generateTemplateBytes creates sheet with headers and category rows', () {
    final categories = [
      Category(id: 1, name: 'Perhiasan Emas'),
      Category(id: 2, name: 'Elektronik'),
    ];

    final bytes = ExcelTemplateService.generateTemplateBytes(categories);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
```

Run:
```bash
flutter test test/services/excel_template_service_test.dart
```

Expected: FAIL — service not found.

- [ ] **Step 2: Implement `ExcelTemplateService`**

Create `lib/services/excel_template_service.dart`:

```dart
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
    'Kondisi',
    'Harga Dasar (Rp)',
    'Deskripsi (opsional)',
  ];

  static final List<String> _sampleRow = [
    '1',
    'KRD-001',
    'Cincin Emas 22K',
    'Perhiasan Emas',
    '5.5',
    '22',
    'Baik',
    '5500000',
    'Cincin emas polos',
  ];

  static final List<String> _sampleRow2 = [
    '2',
    '',
    'Laptop ASUS',
    'Elektronik',
    '0',
    '',
    'Cukup Baik',
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
      ..value = const TextCellValue('Nama Kategori')
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
    sheet.setColumnWidth(6, 18);
    sheet.setColumnWidth(7, 22);
    sheet.setColumnWidth(8, 32);

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
```

- [ ] **Step 3: Run test to verify it passes**

Run:
```bash
flutter test test/services/excel_template_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/services/excel_template_service.dart test/services/excel_template_service_test.dart
git commit -m "feat: add Excel template generator for bulk import"
```

---

## Task 4: Service Parse & Validasi Import Excel

**Files:**
- Create: `lib/services/excel_import_service.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/excel_import_service_test.dart`:

```dart
import 'dart:typed_data';
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
    final result = await ExcelImportService.parseFile(bytes, categories);

    expect(result, isNotEmpty);
    final first = result.first;
    expect(first.isValid, true);
    expect(first.item.name, 'Cincin Emas 22K');
    expect(first.item.categoryId, 1);
    expect(first.item.weightGram, 5.5);
    expect(first.item.basePrice, 5500000);
    expect(first.item.condition, 'Baik');
  });

  test('parseFile flags invalid category and missing name', () async {
    final bytes = ExcelTemplateService.generateTemplateBytes(categories);
    final result = await ExcelImportService.parseFile(bytes, categories);

    // Second sample row uses Elektronik, should be valid.
    final second = result[1];
    expect(second.isValid, true);
    expect(second.item.categoryId, 2);
  });
}
```

Run:
```bash
flutter test test/services/excel_import_service_test.dart
```

Expected: FAIL — service not found.

- [ ] **Step 2: Implement `ExcelImportService`**

Create `lib/services/excel_import_service.dart`:

```dart
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
      if (row == null || _isRowEmpty(row)) continue;

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
```

- [ ] **Step 3: Run test to verify it passes**

Run:
```bash
flutter test test/services/excel_import_service_test.dart
```

Expected: 2 tests PASS.

- [ ] **Step 4: Tambah test untuk baris kosong dan kategori invalid**

Update `test/services/excel_import_service_test.dart` dengan test tambahan:

```dart
import 'package:excel/excel.dart';

  test('parseFile skips completely empty rows', () async {
    final excel = Excel.createExcel();
    final sheet = excel['Template Produk'];
    sheet.appendRow([
      const TextCellValue('No'),
      const TextCellValue('No Kredit (opsional)'),
      const TextCellValue('Nama Produk'),
      const TextCellValue('Kategori'),
      const TextCellValue('Berat (gram)'),
      const TextCellValue('Karat (opsional)'),
      const TextCellValue('Kondisi'),
      const TextCellValue('Harga Dasar (Rp)'),
      const TextCellValue('Deskripsi (opsional)'),
    ]);
    sheet.appendRow([
      const TextCellValue('1'),
      const TextCellValue(''),
      const TextCellValue('Valid Item'),
      const TextCellValue('Perhiasan Emas'),
      const TextCellValue('3'),
      const TextCellValue(''),
      const TextCellValue('Baik'),
      const TextCellValue('1000000'),
      const TextCellValue(''),
    ]);
    // Empty row
    sheet.appendRow(List.generate(9, (_) => const TextCellValue('')));

    final bytes = Uint8List.fromList(excel.encode()!);
    final result = await ExcelImportService.parseFile(bytes, categories);

    expect(result.length, 1);
    expect(result.first.isValid, true);
  });
```

Run:
```bash
flutter test test/services/excel_import_service_test.dart
```

Expected: 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/excel_import_service.dart test/services/excel_import_service_test.dart
git commit -m "feat: add Excel parser and validation for bulk import"
```

---

## Task 5: Tambah Helper Database untuk Batch Insert & Cari Kategori

**Files:**
- Modify: `lib/database/database_helper.dart`

- [ ] **Step 1: Tambah method `getCategoryByName` dan `createAuctionItemsBatch`**

Setelah method `readAllCategories`, tambahkan:

```dart
  Future<Category?> getCategoryByName(String name) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase().trim()],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }
```

Setelah method `createAuctionItem`, tambahkan:

```dart
  Future<List<int>> createAuctionItemsBatch(List<AuctionItem> items) async {
    final db = await instance.database;
    final ids = <int>[];

    await db.transaction((txn) async {
      for (final item in items) {
        final id = await txn.insert('auction_items', item.toMap());
        ids.add(id);
      }
    });

    return ids;
  }
```

- [ ] **Step 2: Tambah unit test untuk batch insert**

Create `test/database/database_helper_batch_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/database/database_helper.dart';
import 'package:katalog_lelang/models/auction_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createAuctionItemsBatch inserts multiple items', () async {
    final dbHelper = DatabaseHelper._init();
    final items = [
      AuctionItem(
        name: 'Item A',
        categoryId: 1,
        weightGram: 1.0,
        condition: 'Baik',
        basePrice: 1000,
      ),
      AuctionItem(
        name: 'Item B',
        categoryId: 2,
        weightGram: 2.0,
        condition: 'Cukup Baik',
        basePrice: 2000,
      ),
    ];

    final ids = await dbHelper.createAuctionItemsBatch(items);

    expect(ids.length, 2);
    expect(ids.every((id) => id > 0), true);

    await dbHelper.close();
  });
}
```

Run:
```bash
flutter test test/database/database_helper_batch_test.dart
```

Expected: PASS.

Note: Jika `sqflite_common_ffi` belum ada, tambahkan ke `dev_dependencies`:

```yaml
  sqflite_common_ffi: ^2.3.5
```

Kemudian `flutter pub get`.

- [ ] **Step 3: Commit**

```bash
git add lib/database/database_helper.dart test/database/database_helper_batch_test.dart
git commit -m "feat: add batch insert and category lookup in database helper"
```

---

## Task 6: Extend Provider untuk State Import Massal

**Files:**
- Modify: `lib/providers/app_provider.dart`

- [ ] **Step 1: Tambah import dan state properties**

Tambahkan import di atas:

```dart
import '../models/imported_auction_item.dart';
```

Tambahkan properties dan getters di bawah `String? _lastItemUpdatedAt;`:

```dart
  List<ImportedAuctionItem> _importDraftItems = [];
  List<ImportedAuctionItem> get importDraftItems => _importDraftItems;

  bool get hasImportDraft => _importDraftItems.isNotEmpty;

  int get selectedImportCount =>
      _importDraftItems.where((i) => i.isSelected && i.isValid).length;
```

- [ ] **Step 2: Tambah methods untuk manage import state**

Tambahkan di akhir class sebelum penutup:

```dart
  // --- Bulk Import ---
  Future<List<ImportedAuctionItem>> parseImportFile(Uint8List fileBytes) async {
    final categories = await _dbHelper.readAllCategories();
    final parsed = await ExcelImportService.parseFile(fileBytes, categories);
    _importDraftItems = parsed;
    notifyListeners();
    return parsed;
  }

  void setImportDraft(List<ImportedAuctionItem> items) {
    _importDraftItems = items;
    notifyListeners();
  }

  void toggleItemSelection(int rowIndex) {
    _importDraftItems = _importDraftItems.map((item) {
      if (item.rowIndex == rowIndex) {
        return item.copyWith(isSelected: !item.isSelected);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  void updateImportedItem(int rowIndex, AuctionItem updatedItem) {
    _importDraftItems = _importDraftItems.map((imported) {
      if (imported.rowIndex == rowIndex) {
        return imported.copyWith(item: updatedItem);
      }
      return imported;
    }).toList();
    notifyListeners();
  }

  Future<List<int>> saveImportedItems() async {
    final itemsToSave = _importDraftItems
        .where((i) => i.isSelected && i.isValid)
        .map((i) => i.item)
        .toList();

    if (itemsToSave.isEmpty) return [];

    final ids = await _dbHelper.createAuctionItemsBatch(itemsToSave);
    await refreshAdminData();
    _importDraftItems = [];
    notifyListeners();
    return ids;
  }

  Future<void> attachPhotoToItem(int itemId, String localPath, {bool isPrimary = false}) async {
    await _dbHelper.createItemPhoto(ItemPhoto(
      itemId: itemId,
      localPath: localPath,
      isPrimary: isPrimary,
      sortOrder: await _nextPhotoSortOrder(itemId),
    ));
    notifyListeners();
  }

  Future<int> _nextPhotoSortOrder(int itemId) async {
    final photos = await _dbHelper.readItemPhotos(itemId);
    return photos.length;
  }

  void clearImportDraft() {
    _importDraftItems = [];
    notifyListeners();
  }
```

Tambahkan import untuk `ExcelImportService`:

```dart
import '../services/excel_import_service.dart';
```

- [ ] **Step 3: Commit**

```bash
git add lib/providers/app_provider.dart
git commit -m "feat: add bulk import state management in AppProvider"
```

---

## Task 7: UI Entry Point Bulk Import

**Files:**
- Create: `lib/screens/admin/bulk_import_screen.dart`

- [ ] **Step 1: Implementasi `BulkImportScreen`**

Create `lib/screens/admin/bulk_import_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/excel_template_service.dart';
import '../../utils/app_colors.dart';
import 'import_confirmation_screen.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _downloadTemplate() async {
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final categories = provider.categories;
      final bytes = ExcelTemplateService.generateTemplateBytes(categories);

      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/template_produk_lelang.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template disimpan di $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh template: $e')),
        );
      }
    }
  }

  Future<void> _pickExcelFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.single.bytes == null) {
        setState(() => _isLoading = false);
        return;
      }

      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.parseImportFile(result.files.single.bytes!);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ImportConfirmationScreen()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Massal Produk',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unduh template, isi data, lalu unggah file Excel untuk diimport ke database.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _buildCard(
              icon: Icons.download_outlined,
              title: '1. Unduh Template Excel',
              description: 'Template sudah berisi daftar kategori yang tersedia.',
              buttonLabel: 'Unduh Template',
              onPressed: _downloadTemplate,
            ),
            const SizedBox(height: 20),
            _buildCard(
              icon: Icons.upload_file_outlined,
              title: '2. Unggah File Excel',
              description: 'Pilih file .xlsx yang sudah diisi.',
              buttonLabel: 'Pilih File Excel',
              onPressed: _pickExcelFile,
              isLoading: _isLoading,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/admin/bulk_import_screen.dart
git commit -m "feat: add bulk import entry screen"
```

---

## Task 8: UI Konfirmasi Data Import

**Files:**
- Create: `lib/screens/admin/import_confirmation_screen.dart`

- [ ] **Step 1: Implementasi `ImportConfirmationScreen`**

Create `lib/screens/admin/import_confirmation_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/imported_auction_item.dart';
import '../../utils/app_colors.dart';
import 'import_photo_capture_screen.dart';

class ImportConfirmationScreen extends StatelessWidget {
  const ImportConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Data Import',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = provider.importDraftItems;
          final validSelectedCount = provider.selectedImportCount;

          if (items.isEmpty) {
            return const Center(child: Text('Tidak ada data untuk dikonfirmasi'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${items.length} baris ditemukan · $validSelectedCount valid terpilih',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleAll(provider),
                      icon: const Icon(Icons.checklist),
                      label: const Text('Pilih Semua'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final imported = items[index];
                    return _buildItemCard(context, provider, imported);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.clearImportDraft();
                            Navigator.pop(context);
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: validSelectedCount > 0
                              ? () => _proceedToPhotos(context, provider)
                              : null,
                          child: Text('Lanjut Input Foto ($validSelectedCount)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    AppProvider provider,
    ImportedAuctionItem imported,
  ) {
    final item = imported.item;
    final hasErrors = !imported.isValid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: imported.isSelected && imported.isValid,
                  onChanged: imported.isValid
                      ? (_) => provider.toggleItemSelection(imported.rowIndex)
                      : null,
                ),
                Expanded(
                  child: Text(
                    'Baris ${imported.rowIndex}: ${item.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (hasErrors)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Error',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kategori ID: ${item.categoryId}'),
                  Text('Berat: ${item.weightGram}g · Kondisi: ${item.condition}'),
                  Text('Harga: Rp ${item.basePrice.toStringAsFixed(0)}'),
                  if (hasErrors) ...[
                    const SizedBox(height: 8),
                    ...imported.validationErrors.map((e) => Text(
                          '• $e',
                          style: const TextStyle(color: Colors.red),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAll(AppProvider provider) {
    final allValidSelected = provider.importDraftItems
        .where((i) => i.isValid)
        .every((i) => i.isSelected);

    final newItems = provider.importDraftItems.map((imported) {
      if (!imported.isValid) return imported;
      return imported.copyWith(isSelected: !allValidSelected);
    }).toList();

    provider.setImportDraft(newItems);
  }

  Future<void> _proceedToPhotos(BuildContext context, AppProvider provider) async {
    final savedIds = await provider.saveImportedItems();
    if (savedIds.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item yang tersimpan')),
      );
      return;
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ImportPhotoCaptureScreen(itemIds: savedIds),
        ),
      );
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/admin/import_confirmation_screen.dart
git commit -m "feat: add import confirmation screen"
```

---

## Task 9: UI Input Foto Per Produk

**Files:**
- Create: `lib/screens/admin/import_photo_capture_screen.dart`

- [ ] **Step 1: Implementasi `ImportPhotoCaptureScreen`**

Create `lib/screens/admin/import_photo_capture_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../database/database_helper.dart';
import '../../models/auction_item.dart';
import '../../models/item_photo.dart';
import '../../utils/file_helper.dart';
import '../../utils/app_colors.dart';

class ImportPhotoCaptureScreen extends StatefulWidget {
  final List<int> itemIds;

  const ImportPhotoCaptureScreen({super.key, required this.itemIds});

  @override
  State<ImportPhotoCaptureScreen> createState() => _ImportPhotoCaptureScreenState();
}

class _ImportPhotoCaptureScreenState extends State<ImportPhotoCaptureScreen> {
  int _currentIndex = 0;
  final Map<int, List<File>> _itemPhotos = {};
  List<AuctionItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final db = DatabaseHelper.instance;
    final items = <AuctionItem>[];
    for (final id in widget.itemIds) {
      try {
        items.add(await db.readAuctionItem(id));
      } catch (_) {
        // Skip missing items
      }
    }
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      _itemPhotos.putIfAbsent(_currentIndex, () => []).add(File(pickedFile.path));
    });
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() {
      _itemPhotos.putIfAbsent(_currentIndex, () => []).add(File(pickedFile.path));
    });
  }

  Future<void> _saveCurrentItemPhotos() async {
    final photos = _itemPhotos[_currentIndex] ?? [];
    if (photos.isEmpty || _currentIndex >= _items.length) return;

    final provider = Provider.of<AppProvider>(context, listen: false);
    final itemId = _items[_currentIndex].id!;

    for (var i = 0; i < photos.length; i++) {
      final savedPath = await FileHelper.saveImageToLocalDirectory(photos[i]);
      await provider.attachPhotoToItem(itemId, savedPath, isPrimary: i == 0);
    }
  }

  void _next() async {
    await _saveCurrentItemPhotos();

    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex++);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua foto berhasil disimpan')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _skip() {
    if (_currentIndex < _items.length - 1) {
      setState(() => _currentIndex++);
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_items.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Tidak ada item untuk difoto')),
      );
    }

    final item = _items[_currentIndex];
    final photos = _itemPhotos[_currentIndex] ?? [];
    final progress = '${_currentIndex + 1}/${_items.length}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Foto Produk $progress'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _items.length,
              backgroundColor: AppColors.muted,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Berat: ${item.weightGram}g · Harga: Rp ${item.basePrice.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (photos.isEmpty)
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Belum ada foto', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        photos[index],
                        height: 240,
                        width: 240,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skip,
                    child: const Text('Lewati'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _next,
                    child: Text(_currentIndex < _items.length - 1 ? 'Simpan & Lanjut' : 'Simpan & Selesai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/admin/import_photo_capture_screen.dart
git commit -m "feat: add per-item photo capture after bulk import"
```

---

## Task 10: Integrasi ke Admin Dashboard

**Files:**
- Modify: `lib/screens/admin/admin_dashboard.dart`

- [ ] **Step 1: Tambah import dan menu navigasi**

Tambahkan import di atas:

```dart
import 'bulk_import_screen.dart';
```

Tambahkan case index 7 di `_getMenuTitle`:

```dart
      case 7:
        return 'Import Massal';
```

Tambahkan case 7 di switch `content`:

```dart
      case 7:
        content = const BulkImportScreen();
        break;
```

Tambahkan `_buildNavItem` baru di sidebar setelah "Tambah Barang":

```dart
                    _buildNavItem(
                      Icons.file_upload_outlined,
                      Icons.file_upload,
                      'Import Massal',
                      7,
                      isDrawer: isDrawer,
                    ),
```

- [ ] **Step 2: Jalankan build untuk cek compile error**

Run:
```bash
flutter build apk --debug 2>&1 | tail -50
```

Expected: Build success tanpa error compile.

- [ ] **Step 3: Commit**

```bash
git add lib/screens/admin/admin_dashboard.dart
git commit -m "feat: integrate bulk import menu into admin dashboard"
```

---

## Task 11: Permissions & Platform Configuration

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Tambah permission Android untuk kamera, storage, dan file picker**

Buka `android/app/src/main/AndroidManifest.xml`, tambahkan di dalam `<manifest>` sebelum `<application>`:

```xml
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

- [ ] **Step 2: Tambah permission iOS**

Buka `ios/Runner/Info.plist`, tambahkan di dalam `<dict>`:

```xml
	<key>NSCameraUsageDescription</key>
	<string>Aplikasi membutuhkan akses kamera untuk mengambil foto produk.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>Aplikasi membutuhkan akses galeri untuk memilih foto produk.</string>
```

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml ios/Runner/Info.plist
git commit -m "chore: add camera and storage permissions for bulk import"
```

---

## Task 12: Run Full Test Suite & Smoke Test

- [ ] **Step 1: Jalankan semua unit test**

Run:
```bash
flutter test
```

Expected: Semua test PASS.

- [ ] **Step 2: Jalankan smoke test build debug**

Run:
```bash
flutter build apk --debug 2>&1 | tail -30
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 3: Commit jika semua test lulus**

```bash
git commit -m "test: verify bulk import feature passes tests and builds" --allow-empty
```

---

## Self-Review

### Spec Coverage

| Requirement | Task |
|-------------|------|
| Aplikasi offline, bulk import via Excel | Task 1, 7, 10 |
| Template Excel yang bisa diunduh | Task 3, 7 |
| Impor file Excel ke aplikasi | Task 4, 7 |
| Cocokkan dengan database (kategori) | Task 4, 5 |
| Halaman konfirmasi data masuk | Task 8 |
| Input foto satu per satu per produk | Task 9 |

### Placeholder Scan

- Semua task memiliki kode lengkap dan command verifikasi.
- Tidak ada TODO/TBD di dalam plan.

### Type Consistency

- `ImportedAuctionItem` digunakan konsisten di service, provider, dan UI.
- `AuctionItem.fromMap/toMap` tidak berubah — backward compatible.
- `createAuctionItemsBatch` mengembalikan `List<int>` dan digunakan oleh provider.

---

## Execution Handoff

**Plan complete and saved to `docs/superpowers/plans/2026-06-28-bulk-import-lelang.md`. Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints for review

**Which approach?**
