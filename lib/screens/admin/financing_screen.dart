import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/financing_calculator.dart';
import '../../widgets/responsive_row_column.dart';

class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});

  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  // Parameter utama
  List<int> _dpOptions = [15, 25, 35, 50];
  double _adminFeeFlat = 15000;
  double _adminFeePercent = 0;
  double _munahRate = 0.38;
  bool _isActive = true;

  double _stlPrice = 502894;

  // Controllers for editable fields
  late TextEditingController _stlController;
  late TextEditingController _adminFeeFlatController;

  // Tenors
  List<Map<String, dynamic>> _tenors = [];
  int? _selectedTenorMonths;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stlController = TextEditingController();
    _adminFeeFlatController = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _stlController.dispose();
    _adminFeeFlatController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final config = await provider.getActiveFinancingConfig();
    final tenors = await provider.getFinancingTenors(config?['id'] as int? ?? 0);

    if (config != null) {
      if (mounted) {
        setState(() {
          _dpOptions = (config['dp_options'] as String)
              .split(',')
              .map((s) => int.parse(s.trim()))
              .toList();
          _adminFeeFlat = (config['admin_fee_flat'] as num).toDouble();
          _adminFeePercent = (config['admin_fee_percent'] as num).toDouble();
          _munahRate = (config['munah_rate'] as num).toDouble();
          _isActive = config['is_active'] == 1;
          _tenors = tenors.map((t) => Map<String, dynamic>.from(t)).toList();
          if (_tenors.isNotEmpty) {
            _selectedTenorMonths = _tenors.first['months'] as int;
          }

          _stlPrice = (config['stl_price'] as num?)?.toDouble() ?? 502894;

          // Set controller values
          _stlController.text = _stlPrice.round().toString();
          _adminFeeFlatController.text = _adminFeeFlat.round().toString();

          _isLoading = false;
        });
      }
    } else {
      // Use defaults
      setState(() {
        _tenors = [
          {'months': 6, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.075, 'bunga_flat': 0.0},
          {'months': 12, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.15, 'bunga_flat': 0.0},
          {'months': 18, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.234, 'bunga_flat': 0.0},
          {'months': 24, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.312, 'bunga_flat': 0.0},
          {'months': 36, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.504, 'bunga_flat': 0.0},
        ];
        _selectedTenorMonths = 6;

        _stlController.text = '502894';
        _adminFeeFlatController.text = '70000';

        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final stlVal = double.tryParse(_stlController.text) ?? 502894;
      final hdleVal = provider.goldPricePerGram;
      final adminFlatVal = double.tryParse(_adminFeeFlatController.text) ?? 70000;

      await Provider.of<AppProvider>(
        context,
        listen: false,
      ).saveFinancingConfig(
        dpOptions: _dpOptions.join(','),
        adminFeeFlat: adminFlatVal,
        adminFeePercent: _adminFeePercent,
        munahRate: _munahRate,
        isActive: _isActive,
        tenors: _tenors,
        stlPrice: stlVal,
        hdlePrice: hdleVal,
        loanRatio: 0.95,
        umPercentageKca: 0.192,
        umPercentageKrasida: 0.185,
        bungaKca: 0.0,
        tempoKca: 4,
        minimumUpKca: 0,
        minimumUpKrasida: 0,
      );

      await _loadConfig();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Konfigurasi pembiayaan berhasil disimpan!'),
            backgroundColor: AppColors.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.of(context).size.width < 900;
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24), 
          
          // Title row
          isPortrait
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konfigurasi Pembiayaan Syariah',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isActive ? AppColors.secondary : AppColors.muted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle : Icons.cancel_outlined,
                            color: _isActive
                                ? AppColors.successGreen
                                : AppColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isActive ? 'Aturan aktif' : 'Nonaktif',
                            style: TextStyle(
                              color: _isActive
                                  ? AppColors.successGreen
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Konfigurasi Pembiayaan Syariah',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isActive ? AppColors.secondary : AppColors.muted,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle : Icons.cancel_outlined,
                            color: _isActive
                                ? AppColors.successGreen
                                : AppColors.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isActive ? 'Aturan aktif' : 'Nonaktif',
                            style: TextStyle(
                              color: _isActive
                                  ? AppColors.successGreen
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 6),
          const Text(
            'Atur parameter bunga, uang muka, STL, dan ratio pinjaman SQLite outlet secara real-time.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),

          ResponsiveRowColumn(
            isPortrait: isPortrait,
            spacing: 28,
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Card 1: Parameter Emas & Nilai Taksir
                    _buildConfigCard(
                      title: 'Parameter Emas & Nilai Taksir',
                      icon: Icons.gavel_outlined,
                      children: [
                        _buildParamInputField(
                          label: 'STL per Gram (24K)',
                          controller: _stlController,
                          suffixText: 'Rp',
                        ),
                      ],
                    ),

                    // Card 2: Administrasi & Biaya
                    _buildConfigCard(
                      title: 'Administrasi & Biaya',
                      icon: Icons.payments_outlined,
                      children: [
                        _buildParamInputField(
                          label: 'Biaya Administrasi Flat (Rp)',
                          controller: _adminFeeFlatController,
                          suffixText: 'Rp',
                        ),
                      ],
                    ),

                    // Card 4: Status Aturan
                    _buildConfigCard(
                      title: 'Status Aturan Konfigurasi',
                      icon: Icons.toggle_on_outlined,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.muted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              'Status Aktif',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: const Text(
                              'Aktifkan aturan simulasi pembiayaan ini',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _isActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            right: Column(
              children: [
                    // Tenor multiplier table container
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tenor KRASIDA & Multiplier',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tenor selection chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tenors.map((tenor) {
                              final months = tenor['months'] as int;
                              final isSelected = _selectedTenorMonths == months;
                              final isActive = tenor['is_active'] == 1;

                              return ChoiceChip(
                                label: Text('$months bln'),
                                selected: isSelected,
                                selectedColor: AppColors.accent,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isActive
                                          ? AppColors.textDark
                                          : AppColors.textMuted),
                                  fontWeight: FontWeight.w800,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedTenorMonths = months);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Tenors table
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.muted,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.cardBorder,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Tenor',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Multiplier',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Rows
                                ...List.generate(_tenors.length, (index) {
                                  final tenor = _tenors[index];
                                  final months = tenor['months'] as int;
                                  final isActive = tenor['is_active'] == 1;
                                  final multiplier =
                                      (tenor['multiplier'] as num?)?.toDouble() ?? 1.0;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: index < _tenors.length - 1
                                          ? const Border(
                                              bottom: BorderSide(
                                                color: AppColors.cardBorder,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Checkbox(
                                                value: isActive,
                                                activeColor: AppColors.primary,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _tenors[index]['is_active'] =
                                                        val == true ? 1 : 0;
                                                  });
                                                },
                                              ),
                                              Expanded(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment: Alignment.centerLeft,
                                                  child: Text(
                                                    isActive ? 'On' : 'Off',
                                                    style: TextStyle(
                                                      color: isActive
                                                          ? AppColors.textDark
                                                          : AppColors.textMuted,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '$months bln',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              multiplier.toStringAsFixed(3),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                            onPressed: () => _showEditTenorDialog(index),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Impact Preview Panel
                    _buildImpactPreview(),
                  ],
                ),
            ),

          const SizedBox(height: 28),

          // Save button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveConfig,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 20),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildParamInputField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    TextInputType keyboardType = TextInputType.number,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.muted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (val) => setState(() {}),
        ),
      ],
    );
  }

  void _showEditTenorDialog(int index) {
    final tenor = _tenors[index];
    final months = tenor['months'] as int;
    final multiplier = (tenor['multiplier'] as num?)?.toDouble() ?? 1.0;

    final multiplierCtrl = TextEditingController(text: multiplier.toStringAsFixed(3));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Tenor $months Bulan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: multiplierCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Multiplier (Faktor Excel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final multVal = double.tryParse(multiplierCtrl.text) ?? multiplier;
              setState(() {
                _tenors[index]['multiplier'] = multVal;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactPreview() {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Mock item price from excel reference
    const mockPrice = 6580000;
    final adminFlat = double.tryParse(_adminFeeFlatController.text) ?? 70000;

    final config = {
      'admin_fee_flat': adminFlat,
    };

    // 1. Tunai
    final tunaiTotal = mockPrice;

    // 2. KCA
    final kcaRes = FinancingCalculator.simulasiKca(
      hargaLelang: mockPrice,
      appraisalValue: mockPrice.toDouble(),
      config: config,
    );

    final kcaUm = kcaRes.uangMuka;
    final kcaUp = kcaRes.uangPinjaman;
    final kcaPelunasan = kcaRes.totalPelunasanKca!;
    final tempoKca = kcaRes.tempoKca!;

    // 3. KRASIDA
    final tenorMonths = _selectedTenorMonths ?? (_tenors.isNotEmpty ? _tenors.first['months'] as int : 12);
    final krasidaRes = FinancingCalculator.simulasiKrasida(
      hargaLelang: mockPrice,
      appraisalValue: mockPrice.toDouble(),
      config: config,
      tenors: _tenors,
      tenorMonths: tenorMonths,
    );

    final krasidaUm = krasidaRes.uangMuka;
    final krasidaUp = krasidaRes.uangPinjaman;
    final krasidaAngsuran = krasidaRes.angsuranPerBulan!;
    final krasidaTotal = krasidaRes.totalBayar!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'IMPACT PREVIEW (Simulasi Contoh)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Menggunakan contoh harga barang: ${currencyFormatter.format(mockPrice)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // TUNAI CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9), // Light green tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.successGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'TUNAI',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currencyFormatter.format(tunaiTotal),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 28),
                  child: Text(
                    'Bayar penuh saat transaksi, tanpa bunga/cicilan.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KCA CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD), // Light blue tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card_outlined, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'KCA — Tempo $tempoKca Bulan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.categoryBlueText,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildImpactDetailRow('Uang Muka (DP)', currencyFormatter.format(kcaUm)),
                _buildImpactDetailRow('Uang Pinjaman', currencyFormatter.format(kcaUp)),
                _buildImpactDetailRow('Biaya Admin', currencyFormatter.format(adminFlat.round())),
                const Divider(height: 16),
                _buildImpactDetailRow(
                  'Total Pelunasan',
                  currencyFormatter.format(kcaPelunasan),
                  isBold: true,
                  textColor: AppColors.categoryBlueText,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KRASIDA CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Light gold tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFECB3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart_outlined, color: AppColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'KRASIDA — Tenor $tenorMonths Bulan',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.categoryAmberText,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildImpactDetailRow('Uang Muka (DP)', currencyFormatter.format(krasidaUm)),
                _buildImpactDetailRow('Uang Pinjaman', currencyFormatter.format(krasidaUp)),
                _buildImpactDetailRow('Angsuran per Bulan', '${currencyFormatter.format(krasidaAngsuran)} / bln'),
                const Divider(height: 16),
                _buildImpactDetailRow(
                  'Total Bayar',
                  currencyFormatter.format(krasidaTotal),
                  isBold: true,
                  textColor: AppColors.categoryAmberText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactDetailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                  color: textColor ?? AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
