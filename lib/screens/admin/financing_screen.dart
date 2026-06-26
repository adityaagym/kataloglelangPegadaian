import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/financing_calculator.dart';

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
  double _hdlePrice = 550000;
  double _loanRatio = 0.95;
  double _umPercentageKca = 0.192;
  double _umPercentageKrasida = 0.185;
  double _bungaKca = 0.0125;
  int _tempoKca = 4;
  int _minimumUpKca = 500000;
  int _minimumUpKrasida = 500000;

  // Controllers for editable fields
  late TextEditingController _stlController;
  late TextEditingController _hdleController;
  late TextEditingController _loanRatioController;
  late TextEditingController _adminFeeFlatController;
  late TextEditingController _umPercentageKcaController;
  late TextEditingController _umPercentageKrasidaController;
  late TextEditingController _bungaKcaController;
  late TextEditingController _tempoKcaController;
  late TextEditingController _minimumUpKcaController;
  late TextEditingController _minimumUpKrasidaController;

  // Tenors
  List<Map<String, dynamic>> _tenors = [];
  int? _selectedTenorMonths;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _stlController = TextEditingController();
    _hdleController = TextEditingController();
    _loanRatioController = TextEditingController();
    _adminFeeFlatController = TextEditingController();
    _umPercentageKcaController = TextEditingController();
    _umPercentageKrasidaController = TextEditingController();
    _bungaKcaController = TextEditingController();
    _tempoKcaController = TextEditingController();
    _minimumUpKcaController = TextEditingController();
    _minimumUpKrasidaController = TextEditingController();
    _loadConfig();
  }

  @override
  void dispose() {
    _stlController.dispose();
    _hdleController.dispose();
    _loanRatioController.dispose();
    _adminFeeFlatController.dispose();
    _umPercentageKcaController.dispose();
    _umPercentageKrasidaController.dispose();
    _bungaKcaController.dispose();
    _tempoKcaController.dispose();
    _minimumUpKcaController.dispose();
    _minimumUpKrasidaController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final config = await provider.getActiveFinancingConfig();

    if (config != null) {
      final tenors = await provider.getFinancingTenors(config['id'] as int);
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
          _hdlePrice = (config['hdle_price'] as num?)?.toDouble() ?? 550000;
          _loanRatio = (config['loan_ratio'] as num?)?.toDouble() ?? 0.95;
          _umPercentageKca = (config['um_percentage_kca'] as num?)?.toDouble() ?? 0.192;
          _umPercentageKrasida = (config['um_percentage_krasida'] as num?)?.toDouble() ?? 0.185;
          _bungaKca = (config['bunga_kca'] as num?)?.toDouble() ?? 0.0125;
          _tempoKca = (config['tempo_kca'] as num?)?.toInt() ?? 4;
          _minimumUpKca = (config['minimum_up_kca'] as num?)?.toInt() ?? 500000;
          _minimumUpKrasida = (config['minimum_up_krasida'] as num?)?.toInt() ?? 500000;

          // Set controller values
          _stlController.text = _stlPrice.round().toString();
          _hdleController.text = _hdlePrice.round().toString();
          _loanRatioController.text = (_loanRatio * 100).toStringAsFixed(0);
          _adminFeeFlatController.text = _adminFeeFlat.round().toString();
          _umPercentageKcaController.text = (_umPercentageKca * 100).toStringAsFixed(1);
          _umPercentageKrasidaController.text = (_umPercentageKrasida * 100).toStringAsFixed(1);
          _bungaKcaController.text = (_bungaKca * 100).toStringAsFixed(2);
          _tempoKcaController.text = _tempoKca.toString();
          _minimumUpKcaController.text = _minimumUpKca.toString();
          _minimumUpKrasidaController.text = _minimumUpKrasida.toString();

          _isLoading = false;
        });
      }
    } else {
      // Use defaults
      setState(() {
        _tenors = [
          {'months': 6, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.075, 'bunga_flat': 0.0125},
          {'months': 12, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.15, 'bunga_flat': 0.0125},
          {'months': 18, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.234, 'bunga_flat': 0.0130},
          {'months': 24, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.312, 'bunga_flat': 0.0130},
          {'months': 36, 'is_active': 1, 'other_fee': 0.0, 'multiplier': 1.504, 'bunga_flat': 0.0140},
        ];
        _selectedTenorMonths = 6;

        _stlController.text = '502894';
        _hdleController.text = '550000';
        _loanRatioController.text = '95';
        _adminFeeFlatController.text = '15000';
        _umPercentageKcaController.text = '19.2';
        _umPercentageKrasidaController.text = '18.5';
        _bungaKcaController.text = '1.25';
        _tempoKcaController.text = '4';
        _minimumUpKcaController.text = '500000';
        _minimumUpKrasidaController.text = '500000';

        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final stlVal = double.tryParse(_stlController.text) ?? 502894;
      final hdleVal = double.tryParse(_hdleController.text) ?? 550000;
      final loanRatioVal = (double.tryParse(_loanRatioController.text) ?? 95) / 100;
      final adminFlatVal = double.tryParse(_adminFeeFlatController.text) ?? 15000;
      final umKcaVal = (double.tryParse(_umPercentageKcaController.text) ?? 19.2) / 100;
      final umKrasidaVal = (double.tryParse(_umPercentageKrasidaController.text) ?? 18.5) / 100;
      final bungaKcaVal = (double.tryParse(_bungaKcaController.text) ?? 1.25) / 100;
      final tempoKcaVal = int.tryParse(_tempoKcaController.text) ?? 4;
      final minUpKcaVal = int.tryParse(_minimumUpKcaController.text) ?? 500000;
      final minUpKrasidaVal = int.tryParse(_minimumUpKrasidaController.text) ?? 500000;

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
        loanRatio: loanRatioVal,
        umPercentageKca: umKcaVal,
        umPercentageKrasida: umKrasidaVal,
        bungaKca: bungaKcaVal,
        tempoKca: tempoKcaVal,
        minimumUpKca: minUpKcaVal,
        minimumUpKrasida: minUpKrasidaVal,
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
          const SizedBox(height: 24), // Lower the header as requested
          
          // Title row
          Row(
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

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: All parameters (scrollable Form)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Parameter Emas & Nilai Taksir
                    _buildConfigCard(
                      title: 'Parameter Emas & Nilai Taksir',
                      icon: Icons.gavel_outlined,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildParamInputField(
                                label: 'STL per Gram (24K)',
                                controller: _stlController,
                                suffixText: 'Rp',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildParamInputField(
                                label: 'HDLE per Gram (24K)',
                                controller: _hdleController,
                                suffixText: 'Rp',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildParamInputField(
                                label: 'Loan Ratio (%)',
                                controller: _loanRatioController,
                                suffixText: '%',
                              ),
                            ),
                          ],
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

                    // Card 3: Skema Pembiayaan (KCA & KRASIDA)
                    _buildConfigCard(
                      title: 'Skema Pembiayaan KCA & KRASIDA',
                      icon: Icons.tune_outlined,
                      children: [
                        const Text(
                          'SKEMA KCA (Kredit Cepat Aman)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildParamInputField(
                                label: 'DP KCA (%)',
                                controller: _umPercentageKcaController,
                                suffixText: '%',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildParamInputField(
                                label: 'Bunga KCA / Bln (%)',
                                controller: _bungaKcaController,
                                suffixText: '%',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildParamInputField(
                                label: 'Tempo KCA (Bulan)',
                                controller: _tempoKcaController,
                                suffixText: 'bln',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildParamInputField(
                                label: 'Minimum UP KCA (Rp)',
                                controller: _minimumUpKcaController,
                                suffixText: 'Rp',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text(
                          'SKEMA KRASIDA (Kredit Gadai Angsuran)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildParamInputField(
                                label: 'DP KRASIDA (%)',
                                controller: _umPercentageKrasidaController,
                                suffixText: '%',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildParamInputField(
                                label: 'Minimum UP KRASIDA (Rp)',
                                controller: _minimumUpKrasidaController,
                                suffixText: 'Rp',
                              ),
                            ),
                          ],
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
              ),

              const SizedBox(width: 24),

              // Right Column: Tenor, Multipliers and Impact Preview
              Expanded(
                flex: 4,
                child: Column(
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
                                        flex: 2,
                                        child: Text(
                                          'Bunga',
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
                                  final bungaFlat =
                                      (tenor['bunga_flat'] as num?)?.toDouble() ?? 0.0125;

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
                                              Text(
                                                isActive ? 'On' : 'Off',
                                                style: TextStyle(
                                                  color: isActive
                                                      ? AppColors.textDark
                                                      : AppColors.textMuted,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '$months bln',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            multiplier.toStringAsFixed(3),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${(bungaFlat * 100).toStringAsFixed(2)}%',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
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
            ],
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
    final bungaFlat = (tenor['bunga_flat'] as num?)?.toDouble() ?? 0.0125;

    final multiplierCtrl = TextEditingController(text: multiplier.toStringAsFixed(3));
    final bungaCtrl = TextEditingController(text: (bungaFlat * 100).toStringAsFixed(2));

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
            const SizedBox(height: 12),
            TextField(
              controller: bungaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bunga Flat per Bulan (%)'),
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
              final bungaVal = (double.tryParse(bungaCtrl.text) ?? (bungaFlat * 100)) / 100;
              setState(() {
                _tenors[index]['multiplier'] = multVal;
                _tenors[index]['bunga_flat'] = bungaVal;
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

    // Read current form values
    final umKcaPercentage = (double.tryParse(_umPercentageKcaController.text) ?? 19.2) / 100;
    final bungaKca = (double.tryParse(_bungaKcaController.text) ?? 1.25) / 100;
    final tempoKca = int.tryParse(_tempoKcaController.text) ?? 4;
    final minUpKca = int.tryParse(_minimumUpKcaController.text) ?? 500000;
    final adminFlat = double.tryParse(_adminFeeFlatController.text) ?? 15000;

    final umKrasidaPercentage = (double.tryParse(_umPercentageKrasidaController.text) ?? 18.5) / 100;
    final minUpKrasida = int.tryParse(_minimumUpKrasidaController.text) ?? 500000;

    // Run mock calculations locally
    // 1. Tunai
    final tunaiTotal = mockPrice;

    // 2. KCA
    final kcaUm = FinancingCalculator.roundDown(mockPrice * umKcaPercentage, 1000);
    final kcaUp = mockPrice - kcaUm;
    final kcaEligible = kcaUp >= minUpKca;
    final kcaBungaTotal = (kcaUp * bungaKca * tempoKca).round();
    final kcaPelunasan = kcaUp + kcaBungaTotal + adminFlat.round();

    // 3. KRASIDA
    final tenorMonths = _selectedTenorMonths ?? (_tenors.isNotEmpty ? _tenors.first['months'] as int : 12);
    Map<String, dynamic>? tenorObj;
    try {
      tenorObj = _tenors.firstWhere((t) => t['months'] == tenorMonths);
    } catch (_) {}

    final krasidaUm = FinancingCalculator.roundDown(mockPrice * umKrasidaPercentage, 1000);
    final krasidaUp = mockPrice - krasidaUm;
    final krasidaEligible = krasidaUp >= minUpKrasida;

    final multiplier = tenorObj != null ? (tenorObj['multiplier'] as num).toDouble() : 1.15;
    final krasidaAngsuran = FinancingCalculator.roundUp((krasidaUp * multiplier) / tenorMonths, 100);
    final krasidaTotal = krasidaAngsuran * tenorMonths;
    final krasidaBunga = krasidaTotal - krasidaUp;

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
          if (kcaEligible)
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
                  _buildImpactDetailRow('Bunga Total ($tempoKca Bln)', currencyFormatter.format(kcaBungaTotal)),
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
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), // Light red tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KCA (Tidak Eligible)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uang Pinjaman ${currencyFormatter.format(kcaUp)} di bawah minimum ${currencyFormatter.format(minUpKca)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // KRASIDA CARD
          if (krasidaEligible)
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
                  _buildImpactDetailRow('Bunga Total', currencyFormatter.format(krasidaBunga)),
                  const Divider(height: 16),
                  _buildImpactDetailRow(
                    'Total Bayar',
                    currencyFormatter.format(krasidaTotal),
                    isBold: true,
                    textColor: AppColors.categoryAmberText,
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE), // Light red tint
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KRASIDA (Tidak Eligible)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uang Pinjaman ${currencyFormatter.format(krasidaUp)} di bawah minimum ${currencyFormatter.format(minUpKrasida)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
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
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
