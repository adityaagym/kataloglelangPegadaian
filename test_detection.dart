import 'dart:io';
import 'package:excel/excel.dart';

void main() async {
  final file = File(r'd:\KP_Pegadaian\KatalogPegadaianAG\RPT_rptDaftarJatuhTempoSyariah_1781918028653.xlsx');
  if (!file.existsSync()) {
    stdout.writeln("File not found");
    return;
  }
  final bytes = await file.readAsBytes();
  final excel = Excel.decodeBytes(bytes);
  
  for (final table in excel.tables.keys) {
    stdout.writeln('Sheet: $table');
    final sheet = excel.tables[table]!;
    for (var i = 0; i < (sheet.maxRows < 15 ? sheet.maxRows : 15); i++) {
      final row = sheet.rows[i];
      final rowString = row.map((e) {
        final value = e?.value;
        if (value == null) return '';
        return value.toString();
      }).join(' | ').replaceAll('\n', ' ');
      stdout.writeln('RowString $i: "$rowString"');
    }
  }
}
