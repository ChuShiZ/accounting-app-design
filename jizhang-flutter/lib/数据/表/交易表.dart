import 'package:drift/drift.dart';

import '账户表.dart';
import '类别表.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  @override
  String get tableName => 'transaction';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  IntColumn get occurredAt => integer()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  IntColumn get toAccountId => integer().nullable().references(Accounts, #id)();
  TextColumn get groupId => text().nullable()();
  TextColumn get groupKind => text().nullable()();
  BoolColumn get locked => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().nullable()();
}
