import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/资产仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';

Future<void> showDepositForm(BuildContext context, {AccountWithBalance? account}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DepositFormSheet(account: account),
  );
}

const depositTerms = [
  (3, '3个月'),
  (6, '6个月'),
  (12, '1年'),
  (24, '2年'),
  (36, '3年'),
  (60, '5年'),
];

String depositTermLabel(int months) {
  for (final item in depositTerms) {
    if (item.$1 == months) return item.$2;
  }
  return '$months个月';
}

class DepositFormSheet extends ConsumerStatefulWidget {
  const DepositFormSheet({super.key, this.account});

  final AccountWithBalance? account;

  @override
  ConsumerState<DepositFormSheet> createState() => _DepositFormSheetState();
}

class _DepositFormSheetState extends ConsumerState<DepositFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _name = TextEditingController();
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '3.25');
  final _startAt = TextEditingController();
  final _certificateNo = TextEditingController();
  final _note = TextEditingController();
  int _termMonths = 36;
  int? _sourceAccountId;

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _bank.text = '招商银行';
    _startAt.text = formatDate(DateTime.now());
    final view = widget.account;
    if (view != null) {
      _bank.text = view.account.institution ?? '';
      _name.text = view.account.name;
      _note.text = view.account.note ?? '';
    }
  }

  @override
  void dispose() {
    _bank.dispose();
    _name.dispose();
    _principal.dispose();
    _rate.dispose();
    _startAt.dispose();
    _certificateNo.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <AccountWithBalance>[];
    final sourceAccounts = accounts
        .where((a) => ['bank', 'ewallet', 'cash'].contains(a.account.type))
        .toList();
    final detail = widget.account?.account.id;
    if (detail != null && _principal.text.isEmpty) {
      // 编辑时从数据库异步补齐一次。
      _loadDetail();
    }
    final start = DateTime.tryParse(_startAt.text.trim()) ?? DateTime.now();
    final maturity = addMonths(start, _termMonths);
    final principal = parseYuanToCents(_principal.text);
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final interest = (principal * (rate * 100) * _termMonths / (10000 * 12)).round();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl)),
        ),
        child: Column(
          children: [
            SizedBox(height: tokens.space2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? '编辑存单' : '添加存单',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
                  children: [
                    _label(context, '银行'),
                    TextFormField(
                      controller: _bank,
                      decoration: _decoration(context, '如：招商银行'),
                      validator: (value) => (value ?? '').trim().isEmpty ? '请填写银行' : null,
                    ),
                    _label(context, '本金'),
                    TextFormField(
                      controller: _principal,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: _decoration(context, '0.00'),
                      validator: (value) => parseYuanToCents(value ?? '') <= 0 ? '请输入本金' : null,
                    ),
                    _label(context, '年利率（%）'),
                    TextFormField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      decoration: _decoration(context, '3.25'),
                      validator: (value) => (double.tryParse(value ?? '') ?? 0) < 0 ? '请输入正确的利率' : null,
                    ),
                    _label(context, '存期'),
                    Wrap(
                      spacing: tokens.space2,
                      runSpacing: tokens.space2,
                      children: depositTerms.map((item) {
                        final selected = item.$1 == _termMonths;
                        return InkWell(
                          onTap: () => setState(() => _termMonths = item.$1),
                          borderRadius: BorderRadius.circular(tokens.radiusFull),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? tokens.primaryLight : tokens.bg,
                              border: Border.all(color: selected ? tokens.primary : tokens.border),
                              borderRadius: BorderRadius.circular(tokens.radiusFull),
                            ),
                            child: Text(
                              item.$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected ? tokens.primary : tokens.textSecondary,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    _label(context, '起存日'),
                    TextFormField(
                      controller: _startAt,
                      keyboardType: TextInputType.datetime,
                      decoration: _decoration(context, 'YYYY-MM-DD'),
                      validator: (value) => DateTime.tryParse((value ?? '').trim()) == null ? '请输入起存日' : null,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: tokens.space3),
                      padding: EdgeInsets.all(tokens.space3),
                      decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                      child: Row(
                        children: [
                          Expanded(child: Text('到期 ${formatDate(maturity)}', style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
                          Text('预计利息 ${formatCents(interest)}', style: TextStyle(fontSize: 13, color: tokens.income, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    if (!_editing) ...[
                      _label(context, '资金来源（可选）'),
                      DropdownButtonFormField<int?>(
                        initialValue: _sourceAccountId,
                        decoration: _decoration(context, ''),
                        icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('不转出（已有存单直接录入）')),
                          ...sourceAccounts.map((a) => DropdownMenuItem<int?>(value: a.account.id, child: Text(a.account.name))),
                        ],
                        onChanged: (value) => setState(() => _sourceAccountId = value),
                      ),
                      SizedBox(height: tokens.space1),
                      Text(
                        '选择账户则从该账户转出本金；存单购买不计支出',
                        style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      ),
                    ],
                    _label(context, '存单名称（选填）'),
                    TextFormField(
                      controller: _name,
                      decoration: _decoration(context, '如：招商银行3年存单'),
                    ),
                    _label(context, '存单号（选填）'),
                    TextFormField(
                      controller: _certificateNo,
                      decoration: _decoration(context, '如 CD20260601001'),
                    ),
                    _label(context, '备注'),
                    TextFormField(
                      controller: _note,
                      decoration: _decoration(context, '添加备注（选填）'),
                    ),
                    SizedBox(height: tokens.space4),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space4, tokens.space4),
              decoration: BoxDecoration(color: tokens.bg, border: Border(top: BorderSide(color: tokens.border))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: tokens.border),
                        foregroundColor: tokens.textPrimary,
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _loaded = false;

  Future<void> _loadDetail() async {
    if (_loaded) return;
    _loaded = true;
    final id = widget.account!.account.id;
    final detail = await ref.read(assetRepositoryProvider).depositDetailOf(id);
    if (!mounted || detail == null) return;
    setState(() {
      _principal.text = (detail.principal / 100).toStringAsFixed(2);
      _rate.text = (detail.rateBp / 100).toStringAsFixed(2);
      _termMonths = detail.termMonths;
      _startAt.text = formatDate(DateTime.fromMillisecondsSinceEpoch(detail.startAt));
      _certificateNo.text = detail.certificateNo ?? '';
    });
  }

  Widget _label(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space3, bottom: tokens.space1),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.primary, width: 1.5),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final start = DateTime.tryParse(_startAt.text.trim());
    if (start == null) return;
    final bank = _bank.text.trim();
    final principal = parseYuanToCents(_principal.text);
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final name = _name.text.trim().isEmpty ? '$bank${depositTermLabel(_termMonths)}存单' : _name.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_editing) {
        await ref.read(assetRepositoryProvider).updateDeposit(
              widget.account!.account.id,
              name: name,
              bank: bank,
              principal: principal,
              rateBp: (rate * 100).round(),
              termMonths: _termMonths,
              startAt: start,
              certificateNo: _certificateNo.text.trim().isEmpty ? null : _certificateNo.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            );
      } else {
        await ref.read(assetRepositoryProvider).createDeposit(
              name: name,
              bank: bank,
              principal: principal,
              rateBp: (rate * 100).round(),
              termMonths: _termMonths,
              startAt: start,
              certificateNo: _certificateNo.text.trim().isEmpty ? null : _certificateNo.text.trim(),
              note: _note.text.trim().isEmpty ? null : _note.text.trim(),
              sourceAccountId: _sourceAccountId,
            );
      }
      ref.invalidate(accountsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(_editing ? '已更新存单' : '已添加存单')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }
}
