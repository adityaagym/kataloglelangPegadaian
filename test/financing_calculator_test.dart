import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/services/financing_calculator.dart';

void main() {
  group('FinancingCalculator Simulasi Tests', () {
    final mockConfig = {
      'admin_fee_flat': 70000.0,
      'stl_price': 502894.0,
      'tempo_kca': 4,
    };

    final List<Map<String, dynamic>> mockTenors = [
      {'months': 6, 'multiplier': 1.075, 'is_active': 1},
      {'months': 12, 'multiplier': 1.150, 'is_active': 1},
    ];

    test('simulasiKca calculates correct loan amount and DP for gold item under 20.1M bracket', () {
      // Setup gold item specs: weight = 10g, karat = 24K, hdle = 550,000
      // Harga Jual (hargaLelang) = roundUp(550,000 * 10 * (24/24), 10000) = 5,500,000
      // Appraisal Value = 502,894 * 10 * (24/24) = 5,028,940
      // Appraisal Value < 20,100,000 -> Loan Ratio = 92% (0.92)
      // Loan Amount (Uang Pinjaman) = roundDown(5,028,940 * 0.92, 100000) = 4,600,000
      // Uang Muka (DP) = Harga Jual - Loan Amount = 5,500,000 - 4,600,000 = 900,000
      // Admin Fee = 70,000
      // Total Pelunasan = 4,600,000 + 70,000 = 4,670,000
      
      const hargaLelang = 5500000;
      const appraisalValue = 5028940.0;

      final result = FinancingCalculator.simulasiKca(
        hargaLelang: hargaLelang,
        appraisalValue: appraisalValue,
        config: mockConfig,
      );

      expect(result.eligible, isTrue);
      expect(result.uangPinjaman, 4620000);
      expect(result.uangMuka, 950000);
      expect(result.tempoKca, 4);
      expect(result.adminFee, 70000);
      expect(result.totalPelunasanKca, 4851000);
    });

    test('simulasiKca calculates correct loan ratio (93%) for low value bracket (<550k)', () {
      // Appraisal Value = 500,000 -> < 550,000 -> Loan Ratio = 93% (0.93)
      // Loan Amount = roundDown(500,000 * 0.93, 10000) = roundDown(465,000, 10000) = 460,000
      const hargaLelang = 600000;
      const appraisalValue = 500000.0;

      final result = FinancingCalculator.simulasiKca(
        hargaLelang: hargaLelang,
        appraisalValue: appraisalValue,
        config: mockConfig,
      );

      expect(result.uangPinjaman, 460000);
    });

    test('simulasiKrasida calculates correct loan amount, DP, and installments with 95% ratio', () {
      // Setup gold item specs: weight = 10g, karat = 24K, hdle = 550,000
      // Harga Jual (hargaLelang) = 5,500,000
      // Appraisal Value = 502,894 * 10 = 5,028,940
      // Krasida Loan Ratio = 95% (0.95)
      // Loan Amount (Uang Pinjaman) = roundDown(5,028,940 * 0.95, 100000) = 4,700,000
      // Uang Muka (DP) = Harga Jual - Loan Amount + Admin Fee = 5,500,000 - 4,700,000 + 70,000 = 870,000
      // Tenor = 6 months (multiplier = 1.075)
      // Installment = roundUp(4,700,000 * 1.075 / 6, 100) = roundUp(842,083.33, 100) = 842,100
      // Total Bayar = 842,100 * 6 = 5,052,600

      const hargaLelang = 5500000;
      const appraisalValue = 5028940.0;

      final result = FinancingCalculator.simulasiKrasida(
        hargaLelang: hargaLelang,
        appraisalValue: appraisalValue,
        config: mockConfig,
        tenors: mockTenors,
        tenorMonths: 6,
      );

      expect(result.eligible, isTrue);
      expect(result.uangPinjaman, 4700000);
      expect(result.uangMuka, 870000);
      expect(result.angsuranPerBulan, 842100);
      expect(result.totalBayar, 5052600);
    });
  });
}
