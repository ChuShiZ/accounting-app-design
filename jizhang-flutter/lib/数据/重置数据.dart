import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '数据库.dart';
import '种子数据.dart';

/// 清空本机记账数据，并恢复默认账户和预设两级分类。
///
/// 不会删除 WebDAV 配置、云端备份和更新相关设置。
class DataResetService {
  DataResetService(this.db);

  final AppDatabase db;

  Future<void> resetAll({bool clearFiles = true}) async {
    await db.transaction(() async {
      await db.delete(db.cardDetails).go();
      await db.delete(db.depositDetails).go();
      await db.delete(db.loanDetails).go();
      await db.delete(db.recurringRules).go();
      await db.delete(db.transactions).go();
      await db.delete(db.accounts).go();
      await db.delete(db.categories).go();
      await (db.delete(db.settings)
            ..where((t) => t.key.isIn(const ['category_tree_version', 'default_account_id'])))
          .go();
    });
    if (clearFiles) {
      await _clearLocalFiles();
    }
    await seedPresetData(db);
  }

  Future<void> _clearLocalFiles() async {
    final docs = await getApplicationDocumentsDirectory();
    final pending = File(p.join(docs.path, 'pending_restore.zip'));
    if (await pending.exists()) await pending.delete();
    final beforeRestore = File(p.join(docs.path, 'jizhang.before-restore.sqlite'));
    if (await beforeRestore.exists()) await beforeRestore.delete();
    try {
      final receipts = Directory(p.join(docs.path, 'receipts'));
      if (await receipts.exists()) await receipts.delete(recursive: true);
    } catch (_) {
      // 图片清理失败不阻断数据库重置；数据库和待恢复文件已经处理。
    }
  }
}
