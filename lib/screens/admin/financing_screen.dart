import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_colors.dart';

class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});

  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  // Parameter utama
  List<int> _dpOptions = [15, 25, 35, 50];
  double _adminFeeFlat = 50000;
  double _adminFeePercent = 0;
  double _munahRate = 0.38;
  bool _isActive = true;

  // Tenors
  List<Map<String, dynamic>> _tenors = [];
  int? _selectedTenorMonths;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
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
          _isLoading = false;
        });
      }
    } else {
      // Use defaults
      setState(() {
        _tenors = [
          {'months': 6, 'is_active': 1, 'other_fee': 0.0},
          {'months': 12, 'is_active': 1, 'other_fee': 0.0},
          {'months': 18, 'is_active': 1, 'other_fee': 0.0},
          {'months': 24, 'is_active': 1, 'other_fee': 0.0},
          {'months': 36, 'is_active': 1, 'other_fee': 0.0},
        ];
        _selectedTenorMonths = 6;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await Provider.of<AppProvider>(
        context,
        listen: false,
      ).saveFinancingConfig(
        dpOptions: _dpOptions.join(','),
        adminFeeFlat: _adminFeeFlat,
        adminFeePercent: _adminFeePercent,
        munahRate: _munahRate,
        isActive: _isActive,
        tenors: _tenors,
      );

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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Konfigurasi Pembiayaan Syariah',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
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
            'Mock konfigurasi ini disiapkan agar mudah diganti dengan data SQLite outlet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left - Parameter Utama
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parameter Utama',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // DP Options + Admin Fee
                      Row(
                        children: [
                          Expanded(
                            child: _buildParamCard(
                              'Pilihan DP',
                              _dpOptions.map((d) => '$d%').join(', '),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildParamCard(
                              'Biaya admin flat',
                              currencyFormatter.format(_adminFeeFlat),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildParamCard(
                              'Biaya admin persen',
                              '${_adminFeePercent.toStringAsFixed(0)}%',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildParamCard(
                              "Mu'nah per 10 hari",
                              '${_munahRate.toStringAsFixed(2)}%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Status Aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: const Text(
                            'Aktifkan/nonaktifkan aturan ini',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Right - Tenor dan Biaya Lain
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tenor dan Biaya Lain',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tenor chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _tenors.map((tenor) {
                          final months = tenor['months'] as int;
                          final isSelected = _selectedTenorMonths == months;
                          final isActive = tenor['is_active'] == 1;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTenorMonths = months),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isActive
                                          ? AppColors.secondary
                                          : AppColors.muted),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isActive
                                            ? AppColors.primary.withValues(
                                                alpha: 0.3,
                                              )
                                            : AppColors.border),
                                ),
                              ),
                              child: Text(
                                '$months bulan',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isActive
                                            ? AppColors.successGreen
                                            : AppColors.textMuted),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Tenor table
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
                                horizontal: 16,
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
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Tenor',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Basis Per 10 Hari',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Biaya Lain',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
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
                              final otherFee =
                                  (tenor['other_fee'] as num?)?.toDouble() ?? 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? AppColors.successGreen
                                                  : AppColors.textMuted,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isActive ? 'Aktif' : 'Off',
                                            style: TextStyle(
                                              color: isActive
                                                  ? AppColors.textDark
                                                  : AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '$months bulan',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${_munahRate.toStringAsFixed(2)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        otherFee > 0
                                            ? currencyFormatter.format(otherFee)
                                            : 'Rp 0',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
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
                    ],
                  ),
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
                  : const Icon(Icons.save, size: 20),
              label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Konfigurasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
