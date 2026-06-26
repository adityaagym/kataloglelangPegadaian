import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/auction_item.dart';
import '../providers/app_provider.dart';
import '../models/item_photo.dart';
import '../services/financing_calculator.dart';
import '../utils/app_colors.dart';

class ItemDetailScreen extends StatefulWidget {
  final AuctionItem item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  Map<String, dynamic>? _financingConfig;
  List<Map<String, dynamic>> _financingTenors = [];
  bool _isFinancingLoading = true;
  int? _selectedTenorMonths;
  List<AuctionItem> _packageItems = [];
  bool _simulatePackage = false;
  SkemaType _selectedSkema = SkemaType.tunai;

  @override
  void initState() {
    super.initState();
    _loadFinancingData();
  }

  Future<void> _loadFinancingData() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final config = await provider.getActiveFinancingConfig();
    if (config != null && config['is_active'] == 1) {
      final tenors = await provider.getFinancingTenors(config['id'] as int);
      final activeTenors = tenors.where((t) => t['is_active'] == 1).toList();
      final creditNumber = widget.item.creditNumber;
      final packageItems = creditNumber != null && creditNumber.isNotEmpty
          ? await provider.getItemsByCreditNumber(creditNumber)
          : <AuctionItem>[];
      if (mounted) {
        setState(() {
          _financingConfig = config;
          _financingTenors = activeTenors;
          _selectedTenorMonths = activeTenors.isNotEmpty
              ? activeTenors.first['months'] as int
              : null;
          _packageItems = packageItems;
          _isFinancingLoading = false;
        });
      }
    } else if (mounted) {
      setState(() => _isFinancingLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildNav(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textDark.withValues(alpha: 0.08),
                          blurRadius: 38,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 54, child: _buildImageColumn()),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 46,
                          child: _buildDetails(currencyFormatter),
                        ),
                      ],
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

