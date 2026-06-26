import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/services/financing_calculator.dart';

void main() {
  test('matches Excel installment rounding for KRASIDA tenor 6', () {
    final result = FinancingCalculator.calculate(
      stlPrice: 502894,
      hdlePrice: 550000,
      loanRatio: 0.95,
      adminFeeFlat: 50000,
      tenorMonths: 6,
      tenorMultiplier: 1.075,
      weightGram: 0,
      karat: 0,
      fallbackSellingPrice: 1400000,
    );

    expect(result.loanAmount, 1300000);
    expect(result.monthlyInstallment, 233000);
  });

  test('rounds the known Excel loan amount example to 250900', () {
    final installment = FinancingCalculator.roundUp((1400000 * 1.075) / 6, -2);

    expect(installment, 250900);
  });
}
