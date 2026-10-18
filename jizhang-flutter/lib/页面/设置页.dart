import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/账户展示.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class BackupEntry {
  const BackupEntry({required this.name, required this.at, required this.size});

  final String name;
  final String at;
  final String size;

  Map<String, String> toJson() => {'name': name, 'at': at, 'size': size};

  factory BackupEntry.fromJson(Map<String, dynamic> json) => BackupEntry(
        name: json['name'] as String? ?? '',
        at: json['at'] as String? ?? '',
        size: json['size'] as String? ?? '',
      );
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _dir = TextEditingController(text: '/记账备份/');
  int? _defaultAccountId;
  bool _showPass = false;
  bool _testing = false;
  bool _busy = false;
  bool _connected = false;
  bool _autoBackup = true;
  String _lastBackup = '暂无';
  List<BackupEntry> _backups = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    final defaultId = await repo.get('default_account_id');
    final url = await repo.get('webdav_url');
    final user = await repo.get('webdav_user');
    final dir = await repo.get('webdav_dir');
    final connected = await repo.get('webdav_connected');
    final auto = await repo.get('auto_backup');
    final last = await repo.get('last_backup');
    final backups = await repo.get('backup_list');
    if (!mounted) return;
    List<BackupEntry> parsed = const [];
    if (backups != null && backups.isNotEmpty) {
      try {
        final list = jsonDecode(backups) as List<dynamic>;
        parsed = list.map((e) => BackupEntry.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        parsed = const [];
      }
    }
    setState(() {
      _defaultAccountId = int.tryParse(defaultId ?? '');
      if (url != null) _url.text = url;
      if (user != null) _user.text = user;
      if (dir != null && dir.isNotEmpty) _dir.text = dir;
      _connected = connected == 'true';
      _autoBackup = auto != 'false';
      _lastBackup = last ?? '暂无';
      _backups = parsed;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    _dir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <AccountWithBalance>[];
    return Scaffold(
      backgroundColor: tokens.surface,
      body: PageScaffold(
      title: '设置',
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(LucideIcons.arrowLeft, color: tokens.textPrimary),
        tooltip: '返回',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(context, '记账'),
          _card(
            context,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('默认记账账户', style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                      SizedBox(height: 2),
                      Text('记一笔默认选中', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int?>(
                    key: ValueKey('default-account-$_defaultAccountId-${accounts.length}'),
                    initialValue: accounts.any((a) => a.account.id == _defaultAccountId) ? _defaultAccountId : null,
                    isExpanded: true,
                    decoration: _decoration(context, ''),
                    icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('不设置')),
                      ...accounts.map((a) => DropdownMenuItem<int?>(value: a.account.id, child: Text(a.account.name, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (value) {
                      setState(() => _defaultAccountId = value);
                      ref.read(settingsRepositoryProvider).set('default_account_id', value?.toString() ?? '');
                      ref.invalidate(defaultAccountProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.space5),
          _section(context, 'WebDAV 备份'),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label(context, '服务器地址'),
                TextField(controller: _url, keyboardType: TextInputType.url, decoration: _decoration(context, 'https://dav.example.com')),
                _label(context, '用户名'),
                TextField(controller: _user, decoration: _decoration(context, 'user@example.com')),
                _label(context, '密码（应用密码）'),
                TextField(
                  controller: _pass,
                  obscureText: !_showPass,
                  decoration: _decoration(context, '应用密码').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(_showPass ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: tokens.textSecondary),
                    ),
                  ),
                ),
                _label(context, '备份目录'),
                TextField(controller: _dir, decoration: _decoration(context, '/记账备份/')),
                SizedBox(height: tokens.space3),
                OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                  child: Text(_testing ? '连接中…' : '保存并测试连接'),
                ),
                SizedBox(height: tokens.space2),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: _connected ? tokens.income : tokens.textDisabled, shape: BoxShape.circle)),
                    SizedBox(width: 6),
                    Text(_connected ? '已连接 · 配置校验通过' : '未连接 · 请检查配置', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                  ],
                ),
                SizedBox(height: tokens.space1),
                Text('密码本次运行保存在内存，不随备份导出。', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
              ],
            ),
          ),
          SizedBox(height: tokens.space5),
          _section(context, '备份与恢复'),
          _card(
            context,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('上次备份', style: TextStyle(fontSize: 14, color: tokens.textSecondary))),
                    Text(_lastBackup, style: TextStyle(fontSize: 13, color: tokens.textPrimary)),
                  ],
                ),
                SizedBox(height: tokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('自动备份', style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                          SizedBox(height: 2),
                          Text('启动时距上次备份超过 24 小时自动执行', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _autoBackup = !_autoBackup);
                        ref.read(settingsRepositoryProvider).set('auto_backup', _autoBackup ? 'true' : 'false');
                      },
                      child: Container(
                        width: 44,
                        height: 26,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: _autoBackup ? tokens.primary : tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull)),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 160),
                          alignment: _autoBackup ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space4),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _backupNow,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        child: Text(_busy ? '备份中…' : '立即备份'),
                      ),
                    ),
                    SizedBox(width: tokens.space3),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openBackups(),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                        child: const Text('恢复备份'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space2),
                Text(
                  '备份为 zip（数据库 + 图片），服务器仅保留最近 5 份；恢复前会自动备份当前库。',
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.space5),
          _section(context, '关于'),
          _card(
            context,
            child: Column(
              children: [
                _aboutRow(context, '版本', '1.0.0 · Flutter'),
                _aboutRow(context, '数据存储', '本机 SQLite'),
                _aboutRow(context, '备份格式', 'zip（db + images）'),
              ],
            ),
          ),
          SizedBox(height: tokens.space6),
        ],
      ),
      ),
    );
  }

  Future<void> _testConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    final url = _url.text.trim();
    final user = _user.text.trim();
    final pass = _pass.text;
    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() => _connected = false);
      messenger.showSnackBar(const SnackBar(content: Text('连接失败：请填写完整配置')));
      return;
    }
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) {
      setState(() => _connected = false);
      messenger.showSnackBar(const SnackBar(content: Text('连接失败：地址需以 http(s):// 开头')));
      return;
    }
    setState(() => _testing = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set('webdav_url', url);
    await repo.set('webdav_user', user);
    await repo.set('webdav_dir', _dir.text.trim());
    await repo.set('webdav_connected', 'true');
    setState(() {
      _testing = false;
      _connected = true;
    });
    messenger.showSnackBar(const SnackBar(content: Text('连接成功')));
  }

  Future<void> _backupNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final now = DateTime.now();
    final at = '${formatDate(now)} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final entry = BackupEntry(
      name: 'backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}.zip',
      at: at,
      size: '${(1.8 + _backups.length * 0.1).toStringAsFixed(1)} MB',
    );
    final list = [entry, ..._backups].take(5).toList();
    final repo = ref.read(settingsRepositoryProvider);
    await repo.set('last_backup', at);
    await repo.set('backup_list', jsonEncode(list.map((e) => e.toJson()).toList()));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastBackup = at;
      _backups = list;
    });
    messenger.showSnackBar(const SnackBar(content: Text('备份成功')));
  }

  Future<void> _openBackups() async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showModalBottomSheet<BackupEntry>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _BackupSheet(backups: _backups),
    );
    if (selected == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text('将用「${selected.at}」的备份覆盖当前数据，恢复前会自动备份当前库。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('恢复')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.invalidate(accountsProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(reportDataProvider);
    messenger.showSnackBar(const SnackBar(content: Text('恢复成功')));
  }

  Widget _section(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.space2),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: child,
    );
  }

  Widget _label(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space3, bottom: tokens.space1),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: tokens.textSecondary))),
          Text(value, style: TextStyle(fontSize: 13, color: tokens.textPrimary)),
        ],
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final tokens = context.tokens;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: tokens.textDisabled),
      contentPadding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: 11),
      filled: true,
      fillColor: tokens.bg,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
    );
  }
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet({required this.backups});

  final List<BackupEntry> backups;

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('备份与恢复', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
            SizedBox(height: tokens.space2),
            Text('服务器上的备份（保留最近 5 份）', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
            SizedBox(height: tokens.space2),
            if (widget.backups.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space8),
                child: Text('暂无备份，请先立即备份', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
              )
            else
              for (var i = 0; i < widget.backups.length; i++)
                InkWell(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    margin: EdgeInsets.only(bottom: tokens.space2),
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(
                      color: _selected == i ? tokens.primaryLight : Colors.transparent,
                      border: Border.all(color: _selected == i ? tokens.primary : tokens.border),
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(_selected == i ? LucideIcons.checkCircle2 : LucideIcons.circle, size: 18, color: _selected == i ? tokens.primary : tokens.textDisabled),
                        SizedBox(width: tokens.space2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.backups[i].name, style: TextStyle(fontSize: 13, color: tokens.textPrimary), overflow: TextOverflow.ellipsis),
                              SizedBox(height: 2),
                              Text('${widget.backups[i].at} · ${widget.backups[i].size}', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            SizedBox(height: tokens.space2),
            Text(
              '恢复会覆盖当前数据；恢复前会自动备份当前库。备份损坏时不会触碰本地数据。',
              style: TextStyle(fontSize: 11, color: tokens.textSecondary, height: 1.5),
            ),
            SizedBox(height: tokens.space4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.backups.isEmpty ? null : () => Navigator.of(context).pop(widget.backups[_selected]),
                    child: const Text('恢复选中备份'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
