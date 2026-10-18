import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/类别仓库.dart';
import '../数据/仓库/交易仓库.dart';
import 'excel解析.dart';

class ExcelImportResult {
  const ExcelImportResult({
    required this.success,
    required this.duplicates,
    required this.skipped,
    required this.errors,
    required this.categoriesCreated,
    required this.totalRows,
  });

  final int success;
  final int duplicates;
  final int skipped;
  final List<ExcelRowError> errors;
  final int categoriesCreated;
  final int totalRows;

  int get processed => success + duplicates + skipped;
}

class ExcelImportService {
  ExcelImportService(this.db);

  final AppDatabase db;

  Future<ExcelImportResult> importRows({
    required int accountId,
    required List<ExcelParsedRow> rows,
    List<ExcelRowError> parseErrors = const [],
  }) async {
    final accountRepository = AccountRepository(db);
    final account = await accountRepository.findById(accountId);
    if (account == null) throw StateError('导入账户不存在');
    final accounts = await accountRepository.listAccounts();
    final accountByName = {for (final item in accounts) item.name: item.id};

    final categoryRepository = CategoryRepository(db);
    final existingCategories = await categoryRepository.listAll();
    final categoryMap = <String, int>{
      for (final category in existingCategories) '${category.type}|${category.name}': category.id,
    };
    var categoriesCreated = 0;
    final needed = <String, ({String type, String name})>{};
    for (final row in rows) {
      final key = '${row.type}|${row.category}';
      if (categoryMap.containsKey(key)) continue;
      needed.putIfAbsent(key, () => (type: row.type, name: row.category));
    }
    for (final entry in needed.values) {
      final id = await categoryRepository.create(
        name: entry.name,
        type: entry.type,
        icon: _iconForCategory(entry.name),
      );
      categoryMap['${entry.type}|${entry.name}'] = id;
      categoriesCreated++;
    }

    final transactionRepository = TransactionRepository(db);
    final existingTransactions = await db.select(db.transactions).get();
    final keys = <String>{
      for (final transaction in existingTransactions)
        _key(
          transaction.occurredAt,
          transaction.type,
          transaction.amount,
          transaction.categoryId ?? -1,
          transaction.note ?? '',
          transaction.accountId,
        ),
    };

    var success = 0;
    var duplicates = 0;
    final errors = <ExcelRowError>[];
    final toInsert = <({ExcelParsedRow row, int accountId, int categoryId})>[];
    for (final row in rows) {
      final targetAccountId = row.accountName == null ? accountId : (accountByName[row.accountName] ?? accountId);
      final categoryId = categoryMap['${row.type}|${row.category}'];
      if (categoryId == null) {
        errors.add(ExcelRowError(row.rowNumber, '类别创建失败'));
        continue;
      }
      final key = _key(
        row.occurredAt.millisecondsSinceEpoch,
        row.type,
        row.amount,
        categoryId,
        row.note,
        targetAccountId,
      );
      if (!keys.add(key)) {
        duplicates++;
        continue;
      }
      toInsert.add((row: row, accountId: targetAccountId, categoryId: categoryId));
    }

    if (toInsert.isNotEmpty) {
      await db.transaction(() async {
        for (final item in toInsert) {
          final row = item.row;
          final note = row.note.isEmpty ? null : row.note;
          if (row.type == 'income') {
            await transactionRepository.addIncome(
              amount: row.amount,
              accountId: item.accountId,
              categoryId: item.categoryId,
              occurredAt: row.occurredAt,
              note: note,
            );
          } else {
            await transactionRepository.addExpense(
              amount: row.amount,
              accountId: item.accountId,
              categoryId: item.categoryId,
              occurredAt: row.occurredAt,
              note: note,
            );
          }
          success++;
        }
      });
    }

    return ExcelImportResult(
      success: success,
      duplicates: duplicates,
      skipped: parseErrors.length + errors.length,
      errors: [...parseErrors, ...errors],
      categoriesCreated: categoriesCreated,
      totalRows: rows.length + parseErrors.length,
    );
  }

  String _key(int occurredAt, String type, int amount, int categoryId, String note, int accountId) {
    return '$occurredAt|$type|$amount|$categoryId|${note.trim()}|$accountId';
  }

  String _iconForCategory(String name) {
    const map = {
      '餐饮': 'food',
      '交通': 'car',
      '购物': 'cart',
      '居家': 'building',
      '娱乐': 'fun',
      '医疗': 'medical',
      '教育': 'education',
      '通讯': 'phone',
      '房贷': 'mortgage',
      '车贷': 'car',
      '贷款': 'loan',
      '储值卡充值': 'card',
      '工资': 'salary',
      '奖金': 'gift',
      '利息': 'interest',
      '赠送': 'gift',
      '理财': 'invest',
    };
    return map[name] ?? 'other';
  }
}
