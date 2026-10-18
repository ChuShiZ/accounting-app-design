import 'package:drift/drift.dart';

import '账户表.dart';

@DataClassName('DepositDetailRow')
class DepositDetails extends Table {
  @override
  String get tableName => 'deposit_detail';

  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get certificateNo => text().nullable()();
  IntColumn get principal => integer()();
  IntColumn get rateBp => integer()();
  IntColumn get termMonths => integer()();
  IntColumn get startAt => integer()();
  IntColumn get maturityAt => integer()();
  IntColumn get closedAt => integer().nullable()();
  TextColumn get closeType => text().nullable()();
  IntColumn get actualInterest => integer().nullable()();

  @override
  Set<Column> get primaryKey => {accountId};
}
