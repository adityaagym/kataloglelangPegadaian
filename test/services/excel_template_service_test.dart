import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/models/category.dart';
import 'package:katalog_lelang/services/excel_template_service.dart';

void main() {
  test('generateTemplateBytes creates sheet with headers and category rows', () {
    final categories = [
      Category(id: 1, name: 'Perhiasan Emas'),
      Category(id: 2, name: 'Elektronik'),
    ];

    final bytes = ExcelTemplateService.generateTemplateBytes(categories);

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(100));
  });
}
