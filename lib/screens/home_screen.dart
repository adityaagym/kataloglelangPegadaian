import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/filter_sheet.dart';
import '../utils/idle_timeout_wrapper.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters({double? minPrice, double? maxPrice}) {
    Provider.of<AppProvider>(context, listen: false).filterItems(
      query: _searchController.text,
      categoryIds: _selectedCategoryId != null ? [_selectedCategoryId!] : null,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  void _resetKiosk() {
    _searchController.clear();
    setState(() => _selectedCategoryId = null);
    _applyFilters();
    Navigator.of(context).popUntil((route) => route.isFirst);
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

    return IdleTimeoutWrapper(
      onTimeout: _resetKiosk,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
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
        ),
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
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo_pegadaian_syariah.png',
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
                  isPortrait ? provider.branchName : 'Cabang ${provider.branchName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPortrait ? 18 : 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            _headerPill(
              Icons.lock_outline,
              isPortrait ? '' : 'Admin',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              isCompact: isPortrait,
            ),
            if (!isPortrait) ...[
              const SizedBox(width: 12),
              _headerPill(
                Icons.access_time,
                DateFormat('HH:mm').format(DateTime.now()),
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
          color: Colors.white.withValues(alpha: onTap == null ? 0.10 : 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: onTap == null ? 0.20 : 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: isCompact ? 18 : 20, color: Colors.white),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
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
        width: isPortrait ? double.infinity : 390,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Harga emas hari ini',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${currencyFormatter.format(provider.goldPricePerGram)} / gram',
              style: TextStyle(
                fontSize: isPortrait ? 26 : 34,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Harga produk emas otomatis menyesuaikan.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.successGreen.withValues(
                  alpha: 0.70,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Temukan barang lelang terpercaya dengan tampilan yang jelas dan mudah dibaca.',
          style: TextStyle(
            fontSize: isPortrait ? 24 : 34,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Gunakan pencarian besar atau filter sederhana untuk melihat perhiasan emas, elektronik, logam mulia, dan kendaraan.',
          style: TextStyle(
            fontSize: isPortrait ? 15 : 20,
            fontWeight: FontWeight.w600,
            height: 1.55,
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
        isPortrait ? 16 : 20,
      ),
      child: Container(
        padding: EdgeInsets.all(isPortrait ? 20 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isPortrait ? 28 : 40),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 50,
              offset: const Offset(0, 15),
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
                      const SizedBox(height: 20),
                      infoColumn,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: infoColumn),
                      const SizedBox(width: 40),
                      goldCard,
                    ],
                  ),
            SizedBox(height: isPortrait ? 20 : 30),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: isPortrait ? 64 : 80,
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: isPortrait ? 18 : 22,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari perhiasan, handphone, laptop...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: isPortrait ? 18 : 24,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            left: isPortrait ? 16 : 22,
                            right: isPortrait ? 10 : 14,
                          ),
                          child: Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: isPortrait ? 26 : 32,
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
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: isPortrait ? 12 : 20),
                SizedBox(
                  height: isPortrait ? 64 : 80,
                  child: ElevatedButton.icon(
                    onPressed: _showFilterSheet,
                    icon: Icon(Icons.tune, size: isPortrait ? 20 : 26),
                    label: Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: isPortrait ? 16 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isPortrait ? 24 : 40,
                      ),
                      backgroundColor: AppColors.primary,
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
                                  color: AppColors.textDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 18,
                                  ),
                                ],
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
                                'Kartu dibuat lebih besar agar nyaman dibaca nasabah lanjut usia.',
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 18,
                              ),
                            ],
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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isPortrait ? 3 : 4,
                  childAspectRatio: isPortrait ? 0.46 : 0.49,
                  crossAxisSpacing: isPortrait ? 16 : 28,
                  mainAxisSpacing: isPortrait ? 16 : 28,
                ),
                itemCount: provider.items.length,
                itemBuilder: (context, index) =>
                    ItemCard(item: provider.items[index]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    final isPortrait = MediaQuery.of(context).size.width < 900;
    
    return Container(
      height: isPortrait ? 76 : 88,
      padding: EdgeInsets.symmetric(horizontal: isPortrait ? 16 : 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        children: [
          Consumer<AppProvider>(
            builder: (context, provider, child) => Text.rich(
              TextSpan(
                text: 'Menampilkan ',
                children: [
                  TextSpan(
                    text: '${provider.items.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(text: ' barang'),
                ],
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: isPortrait ? 14 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          _footerCircle(Icons.chevron_left, false, isPortrait),
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
              'Halaman 1 dari 1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: isPortrait ? 12 : 14,
              ),
            ),
          ),
          SizedBox(width: isPortrait ? 8 : 12),
          _footerCircle(Icons.chevron_right, true, isPortrait),
        ],
      ),
    );
  }

  Widget _footerCircle(IconData icon, bool filled, bool isPortrait) {
    final size = isPortrait ? 40.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? Colors.white : Colors.white.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Icon(
        icon,
        color: filled ? AppColors.primary : Colors.white,
        size: isPortrait ? 20 : 24,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
