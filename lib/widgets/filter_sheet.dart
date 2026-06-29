import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  late TextEditingController _minController;
  late TextEditingController _maxController;
  final FocusNode _minFocus = FocusNode();
  final FocusNode _maxFocus = FocusNode();

  final NumberFormat _numberFormatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _minController = TextEditingController(
      text: _minPrice == 0 ? '0' : _numberFormatter.format(_minPrice.toInt()),
    );
    _maxController = TextEditingController(
      text: _numberFormatter.format(_maxPrice.toInt()),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocus.dispose();
    _maxFocus.dispose();
    super.dispose();
  }

  /// Parses a user-entered string back into a raw double.
  double _parsePrice(String text) {
    if (text.isEmpty) return 0;
    // Remove all non-digit characters (dots, spaces, etc.)
    final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(digitsOnly) ?? 0;
  }

  /// Formats a raw double price into a human-readable short label.
  /// Uses "jt" for millions, "M" for miliar (billions).
  String _formatPriceLabel(double value) {
    if (value >= 1000000000) {
      final v = value / 1000000000;
      // Show decimal only when needed
      return v == v.roundToDouble()
          ? '${v.toInt()} M'
          : '${v.toStringAsFixed(1)} M';
    } else if (value >= 1000000) {
      final v = value / 1000000;
      return v == v.roundToDouble()
          ? '${v.toInt()} jt'
          : '${v.toStringAsFixed(1)} jt';
    } else if (value >= 1000) {
      final v = value / 1000;
      return v == v.roundToDouble()
          ? '${v.toInt()} rb'
          : '${v.toStringAsFixed(1)} rb';
    } else {
      return value.toInt().toString();
    }
  }

  /// Called when focus leaves a price field – re-formats the text.
  void _onPriceFieldSubmitted(TextEditingController controller, bool isMin) {
    final value = _parsePrice(controller.text);
    setState(() {
      if (isMin) {
        _minPrice = value;
      } else {
        _maxPrice = value;
      }
      controller.text = value == 0 ? '0' : _numberFormatter.format(value.toInt());
    });
  }

  void _resetFilter() {
    setState(() {
      _selectedCategoryId = null;
      _minPrice = 0;
      _maxPrice = 5000000000;
      _minController.text = '0';
      _maxController.text = _numberFormatter.format(5000000000);
    });
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
                                  subtitle: 'Masukkan batas minimum dan maksimum secara manual.',
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _priceInputBox(
                                              'Minimum',
                                              _minController,
                                              _minFocus,
                                              true,
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.fromLTRB(16, 28, 16, 0),
                                            child: SizedBox(
                                              width: 32,
                                              child: Divider(color: AppColors.border),
                                            ),
                                          ),
                                          Expanded(
                                            child: _priceInputBox(
                                              'Maksimum',
                                              _maxController,
                                              _maxFocus,
                                              false,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              size: 18,
                                              color: AppColors.successGreen,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Masukkan angka dalam Rupiah penuh. Contoh: 500000 = Rp 500 rb, 5000000 = Rp 5 jt, 1000000000 = Rp 1 M.',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.successGreen.withValues(
                                                    alpha: 0.85,
                                                  ),
                                                  height: 1.4,
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Container(
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
                                'Rp ${_formatPriceLabel(_minPrice)} - Rp ${_formatPriceLabel(_maxPrice)}',
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
                        onPressed: _resetFilter,
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
                            // Ensure we capture latest typed values
                            _minPrice = _parsePrice(_minController.text);
                            _maxPrice = _parsePrice(_maxController.text);
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

  /// Builds an editable price input box with auto-formatting.
  Widget _priceInputBox(
    String label,
    TextEditingController controller,
    FocusNode focusNode,
    bool isMin,
  ) {
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
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ThousandSeparatorFormatter(),
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: AppColors.muted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(22),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            final parsed = _parsePrice(value);
            setState(() {
              if (isMin) {
                _minPrice = parsed;
              } else {
                _maxPrice = parsed;
              }
            });
          },
          onEditingComplete: () {
            _onPriceFieldSubmitted(controller, isMin);
            focusNode.unfocus();
          },
          onTapOutside: (_) {
            if (focusNode.hasFocus) {
              _onPriceFieldSubmitted(controller, isMin);
              focusNode.unfocus();
            }
          },
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

/// Custom TextInputFormatter that adds thousand separators (dots) as user types.
class _ThousandSeparatorFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###', 'id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return newValue;

    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
