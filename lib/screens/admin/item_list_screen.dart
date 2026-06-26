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
      final query = _searchController.text.toLowerCase();
      items = items
          .where(
            (item) =>
                item.name.toLowerCase().contains(query) ||
                (item.creditNumber ?? '').toLowerCase().contains(query),
          )
          .toList();
    }

    // Category filter
    if (_filterCategoryId != null) {
      items = items
          .where((item) => item.categoryId == _filterCategoryId)
          .toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Terbaru':
        items.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        break;
      case 'Harga naik':
        items.sort((a, b) => a.basePrice.compareTo(b.basePrice));
        break;
      case 'Harga turun':
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 460,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.destructive,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.destructive.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.destructive,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Hapus Barang Lelang?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Data '${item.name}' akan dihapus dari database lokal dan tidak dapat dikembalikan.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.destructive,
                            ),
                            onPressed: () {
                              Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).deleteItem(item.id!);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Hapus'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isPortrait = MediaQuery.of(context).size.width < 900;

    final searchField = TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Cari nama atau nomor akad...',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textMuted,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
    );

    final categoryDropdown = Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _filterCategoryId,
              isExpanded: true,
              hint: const Text(
                'Kategori',
                style: TextStyle(color: AppColors.textMuted),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Semua Kategori'),
                ),
                ...provider.categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (val) =>
                  setState(() => _filterCategoryId = val),
            ),
          ),
        );
      },
    );

    final sortDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isExpanded: isPortrait,
          items: ['Terbaru', 'Harga naik', 'Harga turun', 'Nama A-Z']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) => setState(() => _sortBy = val!),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Daftar Barang Lelang',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola data barang lelang pada database offline cabang.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Search, Category filter, Sort
          isPortrait
              ? Column(
                  children: [
                    searchField,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: categoryDropdown),
                        const SizedBox(width: 12),
                        Expanded(child: sortDropdown),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Search
                    Expanded(
                      flex: 3,
                      child: searchField,
                    ),
                    const SizedBox(width: 16),
                    // Category dropdown
                    Expanded(
                      flex: 2,
                      child: categoryDropdown,
                    ),
                    const SizedBox(width: 16),
                    // Sort dropdown
                    sortDropdown,
                  ],
                ),
          const SizedBox(height: 24),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada data barang lelang.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                'NO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                'THUMBNAIL',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'NAMA BARANG',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'NO AKAD',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'KATEGORI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'HARGA DASAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'AKSI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table rows
                      Expanded(
                        child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  // Thumbnail
                                  SizedBox(
                                    width: 70,
                                    child: FutureBuilder(
                                      future: provider.getItemPhotos(item.id!),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData &&
                                            snapshot.data!.isNotEmpty) {
                                          return ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.file(
                                              File(
                                                snapshot.data!.first.localPath,
                                              ),
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => _placeholderThumb(),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        if ((item.creditNumber ?? '')
                                            .isNotEmpty)
                                          const SizedBox(height: 3),
                                        if ((item.creditNumber ?? '')
                                            .isNotEmpty)
                                          const Text(
                                            'Bagian dari akad yang dapat berisi beberapa barang',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.creditNumber?.isNotEmpty == true
                                          ? item.creditNumber!
                                          : '-',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  // Category
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.categoryBadgeBg(
                                            item.categoryName,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          item.categoryName ?? '-',
                                          style: TextStyle(
                                            color: AppColors.categoryBadgeText(
                                              item.categoryName,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          Icons.edit_outlined,
                                          AppColors.info,
                                          () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => Scaffold(
                                                  body: ItemFormScreen(
                                                    itemToEdit: item,
                                                  ),
                                                ),
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
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.accentLighter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textMuted,
        size: 24,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
