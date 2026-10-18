import 'package:drift/drift.dart';

import '账户表.dart';

@DataClassName('LoanDetailRow')
class LoanDetails extends Table {
  @override
  String get tableName => 'loan_detail';

  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get kind => text()();
  IntColumn get originalPrincipal => integer()();
  IntColumn get rateBp => integer()();
  IntColumn get termMonths => integer()();
  IntColumn get startAt => integer()();
  IntColumn get nextDueAt => integer()();
  IntColumn get perAmount => integer().nullable()();
  TextColumn get repaymentMethod => text()();

  @override
  Set<Column> get primaryKey => {accountId};
}
