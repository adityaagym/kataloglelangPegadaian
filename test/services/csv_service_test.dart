import 'package:flutter_test/flutter_test.dart';
import 'package:katalog_lelang/models/auction_item.dart';
import 'package:katalog_lelang/services/csv_service.dart';

void main() {
  group('CsvService Tests', () {
    test('convertToCsv converts items correctly and escapes special characters', () {
      final items = [
        AuctionItem(
          id: 1,
          creditNumber: 'KRD-001',
          name: 'Cincin Emas, Murni',
          categoryId: 1,
          weightGram: 5.5,
          karat: '22',
          basePrice: 6000000,
          description: 'Cincin emas dengan kata "murni" di deskripsi',
          categoryName: 'Perhiasan Emas',
        ),
        AuctionItem(
          id: 2,
          creditNumber: null,
          name: 'Laptop ASUS',
          categoryId: 2,
          weightGram: 0,
          karat: null,
          basePrice: 4500000,
          description: 'Laptop biasa',
          categoryName: 'Elektronik',
        ),
      ];

      final csvString = CsvService.convertToCsv(items);
      final lines = csvString.split('\n').where((l) => l.isNotEmpty).toList();

      expect(lines.length, 3); // Header + 2 data rows
      expect(lines[0], 'No,No Kredit (opsional),Nama Produk,Kategori,Berat (gram),Karat (opsional),Harga Dasar (opsional),Deskripsi (opsional)');
      
      // Row 1: has comma in name, and quotes in description
      expect(lines[1], '1,KRD-001,"Cincin Emas, Murni",Perhiasan Emas,5.5,22,6000000,"Cincin emas dengan kata ""murni"" di deskripsi"');
      
      // Row 2: has nulls
      expect(lines[2], '2,,Laptop ASUS,Elektronik,0.0,,4500000,Laptop biasa');
    });

    test('parseCsv parses fields correctly with quotes and commas', () {
      const csv = 'No,No Kredit,Nama Produk,Kategori,Berat,Karat,Harga Dasar,Deskripsi\r\n'
          '1,KRD-001,"Cincin Emas, Murni",Perhiasan Emas,5.5,22,6000000,"Cincin emas ""murni"""\r\n'
          '2,,Laptop ASUS,Elektronik,0,,4500000,Laptop biasa';

      final result = CsvService.parseCsv(csv);

      expect(result.length, 3);
      expect(result[0], ['No', 'No Kredit', 'Nama Produk', 'Kategori', 'Berat', 'Karat', 'Harga Dasar', 'Deskripsi']);
      expect(result[1], ['1', 'KRD-001', 'Cincin Emas, Murni', 'Perhiasan Emas', '5.5', '22', '6000000', 'Cincin emas "murni"']);
      expect(result[2], ['2', '', 'Laptop ASUS', 'Elektronik', '0', '', '4500000', 'Laptop biasa']);
    });
  });
}
