import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/账户展示.dart';
import '../数据/仓库/账户仓库.dart';
import '../导入/excel解析.dart';
import '../导入/excel导入服务.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class ExcelImportPage extends ConsumerStatefulWidget {
  const ExcelImportPage({super.key});

  @override
  ConsumerState<ExcelImportPage> createState() => _ExcelImportPageState();
}

class _ExcelImportPageState extends ConsumerState<ExcelImportPage> {
  int? _accountId;
  String? _fileName;
  ExcelParseResult? _parsed;
  ExcelImportResult? _result;
  bool _parsing = false;
  bool _importing = false;
  String? _parseError;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsAsync = ref.watch(accountsProvider);
    final accounts = accountsAsync.valueOrNull ?? const <AccountWithBalance>[];
    final preferred = ref.watch(defaultAccountProvider).valueOrNull;
    final selected = (_accountId != null && accounts.any((a) => a.account.id == _accountId))
        ? _accountId
        : (preferred != null && accounts.any((a) => a.account.id == preferred)
            ? preferred
            : (accounts.isNotEmpty ? accounts.first.account.id : null));
    final parsed = _parsed;
    return Scaffold(
      backgroundColor: tokens.surface,
      body: PageScaffold(
        title: 'Excel 导入',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: tokens.textPrimary),
          tooltip: '返回',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(tokens.space4),
              decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('导入账户', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                  SizedBox(height: tokens.space1),
                  DropdownButtonFormField<int>(
                    key: ValueKey('import-account-$selected-${accounts.length}'),
                    initialValue: selected,
                    isExpanded: true,
                    decoration: _decoration(context, accounts.isEmpty ? '请先添加账户' : ''),
                    icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                    items: accounts
                        .map((a) => DropdownMenuItem(value: a.account.id, child: Text(a.account.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (value) => setState(() => _accountId = value),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    'Excel 没有账户列时，全部导入到该账户',
                    style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                  ),
                  SizedBox(height: tokens.space3),
                  OutlinedButton.icon(
                    onPressed: _parsing ? null : _pickFile,
                    icon: const Icon(LucideIcons.fileSpreadsheet, size: 18),
                    label: Text(_fileName ?? '选择 .xlsx 文件'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: BorderSide(color: tokens.border),
                      foregroundColor: tokens.textPrimary,
                    ),
                  ),
                  if (_parseError != null) ...[
                    SizedBox(height: tokens.space2),
                    Text(_parseError!, style: TextStyle(fontSize: 12, color: tokens.expense)),
                  ],
                ],
              ),
            ),
            if (_parsing) ...[
              SizedBox(height: tokens.space4),
              Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary))),
            ],
            if (parsed != null) ...[
              SizedBox(height: tokens.space4),
              _resultSummary(context, parsed),
              SizedBox(height: tokens.space3),
              _preview(context, parsed),
              SizedBox(height: tokens.space4),
              FilledButton(
                onPressed: _importing || selected == null || parsed.rows.isEmpty ? null : () => _import(selected),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _importing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('开始导入 ${parsed.rows.length} 条'),
              ),
            ],
            if (_result != null) ...[
              SizedBox(height: tokens.space4),
              _resultCard(context, _result!),
            ],
            SizedBox(height: tokens.space6),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _parseError = null);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _fileName = file.name;
        _result = null;
        _parsing = true;
      });
      final parsed = ExcelParser.parse(bytes);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _parsing = false;
        _result = null;
      });
      if (parsed.rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('没有可导入的收入/支出记录')));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _parsing = false;
        _parsed = null;
        _parseError = '解析失败：$error';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('解析失败：$error')));
    }
  }

  Future<void> _import(int accountId) async {
    final parsed = _parsed;
    if (parsed == null) return;
    setState(() {
      _importing = true;
      _result = null;
    });
    try {
      final result = await ExcelImportService(ref.read(databaseProvider)).importRows(
        accountId: accountId,
        rows: parsed.rows,
        parseErrors: parsed.errors,
      );
      ref.invalidate(homeProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(reportDataProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(categoryUsageProvider);
      if (!mounted) return;
      setState(() {
        _importing = false;
        _result = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入完成：成功 ${result.success} 条')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }

  Widget _resultSummary(BuildContext context, ExcelParseResult parsed) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space3),
      decoration: BoxDecoration(color: tokens.primaryLight, borderRadius: BorderRadius.circular(tokens.radiusMd)),
      child: Row(
        children: [
          Expanded(child: _stat(context, '有效记录', '${parsed.rows.length}')),
          _stat(context, '跳过', '${parsed.errors.length}'),
          SizedBox(width: tokens.space4),
          _stat(context, '总行数', '${parsed.totalRows}'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
      ],
    );
  }

  Widget _preview(BuildContext context, ExcelParseResult parsed) {
    final tokens = context.tokens;
    final rows = parsed.rows.take(8).toList();
    return Container(
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(tokens.space3),
            child: Row(
              children: [
                Expanded(child: Text('预览前 ${rows.length} 条', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
                Flexible(child: Text(parsed.headers.join(' · '), style: TextStyle(fontSize: 9, color: tokens.textDisabled), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.divider),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: tokens.space2),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(formatDate(rows[i].occurredAt), style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(rows[i].type == 'income' ? '收入' : '支出', style: TextStyle(fontSize: 11, color: rows[i].type == 'income' ? tokens.income : tokens.expense)),
                  ),
                  Expanded(
                    child: Text(rows[i].category, style: TextStyle(fontSize: 12, color: tokens.textPrimary), overflow: TextOverflow.ellipsis),
                  ),
                  Text(formatCents(rows[i].amount), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tokens.textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            if (i < rows.length - 1) Divider(height: 1, indent: 12, endIndent: 12, color: tokens.divider),
          ],
          if (parsed.errors.isNotEmpty) ...[
            Divider(height: 1, color: tokens.divider),
            Padding(
              padding: EdgeInsets.all(tokens.space3),
              child: Text(
                parsed.errors.take(3).map((error) => '第 ${error.rowNumber} 行：${error.message}').join('\n'),
                style: TextStyle(fontSize: 11, color: tokens.expense, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(BuildContext context, ExcelImportResult result) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(color: tokens.incomeBg, borderRadius: BorderRadius.circular(tokens.radiusLg), border: Border.all(color: tokens.income.withValues(alpha: .25))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('导入结果', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
          SizedBox(height: tokens.space2),
          Text('成功 ${result.success} 条 · 重复 ${result.duplicates} 条 · 跳过 ${result.skipped} 条 · 新建类别 ${result.categoriesCreated} 个',
              style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.5)),
          if (result.errors.isNotEmpty) ...[
            SizedBox(height: tokens.space1),
            Text('失败行：${result.errors.take(5).map((e) => e.rowNumber).join('、')}${result.errors.length > 5 ? ' 等' : ''}',
                style: TextStyle(fontSize: 11, color: tokens.expense)),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final tokens = context.tokens;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: tokens.textDisabled),
      contentPadding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: 12),
      filled: true,
      fillColor: tokens.bg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
    );
  }
}
