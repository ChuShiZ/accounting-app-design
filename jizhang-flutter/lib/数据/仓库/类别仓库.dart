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

  Future<CategoryRow?> findById(int id) {
    return (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<CategoryRow>> listChildren(int parentId) {
    return (db.select(db.categories)
          ..where((t) => t.parentId.equals(parentId))
          ..orderBy([(t) => OrderingTerm(expression: t.id)]))
        .get();
  }

  Future<bool> hasChildren(int id) async {
    final rows = await (db.select(db.categories)..where((t) => t.parentId.equals(id))).get();
    return rows.isNotEmpty;
  }

  Future<void> setParent(int id, int? parentId) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(parentId: Value(parentId)),
    );
  }

  Future<CategoryRow?> findByName(String name, String type) {
    return (db.select(db.categories)
          ..where((t) => t.name.equals(name) & t.type.equals(type)))
        .getSingleOrNull();
  }

  Future<int> usageCount(int id) async {
    final rows = await (db.select(db.transactions)..where((t) => t.categoryId.equals(id))).get();
    return rows.length;
  }

  Future<int> usageCountWithChildren(int id) async {
    final children = await listChildren(id);
    final ids = <int>[id, ...children.map((c) => c.id)];
    final rows = await (db.select(db.transactions)..where((t) => t.categoryId.isIn(ids))).get();
    return rows.length;
  }

  Future<bool> nameExists(String name, String type, {int? excludeId}) async {
    final rows = await (db.select(db.categories)
          ..where((t) => t.name.equals(name) & t.type.equals(type)))
        .get();
    return rows.any((row) => row.id != excludeId);
  }

  Future<void> updateCategory(
    int id, {
    required String name,
    required String icon,
    required String type,
    int? parentId,
  }) {
    return (db.update(db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        type: Value(type),
        parentId: Value(parentId),
      ),
    );
  }

  /// 删除已使用类别时归入同类型的【其他】；默认类别同时清空。
  /// 一级分类下还有子分类时不允许直接删除，避免误删整棵分类树。
  Future<void> deleteCategory(int id) async {
    final category = await (db.select(db.categories)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (category == null) return;
    if (category.isFixed) throw StateError('固定类别不可删除');
    if (await hasChildren(id)) throw StateError('请先删除或移动子分类');
    final fallback = await findByName('其他', category.type);
    await db.transaction(() async {
      if (fallback != null) {
        await (db.update(db.transactions)..where((t) => t.categoryId.equals(id))).write(
          TransactionsCompanion(categoryId: Value(fallback.id)),
        );
      } else {
        await (db.update(db.transactions)..where((t) => t.categoryId.equals(id))).write(
          const TransactionsCompanion(categoryId: Value(null)),
        );
      }
      await (db.update(db.cardDetails)..where((t) => t.defaultCategoryId.equals(id))).write(
        const CardDetailsCompanion(defaultCategoryId: Value(null)),
      );
      await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
    });
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
