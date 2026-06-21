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

  List<Category> get categories => _categories;
  List<AuctionItem> get items => _filteredItems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

    _isLoading = false;
    notifyListeners();
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
    notifyListeners();
  }

  Future<void> deleteItem(int id) async {
    await _dbHelper.deleteAuctionItem(id);
    await refreshAdminData();
  }
}
