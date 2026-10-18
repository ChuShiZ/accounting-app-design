import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../数据/数据库.dart';
import '../数据/仓库/设置仓库.dart';
import 'webdav客户端.dart';
import '密钥存储.dart';

class WebDavConfig {
  WebDavConfig({
    required String baseUrl,
    required this.username,
    required this.password,
    String folder = '记账备份',
    this.includeImages = false,
  })  : baseUrl = baseUrl.trim(),
        folder = normalizeFolder(folder);

  final String baseUrl;
  final String username;
  final String password;
  final String folder;
  final bool includeImages;

  List<String> get folderSegments => folder.split('/').where((part) => part.isNotEmpty).toList();

  static String normalizeFolder(String value) {
    final cleaned = value.trim().replaceAll('\\', '/').replaceAll(RegExp(r'^/+|/+$'), '');
    if (cleaned.isEmpty) return '记账备份';
    if (cleaned == '.' || cleaned == '..' || cleaned.contains('..')) {
      throw ArgumentError('备份目录不能包含 ..');
    }
    return cleaned;
  }
}

class RemoteBackup {
  const RemoteBackup({
    required this.name,
    required this.at,
    required this.sizeLabel,
    required this.sizeBytes,
  });

  final String name;
  final String at;
  final String sizeLabel;
  final int sizeBytes;
}

class BackupService {
  BackupService(this.db, this.config);

  final AppDatabase db;
  final WebDavConfig config;

  WebDavClient get _client => WebDavClient(
        baseUrl: config.baseUrl,
        username: config.username,
        password: config.password,
      );

  Future<void> testConnection() => _client.testConnection();

