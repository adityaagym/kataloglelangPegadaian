import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/auction_item.dart';
import '../models/category.dart';
import '../models/item_photo.dart';

class AppProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Category> _categories = [];
  List<AuctionItem> _allItems = [];
  List<AuctionItem> _filteredItems = [];
  double _goldPricePerGram = 1120000;
  String? _goldPriceUpdatedAt;

  List<Category> get categories => _categories;
  List<AuctionItem> get items => _filteredItems;
  List<AuctionItem> get allItems => _allItems;
  double get goldPricePerGram => _goldPricePerGram;
  String? get goldPriceUpdatedAt => _goldPriceUpdatedAt;

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

  Future<List<ItemPhoto>> getItemPhotos(int itemId) async {
    return await _dbHelper.readItemPhotos(itemId);
  }

  void filterItems({String query = '', List<int>? categoryIds, double? minPrice, double? maxPrice}) {
    _filteredItems = _allItems.where((item) {
      bool matchesQuery = item.name.toLowerCase().contains(query.toLowerCase());
      bool matchesCategory = categoryIds == null || categoryIds.isEmpty || categoryIds.contains(item.categoryId);
      bool matchesMinPrice = minPrice == null || item.basePrice >= minPrice;
      bool matchesMaxPrice = maxPrice == null || item.basePrice <= maxPrice;

      return matchesQuery && matchesCategory && matchesMinPrice && matchesMaxPrice;
    }).toList();
    notifyListeners();
  }

  Future<void> refreshAdminData() async {
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: false);
    _filteredItems = List.from(_allItems);
    _categories = await _dbHelper.readAllCategories();
    await _loadGoldPrice();
    notifyListeners();
  }

  Future<void> refreshPublicData() async {
    _allItems = await _dbHelper.readAllAuctionItems(activeOnly: true);
    _filteredItems = List.from(_allItems);
    _categories = await _dbHelper.readAllCategories();
    await _loadGoldPrice();
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
  }) async {
    await _dbHelper.saveFinancingConfig(
      dpOptions: dpOptions,
      adminFeeFlat: adminFeeFlat,
      adminFeePercent: adminFeePercent,
      munahRate: munahRate,
      isActive: isActive,
      tenors: tenors,
    );
    notifyListeners();
  }

  // --- Database Path (for backup) ---
  Future<String> getDatabasePath() async {
    return await _dbHelper.getDatabasePath();
  }
}
