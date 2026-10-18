import 'package:drift/drift.dart';

@DataClassName('Account')
class Accounts extends Table {
  @override
  String get tableName => 'account';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get institution => text().nullable()();
  TextColumn get icon => text()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().nullable()();
}
