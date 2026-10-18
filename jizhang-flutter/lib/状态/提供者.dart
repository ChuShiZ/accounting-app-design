import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../数据/数据库.dart';
import '../数据/仓库/交易仓库.dart';
import '../数据/仓库/报表仓库.dart';
import '../数据/仓库/类别仓库.dart';
import '../数据/仓库/设置仓库.dart';
import '../数据/仓库/账户仓库.dart';

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

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
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
