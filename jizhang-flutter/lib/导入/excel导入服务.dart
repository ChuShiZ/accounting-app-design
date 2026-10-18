import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/类别仓库.dart';
import '../数据/仓库/交易仓库.dart';
import 'excel分类映射.dart';
import 'excel解析.dart';

class ExcelImportResult {
  const ExcelImportResult({
    required this.success,
    required this.updated,
    required this.duplicates,
    required this.skipped,
    required this.errors,
    required this.categoriesCreated,
    required this.totalRows,
  });

  final int success;
  final int updated;
  final int duplicates;
  final int skipped;
  final List<ExcelRowError> errors;
  final int categoriesCreated;
  final int totalRows;

  int get processed => success + updated + duplicates + skipped;
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

    String targetNameFor(ExcelParsedRow row) {
      final mapped = ExcelCategoryMapper.targetName(row.type, row.category, note: row.note);
      if (mapped == null) return row.category;
      // 预设目标分类被用户删掉时回退到【其他】，不重建一个错位的一级分类。
      return categoryMap.containsKey('${row.type}|$mapped') ? mapped : '其他';
    }

    final needed = <String, ({String type, String name})>{};
    for (final row in rows) {
      final targetName = targetNameFor(row);
      final key = '${row.type}|$targetName';
      if (categoryMap.containsKey(key)) continue;
      needed.putIfAbsent(key, () => (type: row.type, name: targetName));
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
    final existingByKey = <String, TransactionRow>{};
    final keys = <String>{};
    for (final transaction in existingTransactions) {
      final key = _baseKey(
        transaction.occurredAt,
        transaction.type,
        transaction.amount,
        transaction.note ?? '',
        transaction.accountId,
      );
      existingByKey.putIfAbsent(key, () => transaction);
      keys.add(key);
    }

    var success = 0;
    var updated = 0;
    var duplicates = 0;
    final errors = <ExcelRowError>[];
    final toInsert = <({ExcelParsedRow row, int accountId, int categoryId})>[];
    final toUpdate = <({int transactionId, int categoryId})>[];
    final handledExisting = <int>{};
    for (final row in rows) {
      final targetAccountId = row.accountName == null ? accountId : (accountByName[row.accountName] ?? accountId);
      final targetName = targetNameFor(row);
      final categoryId = categoryMap['${row.type}|$targetName'];
      if (categoryId == null) {
        errors.add(ExcelRowError(row.rowNumber, '类别创建失败'));
        continue;
      }
      final baseKey = _baseKey(
        row.occurredAt.millisecondsSinceEpoch,
        row.type,
        row.amount,
        row.note,
        targetAccountId,
      );
      final existing = existingByKey[baseKey];
      if (existing != null) {
        if (!handledExisting.add(existing.id)) {
          duplicates++;
          continue;
        }
        if (existing.categoryId == categoryId) {
          duplicates++;
        } else {
          toUpdate.add((transactionId: existing.id, categoryId: categoryId));
          updated++;
        }
        continue;
      }
      if (!keys.add(baseKey)) {
        duplicates++;
        continue;
      }
      toInsert.add((row: row, accountId: targetAccountId, categoryId: categoryId));
    }

    if (toUpdate.isNotEmpty || toInsert.isNotEmpty) {
      await db.transaction(() async {
        for (final update in toUpdate) {
          await transactionRepository.updateCategory(update.transactionId, update.categoryId);
        }
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
      updated: updated,
      duplicates: duplicates,
      skipped: parseErrors.length + errors.length,
      errors: [...parseErrors, ...errors],
      categoriesCreated: categoriesCreated,
      totalRows: rows.length + parseErrors.length,
    );
  }

  String _baseKey(int occurredAt, String type, int amount, String note, int accountId) {
    return '$occurredAt|$type|$amount|${note.trim()}|$accountId';
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
