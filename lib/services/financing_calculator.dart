import '../models/auction_item.dart';

enum SkemaType { tunai, kca, krasida }

class SimulasiTenor {
  final int tenor;
  final double bungaPerBulan;
  final int angsuranPerBulan;
  final int totalBayar;
  final int bungaTotal;
  final bool isSelected;

  SimulasiTenor({
    required this.tenor,
    required this.bungaPerBulan,
    required this.angsuranPerBulan,
    required this.totalBayar,
    required this.bungaTotal,
    this.isSelected = false,
  });
}

class SimulasiResult {
  final SkemaType skema;
  final int hargaLelang;
  final int uangMuka;
  final int uangPinjaman;
  final bool eligible;
  final String? message;

  // KCA specific
  final int? tempoKca;
  final int? bungaTotalKca;
  final int? adminFee;
  final int? totalPelunasanKca;

  // KRASIDA specific
  final int? tenor;
  final double? bungaPerBulan;
  final int? angsuranPerBulan;
  final int? totalBayar;
  final int? bungaTotalKrasida;
  final List<SimulasiTenor>? perbandinganTenor;

  SimulasiResult({
    required this.skema,
    required this.hargaLelang,
    required this.uangMuka,
    required this.uangPinjaman,
    this.eligible = true,
    this.message,
    this.tempoKca,
    this.bungaTotalKca,
    this.adminFee,
    this.totalPelunasanKca,
    this.tenor,
    this.bungaPerBulan,
    this.angsuranPerBulan,
    this.totalBayar,
    this.bungaTotalKrasida,
    this.perbandinganTenor,
  });
}

class FinancingCalculation {
  final double sellingPrice;
  final double appraisalValue;
  final double loanAmount;
  final double downPayment;
  final double adminFee;
  final int tenorMonths;
  final double tenorMultiplier;
  final double monthlyInstallment;
  final double totalInstallment;

  const FinancingCalculation({
    required this.sellingPrice,
    required this.appraisalValue,
    required this.loanAmount,
    required this.downPayment,
    required this.adminFee,
    required this.tenorMonths,
    required this.tenorMultiplier,
    required this.monthlyInstallment,
    required this.totalInstallment,
  });
}

class FinancingCalculator {
  static const Map<int, double> defaultTenorMultipliers = {
    6: 1.075,
    12: 1.15,
    18: 1.234,
    24: 1.312,
    36: 1.504,
  };

  static int roundUp(num value, int factor) {
    if (value <= 0) return 0;
    return ((value + factor - 1) ~/ factor) * factor;
  }

  static int roundDown(num value, int factor) {
    if (value <= 0) return 0;
    return (value ~/ factor) * factor;
  }

  static double parseKarat(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    final match = RegExp(r'([0-9]+(?:[.,][0-9]+)?)').firstMatch(value);
    if (match == null) return 0;
    final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
    return parsed.clamp(0, 24).toDouble();
  }

  // 1. Skema Tunai
  static SimulasiResult simulasiTunai({required int hargaLelang}) {
    return SimulasiResult(
      skema: SkemaType.tunai,
      hargaLelang: hargaLelang,
      uangMuka: 0,
      uangPinjaman: 0,
      eligible: true,
    );
  }

  // 2. Skema KCA
  static SimulasiResult simulasiKca({
    required int hargaLelang,
    double? appraisalValue,
    required Map<String, dynamic> config,
  }) {
    final adminFee = (config['admin_fee_flat'] as num?)?.toInt() ?? 15000;
    final double umPercentageKca = (config['um_percentage_kca'] as num?)?.toDouble() ?? 0.192;
    final int minimumUpKca = (config['minimum_up_kca'] as num?)?.toInt() ?? 500000;
    final double bungaKca = (config['bunga_kca'] as num?)?.toDouble() ?? 0.0125;
    final int tempoKca = (config['tempo_kca'] as num?)?.toInt() ?? 4;

    int uangMuka = roundDown(hargaLelang * umPercentageKca, 1000);
    int uangPinjaman = hargaLelang - uangMuka;

    if (uangPinjaman < minimumUpKca) {
      return SimulasiResult(
        skema: SkemaType.kca,
        hargaLelang: hargaLelang,
        uangMuka: uangMuka,
        uangPinjaman: uangPinjaman,
        eligible: false,
        message: 'Uang pinjaman KCA (Rp $uangPinjaman) kurang dari batas minimum (Rp $minimumUpKca). Hanya tersedia untuk pembelian tunai.',
      );
    }

    int bungaTotal = (uangPinjaman * bungaKca * tempoKca).round();
    int totalPelunasan = uangPinjaman + bungaTotal + adminFee;

    return SimulasiResult(
      skema: SkemaType.kca,
      hargaLelang: hargaLelang,
      uangMuka: uangMuka,
      uangPinjaman: uangPinjaman,
      eligible: true,
      tempoKca: tempoKca,
      bungaTotalKca: bungaTotal,
      adminFee: adminFee,
      totalPelunasanKca: totalPelunasan,
    );
  }

