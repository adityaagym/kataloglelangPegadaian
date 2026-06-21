import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/filter_sheet.dart';
import '../utils/idle_timeout_wrapper.dart';
import 'admin/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters({double? minPrice, double? maxPrice}) {
    Provider.of<AppProvider>(context, listen: false).filterItems(
      query: _searchController.text,
      categoryIds: _selectedCategoryId != null ? [_selectedCategoryId!] : null,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  void _resetKiosk() {
    // Reset to initial state
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
    });
    _applyFilters();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialCategoryId: _selectedCategoryId,
        onApply: (categoryId, minPrice, maxPrice) {
          setState(() {
            _selectedCategoryId = categoryId;
          });
          _applyFilters(minPrice: minPrice, maxPrice: maxPrice);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IdleTimeoutWrapper(
      onTimeout: _resetKiosk,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 80,
          title: Row(
            children: [
              GestureDetector(
                onLongPress: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.gavel, color: Colors.white), // Placeholder logo
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Katalog Barang Lelang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.all(24.0),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari nama barang lelang...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: const Color(0xFFF5F7FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip('Semua', null),
                            ...provider.categories.map((c) => _buildFilterChip(c.name, c.id)).toList(),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('⚙ Filter'),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              onPressed: _showFilterSheet,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Grid
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.items.isEmpty) {
                    return const Center(child: Text('Barang tidak ditemukan.'));
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // For landscape tablet
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: provider.items.length,
                      itemBuilder: (context, index) {
                        return ItemCard(item: provider.items[index]);
                      },
                    ),
                  );
                },
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer<AppProvider>(
                    builder: (context, provider, child) {
                      return Text('Menampilkan ${provider.items.length} dari ${provider.items.length} barang',
                        style: const TextStyle(color: Colors.grey));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? categoryId) {
    bool isSelected = _selectedCategoryId == categoryId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF1B5E20),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1B5E20)),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20)),
        onSelected: (selected) {
          setState(() {
            _selectedCategoryId = selected ? categoryId : null;
          });
          _applyFilters();
        },
      ),
    );
  }
}
