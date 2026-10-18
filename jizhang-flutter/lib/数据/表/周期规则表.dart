import 'package:drift/drift.dart';

import '账户表.dart';
import '类别表.dart';

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  @override
  String get tableName => 'recurring_rule';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  TextColumn get frequency => text()();
  IntColumn get nextDueAt => integer()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get note => text().nullable()();
}
