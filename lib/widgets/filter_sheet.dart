import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_colors.dart';

class FilterSheet extends StatefulWidget {
  final int? initialCategoryId;
  final Function(int? categoryId, double? minPrice, double? maxPrice) onApply;

  const FilterSheet({super.key, this.initialCategoryId, required this.onApply});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  int? _selectedCategoryId;
  double _minPrice = 0;
  double _maxPrice = 50000000;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1050),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Barang Lelang',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pilih kriteria utama agar daftar barang lebih mudah dibaca dan cepat ditemukan.',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              height: 1.45,
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
                        foregroundColor: AppColors.textSecondary,
                        fixedSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    color: AppColors.muted,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _panel(
                                  title: 'Kategori Barang',
                                  subtitle: 'Pilih satu kategori utama.',
                                  trailing: _selectedCategoryId == null
                                      ? 'Semua'
                                      : 'Dipilih',
                                  child: Consumer<AppProvider>(
                                    builder: (context, provider, child) => Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _buildCategoryChip('Semua', null),
                                        ...provider.categories.map(
                                          (c) => _buildCategoryChip(c.name, c.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _panel(
                                  title: 'Harga Dasar Lelang',
                                  subtitle: 'Gunakan batas minimum dan maksimum.',
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: _priceBox('Minimum', _minPrice)),
                                          const Padding(
                                            padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
                                            child: SizedBox(
                                              width: 32,
                                              child: Divider(color: AppColors.border),
                                            ),
                                          ),
                                          Expanded(child: _priceBox('Maksimum', _maxPrice)),
                                        ],
                                      ),
                                      RangeSlider(
                                        values: RangeValues(_minPrice, _maxPrice),
                                        min: 0,
                                        max: 50000000,
                                        divisions: 100,
                                        activeColor: AppColors.primary,
                                        inactiveColor: AppColors.secondary,
                                        onChanged: (values) => setState(() {
                                          _minPrice = values.start;
                                          _maxPrice = values.end;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _panel(
                                  title: 'Kondisi Barang',
                                  subtitle: 'Kondisi masih mengikuti data asli barang.',
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _FilterSelectableChip(
                                        label: 'Sangat Baik',
                                        isSelected: true,
                                        onTap: () {},
                                      ),
                                      _FilterSelectableChip(
                                        label: 'Baik',
                                        isSelected: true,
                                        onTap: () {},
                                      ),
                                      _FilterSelectableChip(
                                        label: 'Cukup Baik',
                                        isSelected: false,
                                        onTap: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: const Color(0xFFD7E7D8)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Ringkasan Filter',
                                        style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.successGreen,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      _summaryRow(
                                        'Kategori',
                                        _selectedCategoryId == null
                                            ? 'Semua'
                                            : '1 kategori',
                                      ),
                                      _summaryRow(
                                        'Harga',
                                        '${(_minPrice / 1000000).toStringAsFixed(1)} jt - ${(_maxPrice / 1000000).toStringAsFixed(1)} jt',
                                      ),
                                      _summaryRow('Kondisi', 'Semua kondisi'),
                                    ],
                                  ),
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    SizedBox(
                      width: 320,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _selectedCategoryId = null;
                          _minPrice = 0;
                          _maxPrice = 50000000;
                        }),
                        child: const Text(
                          'Reset Filter',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            widget.onApply(
                              _selectedCategoryId,
                              _minPrice,
                              _maxPrice,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Terapkan Filter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
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

  Widget _panel({
    required String title,
    required String subtitle,
    String? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.035),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailing,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, int? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return _FilterSelectableChip(
      label: label,
      isSelected: isSelected,
      onTap: () => setState(
        () => _selectedCategoryId = isSelected ? null : categoryId,
      ),
    );
  }

  Widget _priceBox(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            'Rp ${(value / 1000000).toStringAsFixed(1)} jt',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterSelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
