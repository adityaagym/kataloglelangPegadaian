import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../models/auction_item.dart';
import '../../models/imported_auction_item.dart';
import '../../services/financing_calculator.dart';

class ImportConfirmationScreen extends StatelessWidget {
  const ImportConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB), // Clean, corporate light gray background
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Impor Massal',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE5E7EB), height: 1),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final items = provider.importDraftItems;
          final validSelectedCount = provider.selectedImportCount;
          final totalCount = items.length;
          final errorCount = items.where((i) => !i.isValid).length;

          final totalValue = items
              .where((i) => i.isSelected && i.isValid)
              .fold<double>(0, (sum, i) => sum + i.item.basePrice);

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada data untuk dikonfirmasi',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  children: [
                    // 1. Summary Cards
                    _buildSummaryRow(totalCount, validSelectedCount, errorCount, totalValue),
                    const SizedBox(height: 28),

                    // 2. List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Item Impor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _toggleAll(provider),
                          icon: const Icon(Icons.checklist, size: 22, color: Color(0xFF16A34A)),
                          label: const Text(
                            'Pilih Semua',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                              fontSize: 16,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3. Item Cards List
                    ...items.map((imported) => _buildItemCard(
                          context,
                          provider,
                          imported,
                          currencyFormatter,
                        )),
                  ],
                ),
              ),

              // 4. Floating Footer Action Bar
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8), // Corporate, clean corners
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {
                            provider.clearImportDraft();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A), // Clean green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: validSelectedCount > 0
                              ? () => _proceedToPhotos(context, provider)
                              : null,
                          icon: const Text(
                            'Lanjut Input Foto',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          label: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(int total, int valid, int error, double value) {
    return Row(
      children: [
        _buildSummaryCard('Total Baris', total.toString(), Icons.list_alt, const Color(0xFF374151)),
        const SizedBox(width: 12),
        _buildSummaryCard('Siap Diimpor', valid.toString(), Icons.check_circle, const Color(0xFF16A34A)),
        const SizedBox(width: 12),
        _buildSummaryCard('Butuh Perbaikan', error.toString(), Icons.warning, const Color(0xFFDC2626)),
        const SizedBox(width: 12),
        _buildSummaryCard('Nilai Transaksi', _formatCompactCurrency(value), Icons.payments_outlined, const Color(0xFF1F2937)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8), // Clean corporate corners
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    AppProvider provider,
    ImportedAuctionItem imported,
    NumberFormat currencyFormatter,
  ) {
    final item = imported.item;
    final hasErrors = !imported.isValid;
    final categoryName = item.categoryName ?? 'Lainnya';

    final cardBorderColor = hasErrors ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB);
    final cardBgColor = hasErrors ? const Color(0xFFFEF2F2) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(6), // Sharp, corporate corners
        border: Border.all(
          color: cardBorderColor,
          width: hasErrors ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _showEditDialog(context, provider, imported),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Clean checkbox
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: imported.isSelected && imported.isValid,
                      onChanged: imported.isValid
                          ? (_) => provider.toggleItemSelection(imported.rowIndex)
                          : null,
                      activeColor: const Color(0xFF16A34A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. Left Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris Atas: [Badge Kategori]
                        _buildFlatCategoryBadge(categoryName),
                        const SizedBox(height: 6),

                        // Baris Tengah: [Nama Item]
                        Text(
                          item.name.isEmpty ? '(Nama Kosong)' : item.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Baris Bawah: Badges (No Akad, Berat, Karat)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.creditNumber?.isNotEmpty == true)
                              _buildBlueCreditNumberBadge(item.creditNumber!),
                            if (item.weightGram > 0)
                              _buildWeightBadge(item.weightGram),
                            if (item.karat != null && item.karat!.isNotEmpty)
                              _buildKaratBadge(item.karat!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 3. Right Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            currencyFormatter.format(item.basePrice),
                            style: const TextStyle(
                              fontSize: 22, // Large and readable
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 24, color: Color(0xFF9CA3AF)),
                ],
              ),

              // Description / Informasi (Span full width if present)
              if (item.description != null && item.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error banner (Span full width if present)
              if (hasErrors) ...[
                const SizedBox(height: 8),
                _buildErrorBanner(imported.validationErrors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlatCategoryBadge(String categoryName) {
    final name = categoryName.toLowerCase();

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (name.contains('perhiasan') || (name.contains('emas') && !name.contains('logam'))) {
      // Perhiasan Emas - amber
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      borderColor = const Color(0xFFFDE68A);
    } else if (name.contains('logam')) {
      // Logam Mulia - slate
      bgColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF475569);
      borderColor = const Color(0xFFCBD5E1);
    } else if (name.contains('elektronik')) {
      // Elektronik - indigo
      bgColor = const Color(0xFFEDE9FE);
      textColor = const Color(0xFF4338CA);
      borderColor = const Color(0xFFC4B5FD);
    } else if (name.contains('kendaraan')) {
      // Kendaraan - dark blue
      bgColor = const Color(0xFFDBEAFE);
      textColor = const Color(0xFF1E3A8A);
      borderColor = const Color(0xFFBFDBFE);
    } else {
      // Default - neutral grey
      bgColor = const Color(0xFFF3F4F6);
      textColor = const Color(0xFF374151);
      borderColor = const Color(0xFFE5E7EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        categoryName.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBlueCreditNumberBadge(String creditNumber) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Light blue background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
      ),
      child: Text(
        creditNumber,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1E40AF), // Dark blue text
          fontFamily: 'JetBrains Mono',
        ),
      ),
    );
  }

  Widget _buildWeightBadge(double weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light green background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.scale_outlined, size: 16, color: Color(0xFF166534)),
          const SizedBox(width: 4),
          Text(
            'Berat: ${weight}g',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaratBadge(String karat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Light orange background
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_outlined, size: 16, color: Color(0xFFC2410C)),
          const SizedBox(width: 4),
          Text(
            'Karat: $karat',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC2410C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(List<String> errors) {
    final errorText = errors.isNotEmpty ? errors.first : 'Data tidak valid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    AppProvider provider,
    ImportedAuctionItem imported,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _EditItemDialog(
          imported: imported,
          provider: provider,
        );
      },
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1e9) {
      return 'Rp ${(value / 1e9).toStringAsFixed(2)}M';
    } else if (value >= 1e6) {
      return 'Rp ${(value / 1e6).toStringAsFixed(1)}Jt';
    }
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  void _toggleAll(AppProvider provider) {
    final allValidSelected = provider.importDraftItems
        .where((i) => i.isValid)
        .every((i) => i.isSelected);

    final newItems = provider.importDraftItems.map((imported) {
      if (!imported.isValid) return imported;
      return imported.copyWith(isSelected: !allValidSelected);
    }).toList();

    provider.setImportDraft(newItems);
  }

  Future<void> _proceedToPhotos(
    BuildContext context,
    AppProvider provider,
  ) async {
    final savedIds = await provider.saveImportedItems();
    if (savedIds.isEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item yang tersimpan')),
      );
      return;
    }

    provider.startPhotoImport(savedIds);
  }
}

class _EditItemDialog extends StatefulWidget {
  final ImportedAuctionItem imported;
  final AppProvider provider;

  const _EditItemDialog({
    required this.imported,
    required this.provider,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _creditNumberController;
  late TextEditingController _nameController;
  late TextEditingController _weightController;
  late TextEditingController _karatController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  int? _selectedCategoryId;
  bool _isGold = false;

  @override
  void initState() {
    super.initState();
    final item = widget.imported.item;
    _creditNumberController = TextEditingController(text: item.creditNumber ?? '');
    _nameController = TextEditingController(text: item.name);
    _weightController = TextEditingController(
      text: item.weightGram > 0 ? item.weightGram.toString() : '',
    );
    _karatController = TextEditingController(text: item.karat ?? '');
    _priceController = TextEditingController(
      text: item.basePrice > 0
          ? NumberFormat.decimalPattern('id').format(item.basePrice.round())
          : '',
    );
    _descriptionController = TextEditingController(text: item.description ?? '');
    _selectedCategoryId = item.categoryId != 0 ? item.categoryId : null;

    final categoryName = item.categoryName ?? '';
    _isGold = categoryName.toLowerCase().contains('emas') ||
        categoryName.toLowerCase().contains('logam mulia');
  }

  @override
  void dispose() {
    _creditNumberController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    _karatController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(int? newId) {
    if (newId == null) return;
    setState(() {
      _selectedCategoryId = newId;
      try {
        final category = widget.provider.categories.firstWhere((c) => c.id == newId);
        final name = category.name.toLowerCase();
        _isGold = name.contains('emas') || name.contains('logam mulia');
      } catch (_) {
        _isGold = false;
      }
    });

    if (_isGold) {
      _recalculateGoldPrice();
    }
  }

  void _recalculateGoldPrice() {
    final weight = double.tryParse(_weightCtrlText) ?? 0.0;
    final karatVal = FinancingCalculator.parseKarat(_karatController.text.trim());
    final effectiveKarat = karatVal > 0 ? karatVal : 24.0;

    final basePrice = FinancingCalculator.hitungHargaEmas(
      hdlePrice: widget.provider.goldPricePerGram,
      weightGram: weight,
      karatVal: effectiveKarat,
    ).toDouble();

    if (basePrice > 0) {
      _priceController.text = NumberFormat.decimalPattern('id').format(basePrice.round());
    } else {
      _priceController.text = '';
    }
  }

  String get _weightCtrlText => _weightController.text.replaceAll(',', '.');

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightCtrlText) ?? 0.0;

    double basePrice;
    if (_isGold) {
      final karatVal = FinancingCalculator.parseKarat(_karatController.text.trim());
      final effectiveKarat = karatVal > 0 ? karatVal : 24.0;
      basePrice = FinancingCalculator.hitungHargaEmas(
        hdlePrice: widget.provider.goldPricePerGram,
        weightGram: weight,
        karatVal: effectiveKarat,
      ).toDouble();
    } else {
      final priceText = _priceController.text.replaceAll('.', '').replaceAll(',', '');
      basePrice = double.tryParse(priceText) ?? 0.0;
    }

    String? categoryName;
    try {
      categoryName = widget.provider.categories
          .firstWhere((c) => c.id == _selectedCategoryId)
          .name;
    } catch (_) {}

    final updatedItem = AuctionItem(
      id: widget.imported.item.id,
      creditNumber: _creditNumberController.text.trim().isEmpty
          ? null
          : _creditNumberController.text.trim(),
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId ?? 0,
      weightGram: weight,
      karat: _isGold ? (_karatController.text.trim().isEmpty ? null : _karatController.text.trim()) : null,
      basePrice: basePrice,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: widget.imported.item.isActive,
      createdAt: widget.imported.item.createdAt ?? DateTime.now().toIso8601String(),
      categoryName: categoryName,
    );

    widget.provider.updateAndRevalidateImportedItem(widget.imported.rowIndex, updatedItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Solid White
      surfaceTintColor: Colors.transparent, // No tint overlay
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Crisp corners
      elevation: 4,
      child: Container(
        width: 600, // Clean, defined width
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DETAIL & EDIT ITEM',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Baris Excel ${widget.imported.rowIndex}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 22, color: Color(0xFF4B5563)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(color: const Color(0xFFE5E7EB), height: 1), // Crisp divider
                const SizedBox(height: 20),

                // Form fields
                _buildLabel('NOMOR AKAD (OPSIONAL)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _creditNumberController,
                  decoration: _inputDecoration(Icons.tag, 'Masukkan nomor akad'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 16),

                _buildLabel('NAMA BARANG'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(Icons.label_outline, 'Masukkan nama barang'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('KATEGORI'),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: _inputDecoration(Icons.category_outlined, 'Pilih kategori'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  items: widget.provider.categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: _onCategoryChanged,
                  validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel('BERAT (GRAM)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _weightController,
                  decoration: _inputDecoration(Icons.scale_outlined, 'Masukkan berat'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  validator: (v) {
                    final val = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (val == null || val <= 0) return 'Berat tidak valid';
                    return null;
                  },
                  onChanged: (_) {
                    if (_isGold) _recalculateGoldPrice();
                  },
                ),
                const SizedBox(height: 16),

                if (_isGold) ...[
                  _buildLabel('KARAT'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _karatController,
                    decoration: _inputDecoration(Icons.workspace_premium_outlined, 'Masukkan karat (contoh: 22K)'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                    onChanged: (_) => _recalculateGoldPrice(),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildLabel('HARGA DASAR'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  readOnly: _isGold,
                  decoration: _inputDecoration(
                    Icons.payments_outlined,
                    _isGold ? 'Dihitung otomatis' : 'Masukkan harga dasar',
                  ).copyWith(
                    filled: true,
                    fillColor: _isGold ? const Color(0xFFF3F4F6) : Colors.white,
                    suffixIcon: _isGold
                        ? const Tooltip(
                            message: 'Dihitung otomatis dari berat x karat x harga emas aktif',
                            child: Icon(Icons.lock, color: Color(0xFF9CA3AF)),
                          )
                        : null,
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _isGold ? const Color(0xFF6B7280) : const Color(0xFF111827),
                  ),
                  keyboardType: _isGold ? null : TextInputType.number,
                  inputFormatters: _isGold
                      ? []
                      : [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  validator: _isGold
                      ? null
                      : (v) {
                          final val = double.tryParse((v ?? '').replaceAll('.', '').replaceAll(',', ''));
                          if (val == null || val <= 0) return 'Harga tidak valid';
                          return null;
                        },
                ),
                if (_isGold) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF785A1A)),
                      const SizedBox(width: 6),
                      Text(
                        'Harga Emas Aktif: Rp ${NumberFormat.decimalPattern('id').format(widget.provider.goldPricePerGram.round())}/gram',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF785A1A),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                _buildLabel('DESKRIPSI (OPSIONAL)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(Icons.notes, 'Masukkan deskripsi tambahan'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: _save,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text(
                      'SIMPAN PERUBAHAN',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF374151),
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
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
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
      ),
    );
  }
}
