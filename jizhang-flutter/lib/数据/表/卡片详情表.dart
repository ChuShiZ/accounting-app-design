import 'package:drift/drift.dart';

import '账户表.dart';
import '类别表.dart';

@DataClassName('CardDetailRow')
class CardDetails extends Table {
  @override
  String get tableName => 'card_detail';

  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get defaultCategoryId => integer().nullable().references(Categories, #id)();
  IntColumn get expireAt => integer().nullable()();
  TextColumn get cardTail => text().nullable()();
  IntColumn get creditLimit => integer().nullable()();
  IntColumn get billingDay => integer().nullable()();
  IntColumn get repaymentDay => integer().nullable()();

  @override
  Set<Column> get primaryKey => {accountId};
}
