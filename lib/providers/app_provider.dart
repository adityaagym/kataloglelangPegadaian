import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/auction_item.dart';
import '../models/category.dart';
import '../models/imported_auction_item.dart';
import '../models/item_photo.dart';
import '../services/excel_import_service.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Category> _categories = [];
  List<AuctionItem> _allItems = [];
  List<AuctionItem> _filteredItems = [];
  double _goldPricePerGram = 1120000;
  String? _goldPriceUpdatedAt;
  String? _lastItemUpdatedAt;

  // --- Bulk Import State ---
  List<ImportedAuctionItem> _importDraftItems = [];
  List<ImportedAuctionItem> get importDraftItems => _importDraftItems;
  bool get hasImportDraft => _importDraftItems.isNotEmpty;
  int get selectedImportCount =>
      _importDraftItems.where((i) => i.isSelected && i.isValid).length;

  List<Category> get categories => _categories;
  List<AuctionItem> get items => _filteredItems;
  List<AuctionItem> get allItems => _allItems;
  double get goldPricePerGram => _goldPricePerGram;
  String? get goldPriceUpdatedAt => _goldPriceUpdatedAt;
  String? get lastItemUpdatedAt => _lastItemUpdatedAt;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Branch name - could be made configurable later
  String get branchName => 'Simpang Patal';

  AppProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    await _dbHelper.database; // Ensure DB is initialized
    _categories = await _dbHelper.readAllCategories();
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: true);
    _filteredItems = List.from(_allItems);
    await _loadGoldPrice();
    await _loadLastItemUpdateTime();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadGoldPrice() async {
    _goldPricePerGram = await _dbHelper.getGoldPricePerGram();
    final record = await _dbHelper.getLatestGoldPriceRecord();
    if (record != null) {
      _goldPriceUpdatedAt = record['updated_at'] as String?;
    }
  }

  Future<void> _loadLastItemUpdateTime() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT MAX(created_at) as max_date FROM auction_items',
    );
    if (result.isNotEmpty && result.first['max_date'] != null) {
      _lastItemUpdatedAt = result.first['max_date'] as String;
    } else {
      _lastItemUpdatedAt = null;
    }
  }

  Future<List<ItemPhoto>> getItemPhotos(int itemId) async {
    return await _dbHelper.readItemPhotos(itemId);
  }

  Future<List<AuctionItem>> getItemsByCreditNumber(String creditNumber) async {
    return await _dbHelper.readAuctionItemsByCreditNumber(creditNumber);
  }

  void filterItems({
    String query = '',
    List<int>? categoryIds,
    double? minPrice,
    double? maxPrice,
  }) {
    _filteredItems = _allItems.where((item) {
      bool matchesQuery = item.name.toLowerCase().contains(query.toLowerCase());
      bool matchesCategory =
          categoryIds == null ||
          categoryIds.isEmpty ||
          categoryIds.contains(item.categoryId);
      bool matchesMinPrice = minPrice == null || item.basePrice >= minPrice;
      bool matchesMaxPrice = maxPrice == null || item.basePrice <= maxPrice;

      return matchesQuery &&
          matchesCategory &&
          matchesMinPrice &&
          matchesMaxPrice;
    }).toList();
    notifyListeners();
  }

  Future<void> refreshAdminData() async {
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: false);
    _filteredItems = List.from(_allItems);
    _categories = await _dbHelper.readAllCategories();
    await _loadGoldPrice();
    await _loadLastItemUpdateTime();
    notifyListeners();
  }

  Future<void> refreshPublicData() async {
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: true);
    _filteredItems = List.from(_allItems);
    _categories = await _dbHelper.readAllCategories();
    await _loadGoldPrice();
    await _loadLastItemUpdateTime();
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _dbHelper.deleteAuctionItem(id);
    await refreshAdminData();
  }

  // --- Gold Price ---
  Future<void> updateGoldPrice(double pricePerGram) async {
    await _dbHelper.updateGoldPrice(pricePerGram);
    await _dbHelper.recalculateGoldItemPrices();
    await _loadGoldPrice();
    // Refresh items to reflect new prices
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: false);
    _filteredItems = List.from(_allItems);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getGoldItemsPreview() async {
    return await _dbHelper.getGoldItemsWithCalculatedPrice();
  }

  // --- Stats ---
  Future<int> getActiveItemCount() async {
    return await _dbHelper.getActiveItemCount();
  }

  Future<Map<String, dynamic>?> getTopCategory() async {
    return await _dbHelper.getTopCategory();
  }

  Future<List<Map<String, dynamic>>> getRecentItems({int limit = 3}) async {
    return await _dbHelper.getRecentItems(limit: limit);
  }

  // --- Financing ---
  Future<Map<String, dynamic>?> getActiveFinancingConfig() async {
    return await _dbHelper.getActiveFinancingConfig();
  }

  Future<Map<String, dynamic>?> getLatestFinancingConfig() async {
    return await _dbHelper.getLatestFinancingConfig();
  }

  Future<List<Map<String, dynamic>>> getFinancingTenors(int configId) async {
    return await _dbHelper.getFinancingTenors(configId);
  }

  Future<void> saveFinancingConfig({
    required String dpOptions,
    required double adminFeeFlat,
    required double adminFeePercent,
    required double munahRate,
    required bool isActive,
    required List<Map<String, dynamic>> tenors,
    double stlPrice = 502894,
    double hdlePrice = 550000,
    double loanRatio = 0.95,
    double umPercentageKca = 0.192,
    double umPercentageKrasida = 0.185,
    double bungaKca = 0.0125,
    int tempoKca = 4,
    int minimumUpKca = 500000,
    int minimumUpKrasida = 500000,
  }) async {
    await _dbHelper.saveFinancingConfig(
      dpOptions: dpOptions,
      adminFeeFlat: adminFeeFlat,
      adminFeePercent: adminFeePercent,
      munahRate: munahRate,
      isActive: isActive,
      tenors: tenors,
      stlPrice: stlPrice,
      hdlePrice: hdlePrice,
      loanRatio: loanRatio,
      umPercentageKca: umPercentageKca,
      umPercentageKrasida: umPercentageKrasida,
      bungaKca: bungaKca,
      tempoKca: tempoKca,
      minimumUpKca: minimumUpKca,
      minimumUpKrasida: minimumUpKrasida,
    );
    notifyListeners();
  }

  // --- Database Path (for backup) ---
  Future<String> getDatabasePath() async {
    return await _dbHelper.getDatabasePath();
  }

  // --- Bulk Import ---
  Future<List<ImportedAuctionItem>> parseImportFile(Uint8List fileBytes) async {
    final categories = await _dbHelper.readAllCategories();
    final goldPrice = goldPricePerGram;
    final parsed = await ExcelImportService.parseFile(fileBytes, categories, goldPrice: goldPrice);
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

  Future<void> attachPhotoToItem(
    int itemId,
    String localPath, {
    bool isPrimary = false,
  }) async {
    final photos = await _dbHelper.readItemPhotos(itemId);
    await _dbHelper.createItemPhoto(ItemPhoto(
      itemId: itemId,
      localPath: localPath,
      isPrimary: isPrimary,
      sortOrder: photos.length,
    ));
    notifyListeners();
  }

  void clearImportDraft() {
    _importDraftItems = [];
    notifyListeners();
  }
}