  Future<RemoteBackup> createBackup() async {
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final dbFile = await appDatabaseFile();
    if (!await dbFile.exists()) {
      throw StateError('本地数据库文件不存在');
    }
    final archive = Archive();
    final dbBytes = await dbFile.readAsBytes();
    archive.addFile(ArchiveFile('jizhang.sqlite', dbBytes.length, dbBytes));

    final docs = await getApplicationDocumentsDirectory();
    final images = Directory(p.join(docs.path, 'receipts'));
    if (config.includeImages && await images.exists()) {
      await for (final entity in images.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final relative = p.relative(entity.path, from: docs.path).replaceAll('\\', '/');
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relative, bytes.length, bytes));
      }
    }

    final now = DateTime.now();
    final name = _backupName(now);
    final manifest = jsonEncode({
      'format': 'jizhang-backup-v1',
      'createdAt': now.toIso8601String(),
      'database': 'jizhang.sqlite',
      'images': config.includeImages ? 'receipts/' : null,
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    final zipBytes = ZipEncoder().encode(archive, level: 6)!;

    final client = _client;
    await client.upload(config.folderSegments, name, zipBytes);
    await _prune(client);
    return RemoteBackup(
      name: name,
      at: _formatAt(now),
      sizeLabel: _sizeLabel(zipBytes.length),
      sizeBytes: zipBytes.length,
    );
  }

  Future<List<RemoteBackup>> listBackups() async {
    final entries = await _client.list(config.folderSegments);
    return entries
        .where((entry) => entry.name.startsWith('backup_') && entry.name.toLowerCase().endsWith('.zip'))
        .map((entry) => RemoteBackup(
              name: entry.name,
              at: entry.at,
              sizeLabel: entry.size > 0 ? _sizeLabel(entry.size) : '',
              sizeBytes: entry.size,
            ))
        .toList();
  }

  /// 下载并校验备份，写入待恢复 zip；真正替换数据库在下次启动时执行。
  Future<void> downloadForRestore(RemoteBackup backup) async {
    final bytes = await _client.download(config.folderSegments, backup.name);
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final dbEntry = archive.files.where((file) => file.name == 'jizhang.sqlite').firstOrNull;
    if (dbEntry == null) {
      throw StateError('备份包缺少数据库文件');
    }
    final dbBytes = dbEntry.content;
    if (dbBytes.length < 16 || utf8.decode(dbBytes.sublist(0, 15), allowMalformed: true) != 'SQLite format 3') {
      throw StateError('备份数据库校验失败');
    }
    final docs = await getApplicationDocumentsDirectory();
    await File(p.join(docs.path, 'pending_restore.zip')).writeAsBytes(bytes, flush: true);
  }

  Future<void> _prune(WebDavClient client) async {
    final entries = await client.list(config.folderSegments);
    final backups = entries
        .where((entry) => entry.name.startsWith('backup_') && entry.name.toLowerCase().endsWith('.zip'))
        .toList()
      ..sort((a, b) => b.name.compareTo(a.name));
    for (final entry in backups.skip(5)) {
      await client.delete(config.folderSegments, entry.name);
    }
  }

  String _backupName(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'backup_${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}${two(date.second)}.zip';
  }

  String _formatAt(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return '';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

/// 启动或回到前台时若距上次备份超过设定间隔，且已保存凭据，则自动备份。
Future<RemoteBackup?> maybeAutoBackup(AppDatabase db) {
  final running = _autoBackupTask;
  if (running != null) return running;
  final task = _runAutoBackup(db);
  _autoBackupTask = task;
  return task.whenComplete(() => _autoBackupTask = null);
}

Future<RemoteBackup?>? _autoBackupTask;

Future<RemoteBackup?> _runAutoBackup(AppDatabase db) async {
  try {
    final settings = SettingsRepository(db);
    if (await settings.get('auto_backup') == 'false') return null;
    final url = await settings.get('webdav_url');
    final user = await settings.get('webdav_user');
    final dir = await settings.get('webdav_dir');
    final password = await readWebDavPassword();
    if (url == null || user == null || password == null || password.isEmpty) return null;
    final intervalHours = int.tryParse(await settings.get('backup_interval_hours') ?? '') ?? 72;
    final last = await settings.get('last_backup');
    if (last != null && last.isNotEmpty) {
      final parsed = DateTime.tryParse(last.replaceFirst(' ', 'T'));
      if (parsed != null && DateTime.now().difference(parsed) < Duration(hours: intervalHours)) {
        return null;
      }
    }
    final config = WebDavConfig(
      baseUrl: url,
      username: user,
      password: password,
      folder: dir ?? '记账备份',
      includeImages: await settings.get('backup_include_images') == 'true',
    );
    final backup = await BackupService(db, config).createBackup();
    await settings.set('last_backup', backup.at);
    await settings.set('webdav_connected', 'true');
    return backup;
  } catch (_) {
    return null;
  }
}

/// 在数据库打开前执行待恢复备份。返回是否执行了恢复。
Future<bool> applyPendingRestore() async {
  final docs = await getApplicationDocumentsDirectory();
  final pending = File(p.join(docs.path, 'pending_restore.zip'));
  if (!await pending.exists()) return false;
  try {
    final bytes = await pending.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final dbEntry = archive.files.where((file) => file.name == 'jizhang.sqlite').firstOrNull;
    if (dbEntry == null) throw StateError('缺少数据库');
    final dbBytes = dbEntry.content;
    if (dbBytes.length < 16 || utf8.decode(dbBytes.sublist(0, 15), allowMalformed: true) != 'SQLite format 3') {
      throw StateError('数据库校验失败');
    }
    final dbFile = await appDatabaseFile();
    if (await dbFile.exists()) {
      await dbFile.copy(p.join(docs.path, 'jizhang.before-restore.sqlite'));
    }
    final wal = File('${dbFile.path}-wal');
    final shm = File('${dbFile.path}-shm');
    if (await wal.exists()) await wal.delete();
    if (await shm.exists()) await shm.delete();
    await dbFile.writeAsBytes(dbBytes, flush: true);

    final receiptFiles = archive.files.where((file) => file.name.startsWith('receipts/')).toList();
    if (receiptFiles.isNotEmpty) {
      final receipts = Directory(p.join(docs.path, 'receipts'));
      if (await receipts.exists()) await receipts.delete(recursive: true);
      await receipts.create(recursive: true);
      for (final file in receiptFiles) {
        final name = file.name.substring('receipts/'.length);
        if (name.isEmpty || name.contains('..')) continue;
        final target = File(p.join(receipts.path, name.replaceAll('/', p.separator)));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.content, flush: true);
      }
    }
    await pending.delete();
    return true;
  } catch (_) {
    if (await pending.exists()) await pending.delete();
    return false;
  }
}
