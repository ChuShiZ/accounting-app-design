import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  @override
  String get tableName => 'category';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get type => text()();
  IntColumn get parentId => integer().nullable()();
  BoolColumn get isPreset => boolean().withDefault(const Constant(false))();
  BoolColumn get isFixed => boolean().withDefault(const Constant(false))();
}
