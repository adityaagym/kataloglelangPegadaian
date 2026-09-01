import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/filter_sheet.dart';
import '../utils/app_colors.dart';
import 'admin/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  DateTime _currentDeviceTime = DateTime.now();
  Timer? _timeTimer;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _currentDeviceTime = DateTime.now();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentDeviceTime = DateTime.now();
        });
      }
    });
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters({double? minPrice, double? maxPrice}) {
    setState(() => _currentPage = 1);
    Provider.of<AppProvider>(context, listen: false).filterItems(
      query: _searchController.text,
      categoryIds: _selectedCategoryId != null ? [_selectedCategoryId!] : null,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  void _showFilterSheet() {
    showDialog(
      context: context,
      barrierColor: AppColors.muted.withValues(alpha: 0.88),
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        backgroundColor: Colors.transparent,
        child: FilterSheet(
          initialCategoryId: _selectedCategoryId,
          onApply: (categoryId, minPrice, maxPrice) {
            setState(() => _selectedCategoryId = categoryId);
            _applyFilters(minPrice: minPrice, maxPrice: maxPrice);
          },
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  top: -300,
                  left: -250,
                  child: Container(
                    width: 650,
                    height: 650,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -300,
                  right: -250,
                  child: Container(
                    width: 650,
                    height: 650,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHero(currencyFormatter),
                        _buildCatalogGrid(),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isPortrait = MediaQuery.of(context).size.width < 900;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isPortrait ? 16 : 40,
        isPortrait ? 16 : 24,
        isPortrait ? 16 : 40,
        8,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: isPortrait ? 76 : 108),
        padding: EdgeInsets.symmetric(
          horizontal: isPortrait ? 16 : 28,
          vertical: isPortrait ? 12 : 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onLongPress: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: Container(
                width: isPortrait ? 140 : 280,
                height: isPortrait ? 52 : 84,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(
                  'assets/logo_silas_horizontal.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
            SizedBox(width: isPortrait ? 16 : 28),
            Container(
              width: 1,
              height: isPortrait ? 52 : 84,
              color: AppColors.border,
            ),
            SizedBox(width: isPortrait ? 16 : 28),
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, _) => Text(
                  isPortrait
                      ? provider.branchName
                      : 'Cabang ${provider.branchName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: isPortrait ? 18 : 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            if (!isPortrait) ...[
              const SizedBox(width: 12),
              _headerPill(
                Icons.access_time,
                DateFormat('HH:mm').format(_currentDeviceTime),
                null,
                isCompact: false,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _headerPill(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isCompact = false,
  }) {
    final isInteractive = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: BoxConstraints(
          minHeight: isCompact ? 40 : 48,
          minWidth: isCompact ? 40 : 0,
        ),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 20),
        decoration: BoxDecoration(
          color: isInteractive ? AppColors.primaryLight : AppColors.muted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isInteractive
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isCompact ? 18 : 20,
              color: isInteractive
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isInteractive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHero(NumberFormat currencyFormatter) {
    final isPortrait = MediaQuery.of(context).size.width < 900;

    final goldCard = Consumer<AppProvider>(
      builder: (context, provider, _) => Container(
        width: isPortrait ? double.infinity : 320,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Harga emas hari ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${currencyFormatter.format(provider.goldPricePerGram)} / gram',
              style: TextStyle(
                fontSize: isPortrait ? 22 : 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Temukan barang lelang yang tersedia.',
          style: TextStyle(
            fontSize: isPortrait ? 25 : 30,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gunakan pencarian atau filter untuk mencari perhiasan emas, elektronik, logam mulia, dan kendaraan.',
          style: TextStyle(
            fontSize: isPortrait ? 15 : 20,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isPortrait ? 16 : 40,
        8,
        isPortrait ? 16 : 40,
        isPortrait ? 12 : 16,
      ),
      child: Container(
        padding: EdgeInsets.all(isPortrait ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            isPortrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      goldCard,
                      const SizedBox(height: 16),
                      infoColumn,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: infoColumn),
                      const SizedBox(width: 24),
                      goldCard,
                    ],
                  ),
            SizedBox(height: isPortrait ? 16 : 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: isPortrait ? 52 : 56,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: isPortrait ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari perhiasan, handphone, laptop...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: isPortrait ? 16 : 21,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 10),
                          child: Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: isPortrait ? 20 : 22,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: _searchController.clear,
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.muted,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: isPortrait ? 52 : 56,
                  child: ElevatedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: Icon(Icons.tune, size: isPortrait ? 18 : 20),
                    label: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: isPortrait ? 14 : 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPortrait ? 20 : 28,
                      ),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogGrid() {
    final isPortrait = MediaQuery.of(context).size.width < 900;
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (provider.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(40, 14, 40, 32),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(42),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 44,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Barang Tidak Ditemukan',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Coba kata kunci lain atau reset filter agar daftar barang kembali lengkap.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 16,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _selectedCategoryId = null);
                          _applyFilters();
                        },
                        child: const Text(
                          'Reset Pencarian & Filter',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final totalItems = provider.items.length;
        final totalPages = (totalItems / 20).ceil();
        final displayPages = totalPages == 0 ? 1 : totalPages;
        final currentPage = _currentPage.clamp(1, displayPages);

        final startIndex = (currentPage - 1) * 20;
        final endIndex = startIndex + 20;
        final paginatedItems = provider.items.sublist(
          startIndex,
          endIndex > totalItems ? totalItems : endIndex,
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            isPortrait ? 16 : 40,
            14,
            isPortrait ? 16 : 40,
            18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isPortrait
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Barang Lelang Tersedia',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${provider.items.length} barang',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kartu dibuat lebih besar agar nyaman dibaca nasabah.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xCC000000),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barang Lelang Tersedia',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Temukan dan beli barang lelang pilihan anda.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xCC000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${provider.items.length} barang aktif',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobilePortrait = screenWidth < 600;
                  final crossAxisCount = isMobilePortrait ? 2 : (isPortrait ? 3 : 4);
                  final childAspectRatio = isMobilePortrait
                      ? 0.58
                      : (isPortrait ? 0.50 : 0.52);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: isPortrait ? 12 : 28,
                      mainAxisSpacing: isPortrait ? 16 : 28,
                    ),
                    itemCount: paginatedItems.length,
                    itemBuilder: (context, index) =>
                        ItemCard(item: paginatedItems[index]),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final isPortrait = MediaQuery.of(context).size.width < 900;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final totalItems = provider.items.length;
        final totalPages = (totalItems / 20).ceil();
        final displayPages = totalPages == 0 ? 1 : totalPages;
        final currentPage = _currentPage.clamp(1, displayPages);

        final startIndex = totalItems == 0 ? 0 : (currentPage - 1) * 20 + 1;
        final endIndex = (currentPage * 20).clamp(0, totalItems);

        return Container(
          height: isPortrait ? 76 : 88,
          padding: EdgeInsets.symmetric(horizontal: isPortrait ? 16 : 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Text.rich(
                TextSpan(
                  text: 'Menampilkan ',
                  children: [
                    TextSpan(
                      text: totalItems == 0 ? '0' : '$startIndex - $endIndex',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextSpan(text: ' dari $totalItems barang'),
                  ],
                ),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isPortrait ? 14 : 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _footerCircle(
                Icons.chevron_left,
                currentPage > 1,
                isPortrait,
                currentPage > 1
                    ? () => setState(() => _currentPage = currentPage - 1)
                    : null,
              ),
              SizedBox(width: isPortrait ? 8 : 12),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isPortrait ? 16 : 24,
                  vertical: isPortrait ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Halaman $currentPage dari $displayPages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isPortrait ? 12 : 14,
                  ),
                ),
              ),
              SizedBox(width: isPortrait ? 8 : 12),
              _footerCircle(
                Icons.chevron_right,
                currentPage < displayPages,
                isPortrait,
                currentPage < displayPages
                    ? () => setState(() => _currentPage = currentPage + 1)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _footerCircle(
    IconData icon,
    bool filled,
    bool isPortrait,
    VoidCallback? onTap,
  ) {
    final size = isPortrait ? 40.0 : 48.0;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : AppColors.textMuted,
          size: isPortrait ? 20 : 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