  // 3. Skema Krasida
  static SimulasiResult simulasiKrasida({
    required int hargaLelang,
    double? appraisalValue,
    required Map<String, dynamic> config,
    required List<Map<String, dynamic>> tenors,
    required int tenorMonths,
  }) {
    final double umPercentageKrasida = (config['um_percentage_krasida'] as num?)?.toDouble() ?? 0.185;
    final int minimumUpKrasida = (config['minimum_up_krasida'] as num?)?.toInt() ?? 500000;

    int uangMuka = roundDown(hargaLelang * umPercentageKrasida, 1000);
    int uangPinjaman = hargaLelang - uangMuka;

    if (uangPinjaman < minimumUpKrasida) {
      return SimulasiResult(
        skema: SkemaType.krasida,
        hargaLelang: hargaLelang,
        uangMuka: uangMuka,
        uangPinjaman: uangPinjaman,
        eligible: false,
        message: 'Uang pinjaman KRASIDA (Rp $uangPinjaman) kurang dari batas minimum (Rp $minimumUpKrasida). Hanya tersedia untuk pembelian tunai.',
      );
    }

    final tenorObj = tenors.firstWhere(
      (t) => t['months'] == tenorMonths,
      orElse: () => tenors.isNotEmpty ? tenors.first : <String, dynamic>{'months': 12, 'multiplier': 1.15, 'bunga_flat': 0.0},
    );
    final multiplier = (tenorObj['multiplier'] as num).toDouble();

    int angsuran = roundUp((uangPinjaman * multiplier) / tenorMonths, 100);
    int totalBayar = angsuran * tenorMonths;

    // Perbandingan semua tenor
    List<SimulasiTenor> perbandingan = tenors.map((t) {
      final tMonths = t['months'] as int;
      final tMultiplier = (t['multiplier'] as num).toDouble();

      int ang = roundUp((uangPinjaman * tMultiplier) / tMonths, 100);
      int tot = ang * tMonths;

      return SimulasiTenor(
        tenor: tMonths,
        bungaPerBulan: 0.0,
        angsuranPerBulan: ang,
        totalBayar: tot,
        bungaTotal: 0,
        isSelected: tMonths == tenorMonths,
      );
    }).toList();

    return SimulasiResult(
      skema: SkemaType.krasida,
      hargaLelang: hargaLelang,
      uangMuka: uangMuka,
      uangPinjaman: uangPinjaman,
      eligible: true,
      tenor: tenorMonths,
      bungaPerBulan: 0.0,
      angsuranPerBulan: angsuran,
      totalBayar: totalBayar,
      bungaTotalKrasida: totalBayar - uangPinjaman,
      perbandinganTenor: perbandingan,
    );
  }

  // --- Backward Compatibility Delegate (optional, to avoid breaking other files temporarily) ---
  static FinancingCalculation calculate({
    required double stlPrice,
    required double hdlePrice,
    required double loanRatio,
    required double adminFeeFlat,
    required int tenorMonths,
    required double tenorMultiplier,
    required double weightGram,
    required double karat,
    double? fallbackSellingPrice,
  }) {
    final hasGoldInputs = weightGram > 0 && karat > 0;
    final sellingPrice = hasGoldInputs
        ? roundUp((karat / 24) * hdlePrice * weightGram, 10000).toDouble()
        : (fallbackSellingPrice ?? 0);
    final appraisalValue = hasGoldInputs
        ? stlPrice * karat / 24 * weightGram
        : sellingPrice;
    final loanAmount = roundDown(appraisalValue * loanRatio, 100000).toDouble();
    final adminFee = adminFeeFlat;
    final downPayment = (sellingPrice - loanAmount + adminFee).clamp(
      0.0,
      double.infinity,
    );
    final monthlyInstallment = roundUp(
      (loanAmount * tenorMultiplier) / tenorMonths,
      100,
    ).toDouble();

    return FinancingCalculation(
      sellingPrice: sellingPrice,
      appraisalValue: appraisalValue,
      loanAmount: loanAmount,
      downPayment: downPayment,
      adminFee: adminFee,
      tenorMonths: tenorMonths,
      tenorMultiplier: tenorMultiplier,
      monthlyInstallment: monthlyInstallment,
      totalInstallment: monthlyInstallment * tenorMonths,
    );
  }

  static FinancingCalculation calculateItems({
    required List<AuctionItem> items,
    required double stlPrice,
    required double hdlePrice,
    required double loanRatio,
    required double adminFeeFlat,
    required int tenorMonths,
    required double tenorMultiplier,
  }) {
    var sellingPrice = 0.0;
    var appraisalValue = 0.0;

    for (final item in items) {
      final karat = parseKarat(item.karat);
      final hasGoldInputs = item.weightGram > 0 && karat > 0;
      sellingPrice += hasGoldInputs
          ? roundUp((karat / 24) * hdlePrice * item.weightGram, 10000)
          : item.basePrice;
      appraisalValue += hasGoldInputs
          ? stlPrice * karat / 24 * item.weightGram
          : item.basePrice;
    }

    final loanAmount = roundDown(appraisalValue * loanRatio, 100000).toDouble();
    final downPayment = (sellingPrice - loanAmount + adminFeeFlat).clamp(
      0.0,
      double.infinity,
    );
    final monthlyInstallment = roundUp(
      (loanAmount * tenorMultiplier) / tenorMonths,
      100,
    ).toDouble();

    return FinancingCalculation(
      sellingPrice: sellingPrice,
      appraisalValue: appraisalValue,
      loanAmount: loanAmount,
      downPayment: downPayment,
      adminFee: adminFeeFlat,
      tenorMonths: tenorMonths,
      tenorMultiplier: tenorMultiplier,
      monthlyInstallment: monthlyInstallment,
      totalInstallment: monthlyInstallment * tenorMonths,
    );
  }
}
