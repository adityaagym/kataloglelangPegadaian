import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/financing_calculator.dart';
import '../../widgets/responsive_row_column.dart';

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digits
    final cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final double val = double.parse(cleanText);
    final formatter = NumberFormat.decimalPattern('id');
    final formatted = formatter.format(val);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FinancingScreen extends StatefulWidget {
  const FinancingScreen({super.key});

  @override
  State<FinancingScreen> createState() => _FinancingScreenState();
}

class _FinancingScreenState extends State<FinancingScreen> {
  // Parameter utama
  List<int> _dpOptions = [15, 25, 35, 50];
  double _adminFeeFlat = 70000;
  double _adminFeePercent = 0;
  double _munahRate = 0.38;
  bool _isActive = true;

  double _stlPrice = 2200000;

  // Track original values to show floating save button when modified
  double _originalStlPrice = 2200000;
  double _originalAdminFeeFlat = 70000;
  bool _originalIsActive = true;
  List<Map<String, dynamic>> _originalTenors = [];

  bool get _hasChanges {
    final cleanStlText = _stlController.text.replaceAll('.', '').replaceAll(',', '');
    final currentStl = double.tryParse(cleanStlText) ?? _originalStlPrice;
    
    final cleanAdminText = _adminFeeFlatController.text.replaceAll('.', '').replaceAll(',', '');
    final currentAdmin = double.tryParse(cleanAdminText) ?? _originalAdminFeeFlat;

    if (currentStl != _originalStlPrice) return true;
    if (currentAdmin != _originalAdminFeeFlat) return true;
    if (_isActive != _originalIsActive) return true;

    // Check tenors
    if (_tenors.length != _originalTenors.length) return true;
    for (int i = 0; i < _tenors.length; i++) {
      final tCurrent = _tenors[i];
      final tOrig = _originalTenors[i];
      if (tCurrent['is_active'] != tOrig['is_active']) return true;
      
      final currentMultiplier = (tCurrent['multiplier'] as num?)?.toDouble() ?? 1.0;
      final origMultiplier = (tOrig['multiplier'] as num?)?.toDouble() ?? 1.0;
      if ((currentMultiplier - origMultiplier).abs() > 0.0001) return true;
    }

    return false;
  }

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
    final config = await provider.getLatestFinancingConfig();
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

          // Set controller values with formatting
          final formatter = NumberFormat.decimalPattern('id');
          _stlController.text = formatter.format(_stlPrice.round());
          _adminFeeFlatController.text = formatter.format(_adminFeeFlat.round());

          // Initialize tracking values
          _originalStlPrice = _stlPrice;
          _originalAdminFeeFlat = _adminFeeFlat;
          _originalIsActive = _isActive;
          _originalTenors = _tenors.map((t) => Map<String, dynamic>.from(t)).toList();

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

        final formatter = NumberFormat.decimalPattern('id');
        _stlController.text = formatter.format(2200000);
        _adminFeeFlatController.text = formatter.format(70000);

        // Initialize tracking values
        _originalStlPrice = 2200000;
        _originalAdminFeeFlat = 70000;
        _originalIsActive = _isActive;
        _originalTenors = _tenors.map((t) => Map<String, dynamic>.from(t)).toList();

        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      final provider = Provider.of<AppProvider>(context, listen: false);
      
      final cleanStlText = _stlController.text.replaceAll('.', '').replaceAll(',', '');
      final stlVal = double.tryParse(cleanStlText) ?? 2200000;
      
      final hdleVal = provider.goldPricePerGram;
      
      final cleanAdminText = _adminFeeFlatController.text.replaceAll('.', '').replaceAll(',', '');
      final adminFlatVal = double.tryParse(cleanAdminText) ?? 70000;

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
            content: const Text(
              'Konfigurasi pembiayaan berhasil disimpan!',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20), // Lower the header
                
