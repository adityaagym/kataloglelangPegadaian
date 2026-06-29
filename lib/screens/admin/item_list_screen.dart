import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import '../../utils/app_colors.dart';
import 'item_form_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _filterCategoryId;
  String _sortBy = 'Terbaru';
  
  // Selection state
  final Set<int> _selectedItemIds = {};
  
  // Pagination state
  int _currentPage = 0;
  static const int _itemsPerPage = 50;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Hapus Barang Lelang?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Data '${item.name}' akan dihapus dari database lokal dan tidak dapat dikembalikan.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B5563),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).deleteItem(item.id!);
                              setState(() {
                                _selectedItemIds.remove(item.id);
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w800)),
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

  void _confirmDeleteSelected(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Hapus ${_selectedItemIds.length} Barang Terpilih?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Seluruh ${_selectedItemIds.length} data barang yang terpilih akan dihapus permanen dari database lokal cabang.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4B5563),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () async {
                              final provider = Provider.of<AppProvider>(context, listen: false);
                              await provider.deleteItems(_selectedItemIds.toList());
                              setState(() {
                                _selectedItemIds.clear();
                              });
                              if (context.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            child: const Text('Hapus Semua', style: TextStyle(fontWeight: FontWeight.w800)),
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

    final searchField = SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: (_) {
          setState(() {
            _currentPage = 0;
            _selectedItemIds.clear();
          });
        },
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama atau nomor akad...',
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );

    final categoryDropdown = Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _filterCategoryId,
              isExpanded: true,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              hint: const Text(
                'Kategori',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
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
              onChanged: (val) {
                setState(() {
                  _filterCategoryId = val;
                  _currentPage = 0;
                  _selectedItemIds.clear();
                });
              },
            ),
          ),
        );
      },
    );

    final sortDropdown = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _sortBy,
          isExpanded: true,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          items: ['Terbaru', 'Harga naik', 'Harga turun', 'Nama A-Z']
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _sortBy = val!;
              _currentPage = 0;
              _selectedItemIds.clear();
            });
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Lower the header
            // Title
            const Text(
              'Daftar Barang Lelang',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kelola data barang lelang pada database offline cabang.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600),
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
                      Expanded(
                        flex: 4,
                        child: searchField,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: categoryDropdown,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: sortDropdown,
                      ),
                    ],
                  ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
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
                              size: 48,
                              color: const Color(0xFF9CA3AF).withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Belum ada data barang lelang.',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Pagination logic
                    final int totalItems = items.length;
                    final int totalPages = (totalItems / _itemsPerPage).ceil();
                    
                    if (_currentPage >= totalPages && totalPages > 0) {
                      _currentPage = totalPages - 1;
                    }

                    final int startIndex = _currentPage * _itemsPerPage;
                    final int endIndex = (startIndex + _itemsPerPage) > totalItems ? totalItems : (startIndex + _itemsPerPage);
                    final pageItems = items.sublist(startIndex, endIndex);

                    // Check if all visible items on this page are selected
                    final bool isAllPageItemsSelected = pageItems.every((item) => _selectedItemIds.contains(item.id));

                    return Column(
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                          ),
                          child: Row(
                            children: [
                              // Selection Checkbox in Header
                              SizedBox(
                                width: 40,
                                child: Checkbox(
                                  value: isAllPageItemsSelected && pageItems.isNotEmpty,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        for (final item in pageItems) {
                                          _selectedItemIds.add(item.id!);
                                        }
                                      } else {
                                        for (final item in pageItems) {
                                          _selectedItemIds.remove(item.id!);
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 40,
                                child: Text(
                                  'NO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 70,
                                child: Text(
                                  'FOTO',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                flex: 4,
                                child: Text(
                                  'NAMA BARANG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'NO AKAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    'KATEGORI',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: Color(0xFF374151),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                flex: 3,
                                child: Text(
                                  'HARGA DASAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: Color(0xFF374151),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              // Bulk Delete Button or AXIS header
                              SizedBox(
                                width: 120,
                                child: _selectedItemIds.isNotEmpty
                                    ? TextButton.icon(
                                        style: TextButton.styleFrom(
                                          backgroundColor: const Color(0xFFFEE2E2),
                                          foregroundColor: const Color(0xFFDC2626),
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                        onPressed: () => _confirmDeleteSelected(context),
                                        icon: const Icon(Icons.delete_outline, size: 14),
                                        label: Text(
                                          '(${_selectedItemIds.length})',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                                        ),
                                      )
                                    : const Text(
                                        'AKSI',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          color: Color(0xFF374151),
                                          letterSpacing: 0.8,
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
                            itemCount: pageItems.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            itemBuilder: (context, index) {
                              final item = pageItems[index];
                              final isSelected = _selectedItemIds.contains(item.id);
                              
                              return Container(
                                color: isSelected ? const Color(0xFFF9FAFB) : null,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Checkbox for selection
                                    SizedBox(
                                      width: 40,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: AppColors.primary,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedItemIds.add(item.id!);
                                            } else {
                                              _selectedItemIds.remove(item.id!);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${startIndex + index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
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
                                              borderRadius: BorderRadius.circular(6),
                                              child: Image.file(
                                                File(
                                                  snapshot.data!.first.localPath,
                                                ),
                                                width: 44,
                                                height: 44,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        _placeholderThumb(),
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
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF111827),
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (item.description != null &&
                                              item.description!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              item.description!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF9CA3AF),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // No Akad
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          item.creditNumber?.isNotEmpty == true
                                              ? item.creditNumber!
                                              : '-',
                                          style: const TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Category
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _buildFlatCategoryBadge(item.categoryName ?? '-'),
                                        ),
                                      ),
                                    ),
                                    // Price
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        currencyFormatter.format(item.basePrice),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
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
                                            const Color(0xFFE3F2FD),
                                            AppColors.info,
                                            () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ItemFormScreen(
                                                    itemToEdit: item,
                                                  ),
                                                ),
                                              ).then((_) {
                                                provider.refreshAdminData();
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          _buildActionButton(
                                            Icons.delete_outline,
                                            const Color(0xFFFFEBEE),
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

                        // Pagination controls at the bottom
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(6),
                              ),
                              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Menampilkan ${startIndex + 1}-$endIndex dari $totalItems barang',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Previous button
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left),
                                      onPressed: _currentPage > 0
                                          ? () => setState(() => _currentPage--)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    // Page numbers
                                    ...List.generate(totalPages, (pageIndex) {
                                      final isCurrentPage = pageIndex == _currentPage;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: InkWell(
                                          onTap: () => setState(() => _currentPage = pageIndex),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isCurrentPage ? AppColors.primary : Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isCurrentPage ? AppColors.primary : const Color(0xFFD1D5DB),
                                              ),
                                            ),
                                            child: Text(
                                              '${pageIndex + 1}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                color: isCurrentPage ? Colors.white : const Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    // Next button
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right),
                                      onPressed: _currentPage < totalPages - 1
                                          ? () => setState(() => _currentPage++)
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Menampilkan ${startIndex + 1}-$endIndex dari $totalItems barang',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF9CA3AF),
        size: 20,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _buildFlatCategoryBadge(String categoryName) {
    final name = categoryName.toLowerCase();

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (name.contains('perhiasan') || (name.contains('emas') && !name.contains('logam'))) {
      // Perhiasan Emas — amber
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      borderColor = const Color(0xFFFDE68A);
    } else if (name.contains('logam')) {
      // Logam Mulia — slate
      bgColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF475569);
      borderColor = const Color(0xFFCBD5E1);
    } else if (name.contains('elektronik')) {
      // Elektronik — indigo
      bgColor = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF4338CA);
      borderColor = const Color(0xFFC4B5FD);
    } else if (name.contains('kendaraan')) {
      // Kendaraan — dark blue
      bgColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF1E3A8A);
      borderColor = const Color(0xFFBFDBFE);
    } else {
      // Default — neutral grey
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF374151);
      borderColor = const Color(0xFFE5E7EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        categoryName.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
