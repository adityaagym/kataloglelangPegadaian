import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
  int _currentImageIndex = 0;

  Map<String, dynamic>? _financingConfig;
  List<Map<String, dynamic>> _financingTenors = [];
  bool _isFinancingLoading = true;
  int? _selectedDpPercent; // e.g. 15, 25, 35, 50
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
          if (dpOpts.isNotEmpty) {
            _selectedDpPercent = dpOpts.first;
          }
          _isFinancingLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isFinancingLoading = false;
        });
      }
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

    // Mu'nah fee per month (munahRate is per 10 days, so 3 times per month)
    final munahPerMonth = plafond * (munahRate / 100.0) * 3;

    // Monthly installment
    final monthlyInstallment = (plafond / tenorMonths) + munahPerMonth + (otherFee / tenorMonths);
    return monthlyInstallment;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Breadcrumb header with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    // Back button chip
                    _buildBreadcrumbChip(
                      icon: Icons.arrow_back,
                      label: 'Kembali ke Katalog',
                      onTap: () => Navigator.pop(context),
                      isBack: true,
                    ),
                    const SizedBox(width: 12),
                    // Category chip
                    _buildBreadcrumbChip(
                      label: widget.item.categoryName ?? 'Kategori',
                    ),
                    const SizedBox(width: 12),
                    // Branch chip
                    Consumer<AppProvider>(
                      builder: (context, provider, _) {
                        return _buildBreadcrumbChip(
                          label: 'Cabang ${provider.branchName}',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Row(
                children: [
                  // Left Column (Carousel)
                  Expanded(
                    flex: 55,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: FutureBuilder<List<ItemPhoto>>(
                          future: Provider.of<AppProvider>(context, listen: false).getItemPhotos(widget.item.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                            }

                            final photos = snapshot.data ?? [];

                            if (photos.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.image_not_supported_outlined, size: 80, color: AppColors.textMuted.withValues(alpha: 0.4)),
                                    const SizedBox(height: 12),
                                    const Text('Tidak ada foto', style: TextStyle(color: AppColors.textMuted)),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      height: double.infinity,
                                      viewportFraction: 1.0,
                                      enableInfiniteScroll: photos.length > 1,
                                      onPageChanged: (index, reason) {
                                        setState(() {
                                          _currentImageIndex = index;
                                        });
                                      },
                                    ),
                                    items: photos.map((photo) {
                                      return Builder(
                                        builder: (BuildContext context) {
                                          return Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Image.file(
                                              File(photo.localPath),
                                              fit: BoxFit.contain,
                                              errorBuilder: (ctx, err, stack) => const Icon(Icons.error_outline, size: 60, color: AppColors.textMuted),
                                            ),
                                          );
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                                if (photos.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: photos.asMap().entries.map((entry) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: _currentImageIndex == entry.key ? 24 : 10,
                                          height: 10,
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5),
                                            color: _currentImageIndex == entry.key
                                                ? AppColors.primary
                                                : AppColors.primary.withValues(alpha: 0.2),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Right Column (Details)
                  Expanded(
                    flex: 45,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 32, 48, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.item.categoryName ?? 'Lainnya',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Item name
                          Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Specs
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.accentLighter,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                if (widget.item.weightGram > 0)
                                  _buildSpecRow(Icons.fitness_center, 'Berat', '${widget.item.weightGram} gram'),
                                if (widget.item.karat != null && widget.item.karat!.isNotEmpty)
                                  _buildSpecRow(Icons.diamond_outlined, 'Karat', widget.item.karat!),
                                _buildSpecRow(Icons.verified_outlined, 'Kondisi', widget.item.condition),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Price
                          const Text(
                            'Harga Dasar Lelang',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormatter.format(widget.item.basePrice),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),

                          if (widget.item.description != null && widget.item.description!.isNotEmpty) ...[
                            const SizedBox(height: 28),
                            const Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.item.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],

                          // Financing Estimate Section
                          _buildFinancingSection(currencyFormatter),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancingSection(NumberFormat currencyFormatter) {
    if (_isFinancingLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_financingConfig == null || _financingTenors.isEmpty) {
      return const SizedBox.shrink();
    }

    final double basePrice = widget.item.basePrice;
    final double munahRate = (_financingConfig!['munah_rate'] as num).toDouble();
    final double adminFeeFlat = (_financingConfig!['admin_fee_flat'] as num).toDouble();
    final double adminFeePercent = (_financingConfig!['admin_fee_percent'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 36),
        const Divider(),
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.calculate_outlined, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Estimasi Pembiayaan Syariah',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DP selector chips
        const Text(
          'Pilihan Down Payment (DP):',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _dpOptions.map((dp) {
            final isSelected = _selectedDpPercent == dp;
            final dpVal = basePrice * (dp / 100.0);
            return ChoiceChip(
              label: Text('$dp% (${currencyFormatter.format(dpVal)})'),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              backgroundColor: AppColors.background,
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedDpPercent = dp);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Table / list of installments
        if (_selectedDpPercent != null) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Tenor', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary))),
                      Expanded(child: Text('Plafond', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary))),
                      Expanded(child: Text('Angsuran/Bulan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary))),
                    ],
                  ),
                ),

                // Rows
                ...List.generate(_financingTenors.length, (index) {
                  final tenor = _financingTenors[index];
                  final months = tenor['months'] as int;
                  final otherFee = (tenor['other_fee'] as num?)?.toDouble() ?? 0.0;

                  final dpAmount = basePrice * (_selectedDpPercent! / 100.0);
                  final plafond = basePrice - dpAmount;

                  final installment = _calculateInstallment(
                    basePrice: basePrice,
                    dpPercent: _selectedDpPercent!,
                    munahRate: munahRate,
                    adminFeeFlat: adminFeeFlat,
                    adminFeePercent: adminFeePercent,
                    tenorMonths: months,
                    otherFee: otherFee,
                  );

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: index < _financingTenors.length - 1
                          ? const Border(bottom: BorderSide(color: AppColors.cardBorder))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$months Bulan',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currencyFormatter.format(plafond),
                            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currencyFormatter.format(installment.round()),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '* Estimasi angsuran di atas sudah mencakup biaya administrasi & Mu\'nah bulanan.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbChip({IconData? icon, required String label, VoidCallback? onTap, bool isBack = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isBack ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
