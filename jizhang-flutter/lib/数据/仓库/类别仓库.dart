import 'package:drift/drift.dart';

import '../数据库.dart';
class CategoryRepository {
  CategoryRepository(this.db);

  final AppDatabase db;

  Future<List<CategoryRow>> list(String type) {
    return (db.select(db.categories)
          ..where((t) => t.type.equals(type))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  Future<List<CategoryRow>> listAll() {
    return (db.select(db.categories)..orderBy([(t) => OrderingTerm(expression: t.id)])).get();
  }

  Future<int> create({
    required String name,
    required String type,
    required String icon,
    int? parentId,
    bool isPreset = false,
    bool isFixed = false,
  }) {
    return db.into(db.categories).insert(CategoriesCompanion.insert(
          name: name,
          icon: icon,
          type: type,
          parentId: Value(parentId),
          isPreset: Value(isPreset),
          isFixed: Value(isFixed),
        ));
  }
}
