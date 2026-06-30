import '../models/auction_item.dart';

class CsvService {
  static String convertToCsv(List<AuctionItem> items) {
    final sb = StringBuffer();
    // Headers matching ExcelTemplateService template
    sb.writeln('No,No Kredit (opsional),Nama Produk,Kategori,Berat (gram),Karat (opsional),Harga Dasar (opsional),Deskripsi (opsional)');
    
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final no = (i + 1).toString();
      final creditNum = item.creditNumber ?? '';
      final name = item.name;
      final category = item.categoryName ?? '';
      final weight = item.weightGram.toString();
      final karat = item.karat ?? '';
      final basePrice = item.basePrice.toStringAsFixed(0);
      final description = item.description ?? '';
      
      sb.writeln([
        _escapeCsv(no),
        _escapeCsv(creditNum),
        _escapeCsv(name),
        _escapeCsv(category),
        _escapeCsv(weight),
        _escapeCsv(karat),
        _escapeCsv(basePrice),
        _escapeCsv(description),
      ].join(','));
    }
    return sb.toString();
  }

  static List<List<String>> parseCsv(String csvText) {
    final List<List<String>> rows = [];
    List<String> currentRow = [];
    final StringBuffer currentField = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < csvText.length; i++) {
      final char = csvText[i];
      
      if (inQuotes) {
        if (char == '"') {
          // Check if next char is also a double quote (escaped quote "")
          if (i + 1 < csvText.length && csvText[i + 1] == '"') {
            currentField.write('"');
            i++; // skip the second quote
          } else {
            inQuotes = false;
          }
        } else {
          currentField.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentField.toString());
          currentField.clear();
        } else if (char == '\n') {
          currentRow.add(currentField.toString());
          currentField.clear();
          rows.add(currentRow);
          currentRow = [];
        } else if (char == '\r') {
          // skip carriage return
        } else {
          currentField.write(char);
        }
      }
    }
    
    // Handle the last field/row if the text doesn't end with a newline
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(currentRow);
    }
    
    return rows;
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
