import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import '../../utils/app_colors.dart';
import 'item_form_screen.dart';
import 'dart:io';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _filterCategoryId;
  String _sortBy = 'Terbaru';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).refreshAdminData();
    });
  }

  List<AuctionItem> _getFilteredItems(List<AuctionItem> allItems) {
    var items = List<AuctionItem>.from(allItems);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      items = items.where((item) =>
        item.name.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Category filter
    if (_filterCategoryId != null) {
      items = items.where((item) => item.categoryId == _filterCategoryId).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Terbaru':
        items.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case 'Harga ↑':
        items.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'Harga ↓':
        items.sort((a, b) => b.basePrice.compareTo(a.basePrice));
        break;
      case 'Nama A-Z':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return items;
  }

  void _confirmDelete(BuildContext context, AuctionItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Barang Lelang?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text("Apakah Anda yakin ingin menghapus '${item.name}'?\nTindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).deleteItem(item.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Ya, Hapus Permanen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Daftar Barang Lelang',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola data barang lelang pada database offline cabang.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Search, Category filter, Sort
          Row(
            children: [
              // Search
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan nama...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Category dropdown
              Expanded(
                flex: 2,
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: _filterCategoryId,
                          isExpanded: true,
                          hint: const Text('Kategori', style: TextStyle(color: AppColors.textMuted)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Semua Kategori')),
                            ...provider.categories.map((c) =>
                              DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                            ),
                          ],
                          onChanged: (val) => setState(() => _filterCategoryId = val),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Sort dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    items: ['Terbaru', 'Harga ↑', 'Harga ↓', 'Nama A-Z']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _sortBy = val!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  final items = _getFilteredItems(provider.items);

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          const Text('Belum ada data barang lelang.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 50, child: Text('NO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary))),
                            SizedBox(width: 70, child: Text('THUMBNAIL', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary))),
                            SizedBox(width: 16),
                            Expanded(flex: 3, child: Text('NAMA BARANG', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary))),
                            Expanded(flex: 2, child: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary))),
                            Expanded(flex: 2, child: Text('HARGA DASAR', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary))),
                            SizedBox(width: 120, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                          ],
                        ),
                      ),

                      // Table rows
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text('${index + 1}', style: const TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  // Thumbnail
                                  SizedBox(
                                    width: 70,
                                    child: FutureBuilder(
                                      future: provider.getItemPhotos(item.id!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: Image.file(
                                              File(snapshot.data!.first.localPath),
                                              width: 50, height: 50, fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => _placeholderThumb(),
                                            ),
                                          );
                                        }
                                        return _placeholderThumb();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Name
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
                                    ),
                                  ),
                                  // Category
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.categoryName ?? '-',
                                      style: const TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                  // Price
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      currencyFormatter.format(item.basePrice),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  // Actions
                                  SizedBox(
                                    width: 120,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          Icons.edit_outlined,
                                          AppColors.info,
                                          () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => Scaffold(body: ItemFormScreen(itemToEdit: item)),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionButton(
                                          Icons.delete_outline,
                                          AppColors.error,
                                          () => _confirmDelete(context, item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: AppColors.accentLighter,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted, size: 24),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
