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
  double sellingPrice;
  double appraisalValue;
  double loanAmount;
  double downPayment;
  double adminFee;
  final int tenorMonths;
  final double tenorMultiplier;
  double monthlyInstallment;
  double totalInstallment;  

  FinancingCalculation({
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

  /// Hitung harga jual barang emas (HDLE) berdasarkan harga per gram, berat, dan karat.
  /// Hasil dibulatkan ke atas kelipatan 10.000.
  static int hitungHargaEmas({
    required double hdlePrice,
    required double weightGram,
    required double karatVal,
  }) {
    if (weightGram <= 0 || karatVal <= 0) return 0;
    final raw = hdlePrice * (karatVal / 24.0) * weightGram;
    return roundUp(raw, 10000);
  }

  /// Hitung nilai taksiran barang emas (STL) berdasarkan harga taksiran per gram, berat, dan karat.
  /// Digunakan sebagai `appraisalValue` pada simulasi KCA dan Krasida.
  static double hitungNilaiTaksiran({
    required double stlPrice,
    required double weightGram,
    required double karatVal,
  }) {
    if (weightGram <= 0 || karatVal <= 0) return 0;
    return stlPrice * (karatVal / 24.0) * weightGram;
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
    final int minimumUpKca = (config['minimum_up_kca'] as num?)?.toInt() ?? 500000;
    final double bungaKca = (config['bunga_kca'] as num?)?.toDouble() ?? 0.0125;
    final int tempoKca = (config['tempo_kca'] as num?)?.toInt() ?? 4;

    double appVal = appraisalValue ?? hargaLelang.toDouble();
    double rasioKca;
    if (appVal < 550000) {
      rasioKca = 0.93;
    } else if (appVal < 20100000) {
      rasioKca = 0.92;
    } else {
      rasioKca = 0.93;
    }

    int uangPinjaman = roundDown(appVal * rasioKca, 10000);
    int uangMuka = hargaLelang - uangPinjaman + adminFee;

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
    int totalPelunasan = uangPinjaman + bungaTotal;

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
    final int minimumUpKrasida = (config['minimum_up_krasida'] as num?)?.toInt() ?? 500000;
    final int adminFee = (config['admin_fee_flat'] as num?)?.toInt() ?? 15000;

    int uangPinjaman = roundDown((appraisalValue ?? hargaLelang.toDouble()) * 0.95, 100000);
    int uangMuka = hargaLelang - uangPinjaman + adminFee;

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

}
