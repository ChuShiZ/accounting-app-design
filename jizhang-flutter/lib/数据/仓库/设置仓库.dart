import '../数据库.dart';

class SettingsRepository {
  SettingsRepository(this.db);

  final AppDatabase db;

  Future<String?> get(String key) async {
    final row = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) {
    return db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<void> remove(String key) {
    return (db.delete(db.settings)..where((t) => t.key.equals(key))).go();
  }
}
