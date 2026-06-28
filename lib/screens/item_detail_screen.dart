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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isPortrait =
                        constraints.maxWidth < constraints.maxHeight ||
                        constraints.maxWidth < 900;

                    if (isPortrait) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 38,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildImageColumn(height: 480),
                              const SizedBox(height: 28),
                              _buildDetails(
                                currencyFormatter,
                                scrollable: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(32, 10, 32, 32),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textDark.withValues(
                                  alpha: 0.08,
                                ),
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
                                child: _buildDetails(
                                  currencyFormatter,
                                  scrollable: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
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

  Widget _buildImageColumn({double? height}) {
    return Container(
      height: height ?? double.infinity,
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

  Map<String, double> _calculatePrices() {
    final config = _financingConfig;
    if (config == null) return {'totalHarga': 0.0, 'appraisalValue': 0.0};

    final provider = Provider.of<AppProvider>(context, listen: false);
    final hdlePrice = provider.goldPricePerGram.toDouble();

    double totalHarga = 0;
    double appraisalValue = 0;

    if (_simulatePackage) {
      for (final item in _packageItems) {
        if (_isGoldItem(item)) {
          double stlPrice = (config['stl_price'] as num?)?.toDouble() ?? 502894;
          final karatVal = FinancingCalculator.parseKarat(item.karat);
          final effectiveKarat = karatVal > 0 ? karatVal : 24.0;

          final recalculatedItemPrice = FinancingCalculator.hitungHargaEmas(
            hdlePrice: hdlePrice,
            weightGram: item.weightGram,
            karatVal: effectiveKarat,
          ).toDouble();
          totalHarga += recalculatedItemPrice;

          appraisalValue += FinancingCalculator.hitungNilaiTaksiran(
            stlPrice: stlPrice,
            weightGram: item.weightGram,
            karatVal: effectiveKarat,
          );
        } else {
          totalHarga += item.basePrice;
          appraisalValue += item.basePrice;
        }
      }
    } else {
      if (_isGoldItem(widget.item)) {
        double stlPrice = (config['stl_price'] as num?)?.toDouble() ?? 502894;
        final karatVal = FinancingCalculator.parseKarat(widget.item.karat);
        final effectiveKarat = karatVal > 0 ? karatVal : 24.0;

        totalHarga = FinancingCalculator.hitungHargaEmas(
          hdlePrice: hdlePrice,
          weightGram: widget.item.weightGram,
          karatVal: effectiveKarat,
        ).toDouble();

        appraisalValue = FinancingCalculator.hitungNilaiTaksiran(
          stlPrice: stlPrice,
          weightGram: widget.item.weightGram,
          karatVal: effectiveKarat,
        );
      } else {
        totalHarga = widget.item.basePrice;
        appraisalValue = widget.item.basePrice;
      }
    }
    return {'totalHarga': totalHarga, 'appraisalValue': appraisalValue};
  }

  void _showSimulationDialog(SkemaType skema) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currencyFormatter = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );
            final prices = _calculatePrices();
            final totalHarga = prices['totalHarga'] ?? 0;
            final appraisalValue = prices['appraisalValue'] ?? 0;
            final config = _financingConfig!;

            Widget contentWidget;
            String dialogTitle = '';
            Color headerColor = AppColors.primary;

            if (skema == SkemaType.tunai) {
              dialogTitle = 'Detail Pembelian Tunai';
              headerColor = AppColors.primary;
              final result = FinancingCalculator.simulasiTunai(
                hargaLelang: totalHarga.round(),
              );
              contentWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL BAYAR (TUNAI)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormatter.format(result.hargaLelang),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _bulletPoint(
                    'Bayar penuh saat transaksi langsung di cabang.',
                  ),
                  _bulletPoint(
                    'Bebas dari bunga, denda, atau cicilan tambahan.',
                  ),
                  if (_simulatePackage) ...[
                    const SizedBox(height: 16),
                    _buildPackageItemsList(currencyFormatter),
                  ],
                ],
              );
            } else if (skema == SkemaType.kca) {
              dialogTitle = 'Detail Simulasi KCA';
              headerColor = AppColors.info;
              final result = FinancingCalculator.simulasiKca(
                hargaLelang: totalHarga.round(),
                appraisalValue: appraisalValue,
                config: config,
              );

              if (!result.eligible) {
                contentWidget = _buildIneligiblePanel(result.message ?? '');
              } else {
                contentWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          _breakdownRow(
                            'Harga Lelang',
                            currencyFormatter.format(result.hargaLelang),
                          ),
                          const SizedBox(height: 6),
                          _breakdownRow(
                            'Uang Muka (DP)',
                            currencyFormatter.format(result.uangMuka),
                          ),
                          const SizedBox(height: 6),
                          _breakdownRow(
                            'Uang Pinjaman',
                            currencyFormatter.format(result.uangPinjaman),
                            valueColor: AppColors.info,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: AppColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'TEMPO: ${result.tempoKca} BULAN',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _bulletPoint(
                      'Nasabah melunasi sisa pinjaman dalam 4 bulan.',
                    ),
                    _bulletPoint('TIDAK ADA angsuran rutin bulanan.'),
                    _bulletPoint(
                      'Bayar bebas kapan saja (bertahap/sekaligus).',
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL PELUNASAN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(
                                  result.totalPelunasanKca!,
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_simulatePackage) ...[
                      const SizedBox(height: 16),
                      _buildPackageItemsList(currencyFormatter),
                    ],
                  ],
                );
              }
            } else {
              dialogTitle = 'Detail Simulasi KRASIDA';
              headerColor = AppColors.accent;
              final tenorMonths =
                  _selectedTenorMonths ??
                  _financingTenors.first['months'] as int;
              final result = FinancingCalculator.simulasiKrasida(
                hargaLelang: totalHarga.round(),
                appraisalValue: appraisalValue,
                config: config,
                tenors: _financingTenors,
                tenorMonths: tenorMonths,
              );

              if (!result.eligible) {
                contentWidget = _buildIneligiblePanel(result.message ?? '');
              } else {
                contentWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          _breakdownRow(
                            'Harga Lelang',
                            currencyFormatter.format(result.hargaLelang),
                          ),
                          const SizedBox(height: 6),
                          _breakdownRow(
                            'Uang Muka (DP)',
                            currencyFormatter.format(result.uangMuka),
                          ),
                          const SizedBox(height: 6),
                          _breakdownRow(
                            'Uang Pinjaman',
                            currencyFormatter.format(result.uangPinjaman),
                            valueColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'PILIH JANGKA WAKTU (TENOR):',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _financingTenors.map((t) {
                        final months = t['months'] as int;
                        final isSelected = months == tenorMonths;
                        return ChoiceChip(
                          label: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text('$months bulan'),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accent,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                _selectedTenorMonths = months;
                              });
                              setState(() {
                                _selectedTenorMonths = months;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFFD95A),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD95A,
                            ).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CICILAN TETAP BULANAN',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8A5A00),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(result.angsuranPerBulan!),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: AppColors.accent,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'selama $tenorMonths bulan berturut-turut',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8A5A00),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _breakdownRow(
                      'Total Pembayaran',
                      currencyFormatter.format(result.totalBayar!),
                      valueColor: AppColors.accent,
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 14),
                    const Text(
                      '📋 PERBANDINGAN SEMUA TENOR:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(2.4),
                        // 2: FlexColumnWidth(2.4),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                            ),
                          ),
                          children: [
                            _tableHeader('Tenor'),
                            _tableHeader('Angsuran / Bln'),
                            // _tableHeader('Total Bayar'),
                          ],
                        ),
                        ...?result.perbandinganTenor?.map((t) {
                          return TableRow(
                            decoration: BoxDecoration(
                              color: t.isSelected
                                  ? AppColors.accent.withValues(alpha: 0.08)
                                  : null,
                              border: const Border(
                                bottom: BorderSide(
                                  color: AppColors.border,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            children: [
                              _tableCell(
                                '${t.tenor} Bln',
                                isSelected: t.isSelected,
                              ),
                              _tableCell(
                                currencyFormatter.format(t.angsuranPerBulan),
                                isSelected: t.isSelected,
                              ),
                              // _tableCell(currencyFormatter.format(t.totalBayar), isSelected: t.isSelected),
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
                );
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            skema == SkemaType.tunai
                                ? Icons.payments_outlined
                                : skema == SkemaType.kca
                                ? Icons.credit_card_outlined
                                : Icons.bar_chart_outlined,
                            color: headerColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            dialogTitle,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(child: contentWidget),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pembelianButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildDetails(
    NumberFormat currencyFormatter, {
    bool scrollable = true,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          childAspectRatio: 2.7,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
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
              widget.item.karat?.isNotEmpty == true ? widget.item.karat! : '-',
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
        const SizedBox(height: 16),
        // UNIFIED HARGA & TRANSAKSI CARD (Sleek, Clean & Fresh)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header & Badge
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HARGA DASAR LELANG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (_isGoldItem(widget.item))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.workspace_premium_outlined,
                                  color: AppColors.accent,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'EMAS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Consumer<AppProvider>(
                        builder: (context, provider, _) {
                          double displayPrice = widget.item.basePrice;
                          if (_isGoldItem(widget.item)) {
                            final hdlePrice = provider.goldPricePerGram
                                .toDouble();
                            final karatVal = FinancingCalculator.parseKarat(
                              widget.item.karat,
                            );
                            final rawItemPrice =
                                hdlePrice *
                                widget.item.weightGram *
                                (karatVal / 24.0);
                            displayPrice = FinancingCalculator.roundUp(
                              rawItemPrice,
                              10000,
                            ).toDouble();
                          }
                          return Text(
                            currencyFormatter.format(displayPrice),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -1.0,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Gold Reference Banner (inside the card)
              if (_isGoldItem(widget.item)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<AppProvider>(
                    builder: (context, provider, _) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: AppColors.accent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Harga Acuan Emas Hari Ini',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${currencyFormatter.format(provider.goldPricePerGram)} / gram',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Divider separating Price and Action Panel
              if (!_isFinancingLoading &&
                  _financingConfig != null &&
                  _financingTenors.isNotEmpty) ...[
                const Divider(height: 1, color: AppColors.border),

                // Bottom section (Mode & Buttons)
                Container(
                  padding: const EdgeInsets.all(20),
                  color: AppColors.primary.withValues(alpha: 0.02),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode selection (Package vs Single)
                      if (_packageItems.length > 1) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MODE SIMULASI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Row(
                                children: [
                                  _choiceTab(
                                    'Barang Ini',
                                    !_simulatePackage,
                                    () => setState(
                                      () => _simulatePackage = false,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _choiceTab(
                                    'Paket Akad',
                                    _simulatePackage,
                                    () =>
                                        setState(() => _simulatePackage = true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'PILIH CARA PEMBELIAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _pembelianButton(
                              'TUNAI',
                              Icons.payments_outlined,
                              AppColors.primary,
                              () => _showSimulationDialog(SkemaType.tunai),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pembelianButton(
                              'KCA',
                              Icons.credit_card_outlined,
                              AppColors.info,
                              () => _showSimulationDialog(SkemaType.kca),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _pembelianButton(
                              'KRASIDA',
                              Icons.bar_chart_outlined,
                              AppColors.accent,
                              () => _showSimulationDialog(SkemaType.krasida),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (scrollable) {
      return SingleChildScrollView(child: content);
    }
    return content;
  }

  Widget _specCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceTab(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  bool _isGoldItem(AuctionItem item) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      final category = provider.categories.firstWhere(
        (c) => c.id == item.categoryId,
      );
      final name = category.name.toLowerCase();
      return name.contains('emas') || name.contains('logam mulia');
    } catch (_) {
      if (item.categoryName != null) {
        final name = item.categoryName!.toLowerCase();
        return name.contains('emas') || name.contains('logam mulia');
      }
      return false;
    }
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor ?? AppColors.textDark,
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
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 24,
              ),
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
                      color: isSelf
                          ? AppColors.primary
                          : AppColors.textSecondary,
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
                  Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      double displayPrice = item.basePrice;
                      if (_isGoldItem(item)) {
                        final hdlePrice = provider.goldPricePerGram.toDouble();
                        final karatVal = FinancingCalculator.parseKarat(
                          item.karat,
                        );
                        final rawItemPrice =
                            hdlePrice * item.weightGram * (karatVal / 24.0);
                        displayPrice = FinancingCalculator.roundUp(
                          rawItemPrice,
                          10000,
                        ).toDouble();
                      }
                      return Text(
                        currencyFormatter.format(displayPrice),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelf
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: isSelf
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      );
                    },
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? AppColors.accent : AppColors.textDark,
          ),
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
