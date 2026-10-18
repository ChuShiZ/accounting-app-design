import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '表/账户表.dart';
import '表/交易表.dart';
import '表/类别表.dart';
import '表/卡片详情表.dart';
import '表/存单详情表.dart';
import '表/贷款详情表.dart';
import '表/周期规则表.dart';
import '表/设置表.dart';

part '数据库.g.dart';

@DriftDatabase(
  tables: [
    Accounts,
    Transactions,
    Categories,
    CardDetails,
    DepositDetails,
    LoanDetails,
    RecurringRules,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.open() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.reportable);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'jizhang.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
