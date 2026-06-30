import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/utils/app_colors.dart';

void main() {
  test('React migration theme tokens are configured', () {
    expect(AppColors.primary.toARGB32(), 0xFF00AA13);
    expect(AppColors.primaryDark.toARGB32(), 0xFF006838);
    expect(AppColors.background.toARGB32(), 0xFFE8F5E9);
    expect(AppColors.categoryBadgeText('Elektronik').toARGB32(), 0xFF4338CA);
  });
}
