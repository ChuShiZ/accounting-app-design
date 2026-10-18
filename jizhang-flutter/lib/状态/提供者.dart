import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../数据/数据库.dart';
import '../数据/首页数据.dart';
import '../数据/仓库/交易仓库.dart';
import '../数据/仓库/报表仓库.dart';
import '../数据/仓库/类别仓库.dart';
import '../数据/仓库/设置仓库.dart';
import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/资产仓库.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(databaseProvider));
});

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(databaseProvider));
});

final accountsProvider = FutureProvider.autoDispose<List<AccountWithBalance>>((ref) {
  return ref.watch(accountRepositoryProvider).listWithBalances();
});

final categoriesProvider = FutureProvider.autoDispose<List<CategoryRow>>((ref) {
  return ref.watch(categoryRepositoryProvider).listAll();
});

final categoryUsageProvider = FutureProvider.autoDispose<Map<int, int>>((ref) async {
  final rows = await ref.watch(databaseProvider).select(ref.watch(databaseProvider).transactions).get();
  final map = <int, int>{};
  for (final row in rows) {
    final id = row.categoryId;
    if (id != null) map[id] = (map[id] ?? 0) + 1;
  }
  return map;
});

final homeProvider = FutureProvider.autoDispose<HomeSnapshot>((ref) {
  return HomeRepository(ref.watch(databaseProvider)).snapshot();
});

final reportPeriodProvider = StateProvider<String>((ref) => '月');
final reportKindProvider = StateProvider<String>((ref) => 'expense');
final reportOffsetProvider = StateProvider<int>((ref) => 0);

final reportDataProvider = FutureProvider.autoDispose<ReportData>((ref) {
  return ref.watch(reportRepositoryProvider).build(
        period: ref.watch(reportPeriodProvider),
        kind: ref.watch(reportKindProvider),
        offset: ref.watch(reportOffsetProvider),
      );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final accountTransactionsProvider =
    FutureProvider.autoDispose.family<List<TransactionRow>, int>((ref, accountId) async {
  final rows = await ref.watch(transactionRepositoryProvider).listRecent(limit: 500);
  return rows
      .where((t) => t.accountId == accountId || t.toAccountId == accountId)
      .take(12)
      .toList();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final defaultAccountProvider = FutureProvider.autoDispose<int?>((ref) async {
  final value = await ref.watch(settingsRepositoryProvider).get('default_account_id');
  return int.tryParse(value ?? '');
});