  Widget _buildNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 22, 32, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            _navChip(
              Icons.arrow_back,
              'Kembali ke Katalog',
              () => Navigator.pop(context),
              filled: true,
            ),
            const SizedBox(width: 12),
            _navTextChip(
              widget.item.categoryName ?? 'Kategori',
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            Consumer<AppProvider>(
              builder: (context, provider, _) => _navTextChip(
                'Cabang ${provider.branchName}',
                Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navChip(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: filled ? 0.20 : 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTextChip(String label, Color color) {
    final solid = color == AppColors.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: solid
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildImageColumn() {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: FutureBuilder<List<ItemPhoto>>(
        future: Provider.of<AppProvider>(
          context,
          listen: false,
        ).getItemPhotos(widget.item.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                size: 92,
                color: AppColors.textMuted,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: photos.length,
                        onPageChanged: (index) =>
                            setState(() => _currentImageIndex = index),
                        itemBuilder: (context, index) => Image.file(
                          File(photos[index].localPath),
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.error_outline,
                            size: 70,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    if (photos.length > 1) ...[
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: _imageArrow(
                          Icons.chevron_left,
                          photos.length,
                          -1,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: _imageArrow(
                          Icons.chevron_right,
                          photos.length,
                          1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Indicator below the image, styled clearly and boldly
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.20),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'FOTO ${_currentImageIndex + 1} DARI ${photos.length}',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (photos.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentImageIndex ? 24 : 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index == _currentImageIndex
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _imageArrow(IconData icon, int count, int delta) {
    return Center(
      child: IconButton.filled(
        onPressed: () {
          final next = (_currentImageIndex + delta).clamp(0, count - 1);
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        },
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          fixedSize: const Size(50, 50),
        ),
      ),
    );
  }

  Widget _buildDetails(NumberFormat currencyFormatter) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.categoryBadgeBg(widget.item.categoryName),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.item.categoryName ?? 'Lainnya',
                    style: TextStyle(
                      color: AppColors.categoryBadgeText(
                        widget.item.categoryName,
                      ),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.item.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.15,
                  ),
                ),
                if (widget.item.description != null &&
                    widget.item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            childAspectRatio: 2.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _specCard(
                Icons.scale_outlined,
                'Berat',
                widget.item.weightGram > 0
                    ? '${widget.item.weightGram} gram'
                    : '-',
              ),
              _specCard(
                Icons.diamond_outlined,
                'Karat',
                widget.item.karat?.isNotEmpty == true
                    ? widget.item.karat!
                    : '-',
              ),
              _specCard(
                Icons.verified_outlined,
                'Kondisi',
                widget.item.condition,
              ),
              _specCard(
                Icons.category_outlined,
                'Kategori',
                widget.item.categoryName ?? '-',
              ),
              _specCard(
                Icons.receipt_long_outlined,
                'No Akad',
                widget.item.creditNumber?.isNotEmpty == true
                    ? widget.item.creditNumber!
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF3D27A), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HARGA DASAR LELANG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8A5A00),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    currencyFormatter.format(widget.item.basePrice),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<AppProvider>(
                  builder: (context, provider, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.diamond_outlined,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Referensi emas: ${currencyFormatter.format(provider.goldPricePerGram)} / gram',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_isFinancingLoading &&
                    _financingConfig != null &&
                    _financingTenors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Cakupan simulasi (Barang ini / Paket akad)
                  if (_packageItems.length > 1) ...[
                    const Text(
                      'MODE SIMULASI:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _choiceChip(
                          'Barang ini',
                          !_simulatePackage,
                          () => setState(() => _simulatePackage = false),
                        ),
                        const SizedBox(width: 12),
                        _choiceChip(
                          'Paket Akad',
                          _simulatePackage,
                          () => setState(() => _simulatePackage = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Pilih Cara Pembelian
                  const Text(
                    'PILIH CARA PEMBELIAN:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _skemaCard(
                          'TUNAI',
                          'Bayar Penuh',
                          _selectedSkema == SkemaType.tunai,
                          () => setState(() => _selectedSkema = SkemaType.tunai),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _skemaCard(
                          'KCA',
                          'Tempo 4 Bln',
                          _selectedSkema == SkemaType.kca,
                          () => setState(() => _selectedSkema = SkemaType.kca),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _skemaCard(
                          'KRASIDA',
                          'Cicilan Tetap',
                          _selectedSkema == SkemaType.krasida,
                          () => setState(() => _selectedSkema = SkemaType.krasida),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Simulation Result Panel
                  _buildSimulationPanel(currencyFormatter),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _choiceChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _skemaCard(
    String title,
    String subtitle,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationPanel(NumberFormat currencyFormatter) {
    final config = _financingConfig!;
    final totalHarga = _simulatePackage
        ? _packageItems.fold<double>(0.0, (sum, item) => sum + item.basePrice)
        : widget.item.basePrice;

    if (_selectedSkema == SkemaType.tunai) {
      final result = FinancingCalculator.simulasiTunai(hargaLelang: totalHarga.round());
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.money_outlined, color: AppColors.successGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  ' PEMBELIAN TUNAI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Total Bayar',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormatter.format(result.hargaLelang),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _bulletPoint('Bayar penuh saat transaksi.'),
            _bulletPoint('Tidak ada bunga atau cicilan tambahan.'),
            if (_simulatePackage) ...[
              const SizedBox(height: 12),
              _buildPackageItemsList(currencyFormatter),
            ],
          ],
        ),
      );
    } else if (_selectedSkema == SkemaType.kca) {
      final result = FinancingCalculator.simulasiKca(
        hargaLelang: totalHarga.round(),
        config: config,
      );

      if (!result.eligible) {
        return _buildIneligiblePanel(result.message ?? '');
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card_outlined, color: AppColors.info, size: 24),
                SizedBox(width: 8),
                Text(
                  'KCA — Kredit Cicilan Angsuran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _breakdownRow('Harga Lelang', currencyFormatter.format(result.hargaLelang)),
            _breakdownRow('Uang Muka (19.2%)', currencyFormatter.format(result.uangMuka)),
            _breakdownRow('Uang Pinjaman', currencyFormatter.format(result.uangPinjaman)),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  'TEMPO: ${result.tempoKca} BULAN',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bulletPoint('Nasabah melunasi sisa pinjaman dalam 4 bulan.'),
            _bulletPoint('TIDAK ADA angsuran rutin bulanan.'),
            _bulletPoint('Bayar bebas kapan saja (bertahap/sekaligus).'),
            _bulletPoint('Bunga 1.25% flat per bulan atas sisa pinjaman.'),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _breakdownRow('Bunga Total (4 bln)', currencyFormatter.format(result.bungaTotalKca!)),
            _breakdownRow('Admin Fee', currencyFormatter.format(result.adminFee!)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL PELUNASAN',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  currencyFormatter.format(result.totalPelunasanKca!),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
            if (_simulatePackage) ...[
              const SizedBox(height: 16),
              _buildPackageItemsList(currencyFormatter),
            ],
          ],
        ),
      );
    } else {
      final tenorMonths = _selectedTenorMonths ?? _financingTenors.first['months'] as int;
      final result = FinancingCalculator.simulasiKrasida(
        hargaLelang: totalHarga.round(),
        config: config,
        tenors: _financingTenors,
        tenorMonths: tenorMonths,
      );

      if (!result.eligible) {
        return _buildIneligiblePanel(result.message ?? '');
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF3D27A), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_outlined, color: AppColors.accent, size: 24),
                SizedBox(width: 8),
                Text(
                  'KRASIDA — Kredit Gadai Angsuran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _breakdownRow('Harga Lelang', currencyFormatter.format(result.hargaLelang)),
            _breakdownRow('Uang Muka (18.5%)', currencyFormatter.format(result.uangMuka)),
            _breakdownRow('Uang Pinjaman', currencyFormatter.format(result.uangPinjaman)),
            const SizedBox(height: 16),
            
            const Text(
              'PILIH TENOR:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _financingTenors.map((t) {
                final months = t['months'] as int;
                final isSelected = months == tenorMonths;
                return ChoiceChip(
                  label: Text('$months bln'),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTenorMonths = months);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD95A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ANGSURAN TETAP PER BULAN',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8A5A00),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currencyFormatter.format(result.angsuranPerBulan!),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'selama $tenorMonths bulan (Bunga ${(result.bungaPerBulan! * 100).toStringAsFixed(2)}% flat/bulan)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A5A00),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _breakdownRow('Total Bayar', currencyFormatter.format(result.totalBayar!)),
            _breakdownRow('Bunga Total', currencyFormatter.format(result.bungaTotalKrasida!)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            const Text(
              ' PERBANDINGAN SEMUA TENOR:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.8),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  children: [
                    _tableHeader('Bln'),
                    _tableHeader('Angsuran'),
                    _tableHeader('Total Bayar'),
                    _tableHeader('Bunga'),
                  ],
                ),
                ...?result.perbandinganTenor?.map((t) {
                  return TableRow(
                    decoration: BoxDecoration(
                      color: t.isSelected ? AppColors.accent.withValues(alpha: 0.08) : null,
                      border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                    children: [
                      _tableCell('${t.tenor}', isSelected: t.isSelected),
                      _tableCell(currencyFormatter.format(t.angsuranPerBulan), isSelected: t.isSelected),
                      _tableCell(currencyFormatter.format(t.totalBayar), isSelected: t.isSelected),
                      _tableCell(currencyFormatter.format(t.bungaTotal), isSelected: t.isSelected),
                    ],
                  );
                }),
              ],
            ),
            if (_simulatePackage) ...[
              const SizedBox(height: 16),
              _buildPackageItemsList(currencyFormatter),
            ],
          ],
        ),
      );
    }
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIneligiblePanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
              SizedBox(width: 8),
              Text(
                'Skema Tidak Tersedia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageItemsList(NumberFormat currencyFormatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 BARANG DALAM PAKET ${widget.item.creditNumber}:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          ..._packageItems.map((item) {
            final isSelf = item.id == widget.item.id;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelf ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.name} (${item.karat ?? "-"}K, ${item.weightGram}g)${isSelf ? " (Barang ini)" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelf ? FontWeight.w800 : FontWeight.w600,
                        color: isSelf ? AppColors.primary : AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormatter.format(item.basePrice),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelf ? FontWeight.w800 : FontWeight.w700,
                      color: isSelf ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          color: isSelected ? AppColors.accent : AppColors.textDark,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
