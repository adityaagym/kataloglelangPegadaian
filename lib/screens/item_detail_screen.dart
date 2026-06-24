import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/auction_item.dart';
import '../providers/app_provider.dart';
import '../models/item_photo.dart';
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
  int? _selectedDpPercent;
  int? _selectedTenorMonths;
  List<int> _dpOptions = [];

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
      final dpOpts = (config['dp_options'] as String)
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((d) => d > 0)
          .toList();

      if (mounted) {
        setState(() {
          _financingConfig = config;
          _financingTenors = activeTenors;
          _dpOptions = dpOpts;
          _selectedDpPercent = dpOpts.isNotEmpty ? dpOpts.first : null;
          _selectedTenorMonths = activeTenors.isNotEmpty
              ? activeTenors.first['months'] as int
              : null;
          _isFinancingLoading = false;
        });
      }
    } else if (mounted) {
      setState(() => _isFinancingLoading = false);
    }
  }

  double _calculateInstallment({
    required double basePrice,
    required int dpPercent,
    required double munahRate,
    required double adminFeeFlat,
    required double adminFeePercent,
    required int tenorMonths,
    required double otherFee,
  }) {
    final dpAmount = basePrice * (dpPercent / 100.0);
    final plafond = basePrice - dpAmount;
    final adminFee = adminFeeFlat + (basePrice * (adminFeePercent / 100.0));
    final munahPerMonth = plafond * (munahRate / 100.0) * 3;
    return (plafond / tenorMonths) +
        munahPerMonth +
        (otherFee / tenorMonths) +
        (adminFee / tenorMonths);
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
                        child: _imageArrow(Icons.chevron_left, photos.length, -1),
                      ),
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: _imageArrow(Icons.chevron_right, photos.length, 1),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showFinancingDialog(currencyFormatter),
                      icon: const Icon(Icons.calculate_outlined, size: 20),
                      label: const Text(
                        'Lihat Simulasi Pembiayaan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
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

  void _showFinancingDialog(NumberFormat currencyFormatter) {
    showDialog(
      context: context,
      barrierColor: AppColors.muted.withValues(alpha: 0.88),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final config = _financingConfig!;
          final basePrice = widget.item.basePrice;
          final dpPercent = _selectedDpPercent ?? _dpOptions.first;
          final tenorMonths =
              _selectedTenorMonths ?? _financingTenors.first['months'] as int;
          final tenor = _financingTenors.firstWhere(
            (t) => t['months'] == tenorMonths,
            orElse: () => _financingTenors.first,
          );
          final otherFee = (tenor['other_fee'] as num?)?.toDouble() ?? 0;
          final munahRate = (config['munah_rate'] as num).toDouble();
          final adminFlat = (config['admin_fee_flat'] as num).toDouble();
          final adminPercent = (config['admin_fee_percent'] as num).toDouble();
          final dpAmount = basePrice * (dpPercent / 100);
          final plafond = basePrice - dpAmount;
          final installment = _calculateInstallment(
            basePrice: basePrice,
            dpPercent: dpPercent,
            munahRate: munahRate,
            adminFeeFlat: adminFlat,
            adminFeePercent: adminPercent,
            tenorMonths: tenorMonths,
            otherFee: otherFee,
          );

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 48,
              vertical: 32,
            ),
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Material(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Simulasi Pembiayaan Syariah',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Estimasi mengikuti parameter pembiayaan aktif di database lokal.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.goldBg,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFF3D27A),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estimasi angsuran',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8A5A00),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currencyFormatter.format(
                                        installment.round(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const Text(
                                      '/ bulan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF8A5A00),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    _breakdown(
                                      'Harga barang',
                                      currencyFormatter.format(basePrice),
                                    ),
                                    _breakdown(
                                      'DP $dpPercent%',
                                      currencyFormatter.format(dpAmount),
                                    ),
                                    _breakdown(
                                      'Plafond',
                                      currencyFormatter.format(plafond),
                                    ),
                                    _breakdown(
                                      "Mu'nah / 10 hari",
                                      '${munahRate.toStringAsFixed(2)}%',
                                    ),
                                    _breakdown('Tenor', '$tenorMonths bulan'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _selectorPanel(
                                    title: 'Down Payment',
                                    children: _dpOptions.map((dp) {
                                      final selected = dp == dpPercent;
                                      return _choice('$dp%', selected, () {
                                        setState(() => _selectedDpPercent = dp);
                                        setDialogState(() {});
                                      });
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 18),
                                  _selectorPanel(
                                    title: 'Tenor',
                                    children: _financingTenors.map((t) {
                                      final months = t['months'] as int;
                                      return _choice(
                                        '$months bulan',
                                        months == tenorMonths,
                                        () {
                                          setState(
                                            () => _selectedTenorMonths = months,
                                          );
                                          setDialogState(() {});
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Estimasi angsuran dapat berubah sesuai kebijakan outlet dan hasil verifikasi barang.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.85,
                                      ),
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
          );
        },
      ),
    );
  }

  Widget _selectorPanel({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: children),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _breakdown(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A5A00),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
