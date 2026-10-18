import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '../同步/备份服务.dart';
import '../同步/密钥存储.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _dir = TextEditingController(text: '记账备份');
  int? _defaultAccountId;
  bool _showPass = false;
  bool _testing = false;
  bool _busy = false;
  bool _connected = false;
  bool _autoBackup = true;
  int _backupIntervalHours = 72;
  bool _includeImages = false;
  String _lastBackup = '暂无';

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
    final interval = await repo.get('backup_interval_hours');
    final includeImages = await repo.get('backup_include_images');
    final last = await repo.get('last_backup');
    final password = await readWebDavPassword();
    if (!mounted) return;
    setState(() {
      _defaultAccountId = int.tryParse(defaultId ?? '');
      if (url != null) _url.text = url;
      if (user != null) _user.text = user;
      if (password != null) _pass.text = password;
      if (dir != null && dir.isNotEmpty) _dir.text = dir;
      _connected = connected == 'true';
      _autoBackup = auto != 'false';
      _backupIntervalHours = int.tryParse(interval ?? '') ?? 72;
      _includeImages = includeImages == 'true';
      _lastBackup = last ?? '暂无';
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
                TextField(controller: _url, keyboardType: TextInputType.url, decoration: _decoration(context, 'https://dav.jianguoyun.com/dav/')),
                _label(context, '用户名'),
                TextField(controller: _user, decoration: _decoration(context, '坚果云账号邮箱')),
                _label(context, '密码（应用密码）'),
                TextField(
                  controller: _pass,
                  obscureText: !_showPass,
                  decoration: _decoration(context, '坚果云应用密码').copyWith(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(_showPass ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: tokens.textSecondary),
                    ),
                  ),
                ),
                _label(context, '备份目录（不要填根目录）'),
                TextField(controller: _dir, decoration: _decoration(context, '记账备份')),
                SizedBox(height: tokens.space1),
                Text(
                  '备份会保存到 /记账备份/ 子目录；留空时也默认使用该目录。',
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                ),
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
                Text('密码保存在系统安全存储，不随备份导出。', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
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
                          Text('启动/回到前台时检查，非每次操作同步', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
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
                SizedBox(height: tokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('自动备份间隔', style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                          SizedBox(height: 2),
                          Text('坚果云免费版建议 3 天或 7 天；可随时手动备份', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('backup-interval-$_backupIntervalHours'),
                        initialValue: _backupIntervalHours,
                        decoration: _decoration(context, ''),
                        icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                        items: const [
                          DropdownMenuItem(value: 24, child: Text('24 小时')),
                          DropdownMenuItem(value: 72, child: Text('3 天')),
                          DropdownMenuItem(value: 168, child: Text('7 天')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _backupIntervalHours = value);
                          ref.read(settingsRepositoryProvider).set('backup_interval_hours', value.toString());
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('备份图片凭证', style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                          SizedBox(height: 2),
                          Text('默认关闭，只备份数据库，节省坚果云流量', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _includeImages = !_includeImages);
                        ref.read(settingsRepositoryProvider).set('backup_include_images', _includeImages ? 'true' : 'false');
                      },
                      child: Container(
                        width: 44,
                        height: 26,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: _includeImages ? tokens.primary : tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull)),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 160),
                          alignment: _includeImages ? Alignment.centerRight : Alignment.centerLeft,
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
                  '备份为 zip；数据库始终包含，图片凭证默认不包含，可在上方按需开启。服务器仅保留最近 5 份。',
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
                _aboutRow(context, '备份格式', 'zip（db + 可选图片）'),
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
    final config = WebDavConfig(
      baseUrl: url,
      username: user,
      password: pass,
      folder: _dir.text,
    );
    try {
      await BackupService(ref.read(databaseProvider), config).testConnection();
      if (!mounted) return;
      final repo = ref.read(settingsRepositoryProvider);
      await repo.set('webdav_url', url);
      await repo.set('webdav_user', user);
      await repo.set('webdav_dir', config.folder);
      await repo.set('webdav_connected', 'true');
      await saveWebDavPassword(pass);
      if (!mounted) return;
      setState(() {
        _testing = false;
        _connected = true;
        _dir.text = config.folder;
      });
      messenger.showSnackBar(const SnackBar(content: Text('连接成功')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _testing = false;
        _connected = false;
      });
      messenger.showSnackBar(SnackBar(content: Text('连接失败：$error')));
    }
  }

  Future<void> _backupNow() async {
    final messenger = ScaffoldMessenger.of(context);
    final config = _currentConfig();
    if (config == null) {
      messenger.showSnackBar(const SnackBar(content: Text('请先填写 WebDAV 地址、用户名和应用密码')));
      return;
    }
    setState(() => _busy = true);
    try {
      final service = BackupService(ref.read(databaseProvider), config);
      final backup = await service.createBackup();
      final repo = ref.read(settingsRepositoryProvider);
      await repo.set('last_backup', backup.at);
      await repo.set('webdav_connected', 'true');
      await saveWebDavPassword(config.password);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _connected = true;
        _lastBackup = backup.at;
        _dir.text = config.folder;
      });
      messenger.showSnackBar(SnackBar(content: Text('备份成功 · ${backup.name}')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('备份失败：$error')));
    }
  }

  Future<void> _openBackups() async {
    final messenger = ScaffoldMessenger.of(context);
    final config = _currentConfig();
    if (config == null) {
      messenger.showSnackBar(const SnackBar(content: Text('请先填写 WebDAV 地址、用户名和应用密码')));
      return;
    }
    List<RemoteBackup> backups;
    try {
      backups = await BackupService(ref.read(databaseProvider), config).listBackups();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('读取备份失败：$error')));
      return;
    }
    if (!mounted) return;
    if (backups.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('服务器暂无备份')));
      return;
    }
    final selected = await showModalBottomSheet<RemoteBackup>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BackupSheet(backups: backups),
    );
    if (selected == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text('将下载「${selected.at.isEmpty ? selected.name : selected.at}」的备份，并在下次启动 App 时覆盖当前数据。下载和校验前不会改动本地数据。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('下载并恢复')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await BackupService(ref.read(databaseProvider), config).downloadForRestore(selected);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('已下载备份'),
          content: const Text('备份已校验并准备恢复。请完全退出并重新打开 App，启动时会替换本地数据库和图片。'),
          actions: [FilledButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('知道了'))],
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('恢复准备失败：$error')));
    }
  }

  WebDavConfig? _currentConfig() {
    final url = _url.text.trim();
    final user = _user.text.trim();
    final pass = _pass.text;
    if (url.isEmpty || user.isEmpty || pass.isEmpty) return null;
    try {
      return WebDavConfig(
        baseUrl: url,
        username: user,
        password: pass,
        folder: _dir.text,
        includeImages: _includeImages,
      );
    } catch (_) {
      return null;
    }
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

  final List<RemoteBackup> backups;

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
                              Text(
                                widget.backups[i].sizeLabel.isEmpty
                                    ? widget.backups[i].at
                                    : '${widget.backups[i].at} · ${widget.backups[i].sizeLabel}',
                                style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                              ),
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