                // Title row
                isPortrait
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konfigurasi Pembiayaan Syariah',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isActive ? const Color(0xFFC8E6C9) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isActive ? Icons.check_circle : Icons.cancel_outlined,
                                  color: _isActive
                                      ? AppColors.primary
                                      : const Color(0xFF6B7280),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isActive ? 'Aturan aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    color: _isActive
                                        ? AppColors.primary
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
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
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isActive ? const Color(0xFFC8E6C9) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isActive ? Icons.check_circle : Icons.cancel_outlined,
                                  color: _isActive
                                      ? AppColors.primary
                                      : const Color(0xFF6B7280),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isActive ? 'Aturan aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    color: _isActive
                                        ? AppColors.primary
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
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
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),

                if (isPortrait) ...[
                  _buildMainParametersCard(),
                  const SizedBox(height: 20),
                  _buildImpactPreview(),
                  const SizedBox(height: 20),
                  _buildTenorTableCard(),
                ] else ...[
                  ResponsiveRowColumn(
                    isPortrait: false,
                    spacing: 28,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainParametersCard(),
                        const SizedBox(height: 20),
                        _buildTenorTableCard(),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImpactPreview(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_hasChanges)
            Positioned(
              left: 32,
              right: 32,
              bottom: 24,
              child: _buildFloatingSaveButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainParametersCard() {
    return _buildConfigCard(
      title: 'Parameter & Aturan Utama',
      icon: Icons.tune_outlined,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useHorizontal = constraints.maxWidth > 650;
            if (useHorizontal) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildParamInputField(
                      label: 'STL per Gram (24K)',
                      controller: _stlController,
                      prefixText: 'Rp ',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandSeparatorFormatter()],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildParamInputField(
                      label: 'Biaya Administrasi Flat',
                      controller: _adminFeeFlatController,
                      prefixText: 'Rp ',
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandSeparatorFormatter()],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildStatusSwitchField(),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildParamInputField(
                    label: 'STL per Gram (24K)',
                    controller: _stlController,
                    prefixText: 'Rp ',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandSeparatorFormatter()],
                  ),
                  const SizedBox(height: 16),
                  _buildParamInputField(
                    label: 'Biaya Administrasi Flat',
                    controller: _adminFeeFlatController,
                    prefixText: 'Rp ',
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandSeparatorFormatter()],
                  ),
                  const SizedBox(height: 16),
                  _buildStatusSwitchField(),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatusSwitchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Aktif Aturan',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52, // matches the height of our parameter textfields
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Aktif',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF111827),
                ),
              ),
              Switch(
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTenorTableCard() {
    return _buildConfigCard(
      title: 'Tenor Arrum Emas & Multiplier',
      icon: Icons.calendar_month_outlined,
      children: [
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
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF3F4F6),
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isActive
                        ? const Color(0xFF111827)
                        : const Color(0xFF9CA3AF)),
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                ),
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
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      color: Color(0xFFE5E7EB),
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'STATUS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'TENOR',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'MULTIPLIER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'EDIT',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
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
                              color: Color(0xFFE5E7EB),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
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
                                  isActive ? 'Aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF111827)
                                        : const Color(0xFF9CA3AF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
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
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF111827),
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
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
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
    );
  }

  Widget _buildFloatingSaveButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = MediaQuery.of(context).size.width > 650;
        final button = ElevatedButton.icon(
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
              : const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: Text(
            _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),
          ),
        );

        final notificationIcon = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 20,
          ),
        );

        final textColumn = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Perubahan Terdeteksi',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Anda memiliki parameter yang belum disimpan.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: isWide
              ? Row(
                  children: [
                    notificationIcon,
                    const SizedBox(width: 16),
                    Expanded(child: textColumn),
                    const SizedBox(width: 16),
                    button,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        notificationIcon,
                        const SizedBox(width: 16),
                        Expanded(child: textColumn),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: button,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
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
    String? prefixText,
    TextInputType keyboardType = TextInputType.number,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Text(
          'Edit Tenor $months Bulan',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Multiplier (Faktor Cicilan Excel)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: multiplierCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () {
              final multVal = double.tryParse(multiplierCtrl.text) ?? multiplier;
              setState(() {
                _tenors[index]['multiplier'] = multVal;
              });
              Navigator.pop(ctx);
            },
            child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.w900)),
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

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Simulasi contoh: emas 22K berat 10 gram.
    const mockWeightGram = 10.0;
    const mockKaratVal = 22.0;
    final hdlePrice = provider.goldPricePerGram.toDouble();
    final cleanStlText = _stlController.text.replaceAll('.', '').replaceAll(',', '');
    final stlPrice = double.tryParse(cleanStlText) ?? _stlPrice;
    final adminFlat = double.tryParse(_adminFeeFlatController.text.replaceAll('.', '').replaceAll(',', '')) ?? _adminFeeFlat;

    final mockHargaLelang = FinancingCalculator.hitungHargaEmas(
      hdlePrice: hdlePrice,
      weightGram: mockWeightGram,
      karatVal: mockKaratVal,
    );
    final mockAppraisalValue = FinancingCalculator.hitungNilaiTaksiran(
      stlPrice: stlPrice,
      weightGram: mockWeightGram,
      karatVal: mockKaratVal,
    );

    final config = {
      'admin_fee_flat': adminFlat,
    };

    // 1. Tunai
    final tunaiTotal = mockHargaLelang;

    // 2. KCA
    final kcaRes = FinancingCalculator.simulasiKca(
      hargaLelang: mockHargaLelang,
      appraisalValue: mockAppraisalValue,
      config: config,
    );

    final kcaUm = kcaRes.uangMuka;
    final kcaUp = kcaRes.uangPinjaman;
    final kcaPelunasan = kcaRes.totalPelunasanKca ?? 0;
    final tempoKca = kcaRes.tempoKca ?? 4;

    // 3. KRASIDA
    final tenorMonths = _selectedTenorMonths ?? (_tenors.isNotEmpty ? _tenors.first['months'] as int : 12);
    final krasidaRes = FinancingCalculator.simulasiKrasida(
      hargaLelang: mockHargaLelang,
      appraisalValue: mockAppraisalValue,
      config: config,
      tenors: _tenors,
      tenorMonths: tenorMonths,
    );

    final krasidaUm = krasidaRes.uangMuka;
    final krasidaUp = krasidaRes.uangPinjaman;
    final krasidaAngsuran = krasidaRes.angsuranPerBulan ?? 0;
    final krasidaTotal = krasidaRes.totalBayar ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.insights_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'IMPACT PREVIEW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFF4B5563)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulasi: Emas 22K · 10g · ${currencyFormatter.format(mockHargaLelang)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TUNAI CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'TUNAI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Text(
                        currencyFormatter.format(tunaiTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Text(
                    'Bayar penuh saat transaksi, tanpa bunga/cicilan.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card_outlined, color: Color(0xFF1D4ED8), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Rahn — Tempo $tempoKca Bulan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1D4ED8),
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildImpactDetailRow('Uang Muka (DP)', currencyFormatter.format(kcaUm)),
                _buildImpactDetailRow('Uang Pinjaman', currencyFormatter.format(kcaUp)),
                _buildImpactDetailRow('Biaya Admin', currencyFormatter.format(adminFlat.round())),
                const Divider(height: 20, color: Color(0xFFDBEAFE)),
                _buildImpactDetailRow(
                  'Total Pelunasan',
                  currencyFormatter.format(kcaPelunasan),
                  isBold: true,
                  textColor: const Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // KRASIDA CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart_outlined, color: Color(0xFFB45309), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arrum Emas — Tenor $tenorMonths Bulan',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB45309),
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildImpactDetailRow('Uang Muka (DP)', currencyFormatter.format(krasidaUm)),
                _buildImpactDetailRow('Uang Pinjaman', currencyFormatter.format(krasidaUp)),
                _buildImpactDetailRow('Angsuran per Bulan', '${currencyFormatter.format(krasidaAngsuran)} / bln'),
                const Divider(height: 20, color: Color(0xFFFEF3C7)),
                _buildImpactDetailRow(
                  'Total Bayar',
                  currencyFormatter.format(krasidaTotal),
                  isBold: true,
                  textColor: const Color(0xFFB45309),
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: isBold ? const Color(0xFF111827) : const Color(0xFF4B5563),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
                color: textColor ?? const Color(0xFF111827),
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
