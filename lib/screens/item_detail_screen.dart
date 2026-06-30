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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background glows (Same style as home screen)
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isPortrait = constraints.maxWidth < 750;

                if (isPortrait) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildImageColumn(height: 460, isPortrait: isPortrait),
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.border),
                          const SizedBox(height: 12),
                          _buildDetails(
                            currencyFormatter,
                            isPortrait: isPortrait,
                            scrollable: false,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(40, 24, 40, 40),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Image + Specs (50% width)
                          Expanded(
                            flex: 50,
                            child: _buildImageColumn(isPortrait: isPortrait),
                          ),
                          const SizedBox(width: 32),
                          // Right side: Details & Simulation (50% width)
                          Expanded(
                            flex: 50,
                            child: _buildDetails(
                              currencyFormatter,
                              isPortrait: isPortrait,
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
    );
  }

  Widget _buildImageColumn({double? height, required bool isPortrait}) {
    return Container(
      height: height ?? double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F7),
        borderRadius: BorderRadius.circular(20),
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

          final mainImageWidget = photos.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 80,
                    color: AppColors.textMuted,
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: photos.length,
                  onPageChanged: (index) =>
                      setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) => Image.file(
                    File(photos[index].localPath),
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: AppColors.textMuted,
                    ),
                  ),
                );

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: mainImageWidget,
                    ),
                    // Floating Back Button
                    Positioned(
                      left: 8,
                      top: 8,
                      child: IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          foregroundColor: AppColors.textDark,
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    if (photos.length > 1) ...[
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: _imageArrow(
                          Icons.chevron_left,
                          photos.length,
                          -1,
                        ),
                      ),
                      Positioned(
                        right: 8,
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
              if (photos.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'FOTO ${_currentImageIndex + 1} DARI ${photos.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    photos.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == _currentImageIndex ? 16 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
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
              const SizedBox(height: 16),
              // Specs Grid directly below photo
              _buildSpecsGrid(isPortrait),
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
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          foregroundColor: AppColors.primary,
          fixedSize: const Size(40, 40),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSpecsGrid(bool isPortrait) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Adjust childAspectRatio dynamically based on available width
        final aspectRatio = width < 300 ? 2.3 : (width < 380 ? 2.6 : 3.0);
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _specCard(
              Icons.scale_outlined,
              'Berat',
              widget.item.weightGram > 0 ? '${widget.item.weightGram} gram' : '-',
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
        );
      },
    );
  }

  Widget _specCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 8),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
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

  Widget _buildDetails(
    NumberFormat currencyFormatter, {
    required bool isPortrait,
    bool scrollable = true,
  }) {
    final prices = _calculatePrices();
    final totalHarga = prices['totalHarga'] ?? 0;
    final appraisalValue = prices['appraisalValue'] ?? 0;
    final config = _financingConfig ?? <String, dynamic>{};

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              if (widget.item.description != null &&
                  widget.item.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.item.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Price display card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HARGA DASAR LELANG / TUNAI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Consumer<AppProvider>(
                builder: (context, provider, _) {
                  double displayPrice = widget.item.basePrice;
                  if (_isGoldItem(widget.item)) {
                    final hdlePrice = provider.goldPricePerGram.toDouble();
                    final karatVal = FinancingCalculator.parseKarat(
                      widget.item.karat,
                    );
                    final effectiveKarat = karatVal > 0 ? karatVal : 24.0;
                    displayPrice = FinancingCalculator.hitungHargaEmas(
                      hdlePrice: hdlePrice,
                      weightGram: widget.item.weightGram,
                      karatVal: effectiveKarat,
                    ).toDouble();
                  }
                  return Text(
                    currencyFormatter.format(displayPrice),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1.0,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Gold Reference Banner
        if (_isGoldItem(widget.item)) ...[
          Consumer<AppProvider>(
            builder: (context, provider, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Harga Acuan Emas Hari Ini: ${currencyFormatter.format(provider.goldPricePerGram)} / gram',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color.fromARGB(255, 33, 33, 33),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // SIMULATION PANEL (Rahn & Arrum Emas stacked cleanly inside a card)
        if (!_isFinancingLoading &&
            _financingConfig != null &&
            _financingTenors.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PEMBIAYAAN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 20),

                // Package mode toggle (if applicable)
                if (_packageItems.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Simulasi Paket Akad',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
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
                              () => setState(() => _simulatePackage = false),
                            ),
                            const SizedBox(width: 4),
                            _choiceTab(
                              'Paket Akad',
                              _simulatePackage,
                              () => setState(() => _simulatePackage = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                ],

                // 1. RAHN (GADAI EMAS) SECTION
                _buildRahnSection(
                  totalHarga,
                  appraisalValue,
                  config,
                  currencyFormatter,
                  isPortrait,
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),

                // 2. ARRUM EMAS SECTION
                _buildArrumEmasSection(
                  totalHarga,
                  appraisalValue,
                  config,
                  currencyFormatter,
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (scrollable) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }
    return content;
  }

  Widget _buildRahnSection(
    double totalHarga,
    double appraisalValue,
    Map<String, dynamic> config,
    NumberFormat currencyFormatter,
    bool isPortrait,
  ) {
    final result = FinancingCalculator.simulasiKca(
      hargaLelang: totalHarga.round(),
      appraisalValue: appraisalValue,
      config: config,
    );

    if (!result.eligible) {
      return _buildIneligiblePanel(result.message ?? '');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.handshake_outlined, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Text(
              'Rahn (Gadai Emas)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: isPortrait
              ? Column(
                  children: [
                    _rahnInfoColumn(
                      'Uang Muka (DP)',
                      currencyFormatter.format(result.uangMuka),
                      AppColors.accent,
                    ),
                    const Divider(height: 24),
                    _rahnInfoColumn(
                      'Jangka Waktu',
                      '${result.tempoKca} Bulan',
                      AppColors.textDark,
                    ),
                    const Divider(height: 24),
                    _rahnInfoColumn(
                      'Total Pelunasan',
                      currencyFormatter.format(result.totalPelunasanKca!),
                      AppColors.primary,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _rahnInfoColumn(
                        'Uang Muka (DP)',
                        currencyFormatter.format(result.uangMuka),
                        AppColors.accent,
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.border),
                    Expanded(
                      child: _rahnInfoColumn(
                        'Jangka Waktu',
                        '${result.tempoKca} Bulan',
                        AppColors.textDark,
                      ),
                    ),
                    Container(width: 1, height: 50, color: AppColors.border),
                    Expanded(
                      child: _rahnInfoColumn(
                        'Total Pelunasan',
                        currencyFormatter.format(result.totalPelunasanKca!),
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _rahnInfoColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrumEmasSection(
    double totalHarga,
    double appraisalValue,
    Map<String, dynamic> config,
    NumberFormat currencyFormatter,
  ) {
    final tempResult = FinancingCalculator.simulasiKrasida(
      hargaLelang: totalHarga.round(),
      appraisalValue: appraisalValue,
      config: config,
      tenors: _financingTenors,
      tenorMonths: _financingTenors.first['months'] as int,
    );

    if (!tempResult.eligible) {
      return _buildIneligiblePanel(tempResult.message ?? '');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.trending_up_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Arrum Emas (Cicilan)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.0),
              3: FlexColumnWidth(2.2),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.5),
                  ),
                ),
                children: [
                  _tableHeader('Tenor'),
                  _tableHeader('Uang DP'),
                  _tableHeader('Uang Pinjaman'),
                  _tableHeader('Angsuran / Bln'),
                ],
              ),
              ..._financingTenors.map((t) {
                final tenorMonths = t['months'] as int;
                final result = FinancingCalculator.simulasiKrasida(
                  hargaLelang: totalHarga.round(),
                  appraisalValue: appraisalValue,
                  config: config,
                  tenors: _financingTenors,
                  tenorMonths: tenorMonths,
                );

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  children: [
                    _tableCell('${result.tenor} Bln', isBold: true),
                    _tableCell(currencyFormatter.format(result.uangMuka)),
                    _tableCell(currencyFormatter.format(result.uangPinjaman)),
                    _tableCell(
                      currencyFormatter.format(result.angsuranPerBulan),
                      textColor: AppColors.primary,
                      isBold: true,
                    ),
                  ],
                );
              }),
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

  Widget _choiceTab(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
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

  Widget _buildIneligiblePanel(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'Skema Tidak Tersedia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 BARANG DALAM PAKET ${widget.item.creditNumber}:',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          ..._packageItems.map((item) {
            final isSelf = item.id == widget.item.id;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
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
                        fontSize: 12,
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
                        final effectiveKarat = karatVal > 0 ? karatVal : 24.0;
                        displayPrice = FinancingCalculator.hitungHargaEmas(
                          hdlePrice: hdlePrice,
                          weightGram: item.weightGram,
                          karatVal: effectiveKarat,
                        ).toDouble();
                      }
                      return Text(
                        currencyFormatter.format(displayPrice),
                        style: TextStyle(
                          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _tableCell(
    String text, {
    bool isSelected = false,
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: (isBold || isSelected)
                ? FontWeight.w900
                : FontWeight.w700,
            color:
                textColor ??
                (isSelected ? AppColors.accent : AppColors.textDark),
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
