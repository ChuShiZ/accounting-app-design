import 'dart:typed_data';

import 'package:excel/excel.dart';

class ExcelParsedRow {
  const ExcelParsedRow({
    required this.rowNumber,
    required this.occurredAt,
    required this.type,
    required this.category,
    required this.note,
    required this.amount,
    this.accountName,
  });

  final int rowNumber;
  final DateTime occurredAt;
  final String type;
  final String category;
  final String note;
  final int amount;
  final String? accountName;
}

class ExcelRowError {
  const ExcelRowError(this.rowNumber, this.message);

  final int rowNumber;
  final String message;
}

class ExcelParseResult {
  const ExcelParseResult({
    required this.rows,
    required this.errors,
    required this.totalRows,
    required this.headers,
  });

  final List<ExcelParsedRow> rows;
  final List<ExcelRowError> errors;
  final int totalRows;
  final List<String> headers;

  int get skipped => errors.length;
}

class ExcelParser {
  static const dateAliases = ['账单日期', '日期', '交易日期', '交易时间', '时间'];
  static const typeAliases = ['收支类型', '类型', '收支'];
  static const categoryAliases = ['记账分类', '分类', '类别', '分类筛选'];
  static const amountAliases = ['金额', '金额（元）', '金额(元)'];
  static const noteAliases = ['备注', '说明'];
  static const accountAliases = ['账户', '账户名称', '支付账户'];

  static ExcelParseResult parse(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw const FormatException('Excel 中没有工作表');
    }
    final table = workbook.tables.entries
        .map((entry) => entry.value)
        .firstWhere((sheet) => sheet.rows.isNotEmpty, orElse: () => workbook.tables.values.first);
    final rows = table.rows;
    if (rows.isEmpty) throw const FormatException('Excel 中没有数据');

    var headerIndex = -1;
    List<String> header = const [];
    for (var i = 0; i < rows.length; i++) {
      final values = rows[i].map(_cellText).toList();
      if (values.where((value) => value.trim().isNotEmpty).length >= 2) {
        headerIndex = i;
        header = values.map((value) => value.trim()).toList();
        break;
      }
    }
    if (headerIndex < 0) throw const FormatException('没有找到表头');

    final dateColumn = _findColumn(header, dateAliases);
    final typeColumn = _findColumn(header, typeAliases);
    final categoryColumn = _findColumn(header, categoryAliases);
    final amountColumn = _findColumn(header, amountAliases);
    final noteColumn = _findColumn(header, noteAliases);
    final accountColumn = _findColumn(header, accountAliases);
    if (dateColumn < 0) throw const FormatException('缺少日期列');
    if (typeColumn < 0) throw const FormatException('缺少收支类型列');
    if (amountColumn < 0) throw const FormatException('缺少金额列');

    final parsed = <ExcelParsedRow>[];
    final errors = <ExcelRowError>[];
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => _cellText(cell).trim().isEmpty)) continue;
      final rowNumber = i + 1;
      final date = _cellDate(row, dateColumn);
      final type = _normalizeType(_cellTextAt(row, typeColumn));
      final amount = _parseAmount(_cellTextAt(row, amountColumn));
      if (date == null) {
        errors.add(ExcelRowError(rowNumber, '日期格式不正确'));
        continue;
      }
      if (type == null) {
        errors.add(ExcelRowError(rowNumber, '收支类型不是收入/支出'));
        continue;
      }
      if (amount == null || amount <= 0) {
        errors.add(ExcelRowError(rowNumber, '金额无效'));
        continue;
      }
      final category = (categoryColumn < 0 ? '' : _cellTextAt(row, categoryColumn)).trim();
      final note = (noteColumn < 0 ? '' : _cellTextAt(row, noteColumn)).trim();
      final accountName = (accountColumn < 0 ? '' : _cellTextAt(row, accountColumn)).trim();
      parsed.add(ExcelParsedRow(
        rowNumber: rowNumber,
        occurredAt: date,
        type: type,
        category: category.isEmpty ? '其他' : category,
        note: note,
        amount: amount,
        accountName: accountName.isEmpty ? null : accountName,
      ));
    }
    return ExcelParseResult(rows: parsed, errors: errors, totalRows: rows.length - headerIndex - 1, headers: header);
  }

  static int _findColumn(List<String> headers, List<String> aliases) {
    for (var i = 0; i < headers.length; i++) {
      final normalized = headers[i].replaceAll(RegExp(r'\s+'), '').toLowerCase();
      if (aliases.any((alias) => normalized == alias.replaceAll(RegExp(r'\s+'), '').toLowerCase())) {
        return i;
      }
    }
    return -1;
  }

  static String _cellTextAt(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) return '';
    return _cellText(row[index]);
  }

  static String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) return value.asDateTimeLocal().toIso8601String();
    if (value is DateTimeCellValue) return value.asDateTimeLocal().toIso8601String();
    if (value is TimeCellValue) return value.toString();
    return value.toString();
  }

  static DateTime? _cellDate(List<Data?> row, int index) {
    if (index >= row.length) return null;
    final value = row[index]?.value;
    if (value is DateCellValue) return value.asDateTimeLocal();
    if (value is DateTimeCellValue) return value.asDateTimeLocal();
    final text = _cellText(row[index]).trim();
    if (text.isEmpty) return null;
    final normalized = text
        .replaceAll('年', '-')
        .replaceAll('月', '-')
        .replaceAll('日', '')
        .replaceAll('/', '-');
    return DateTime.tryParse(normalized);
  }

  static String? _normalizeType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == '收入' || normalized == 'income') return 'income';
    if (normalized == '支出' || normalized == 'expense') return 'expense';
    return null;
  }

  static int? _parseAmount(String value) {
    final cleaned = value
        .replaceAll(',', '')
        .replaceAll('，', '')
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll('元', '')
        .trim();
    if (cleaned.isEmpty) return null;
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }
}
