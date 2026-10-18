import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/资产仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '存单表单.dart';
import '账户展示.dart';

Future<void> showDepositSettleSheet(
  BuildContext context,
  AccountWithBalance view, {
  required String mode,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DepositSettleSheet(view: view, mode: mode),
  );
}

class DepositSettleSheet extends ConsumerStatefulWidget {
  const DepositSettleSheet({super.key, required this.view, required this.mode});

  final AccountWithBalance view;
  final String mode;

  @override
  ConsumerState<DepositSettleSheet> createState() => _DepositSettleSheetState();
}

class _DepositSettleSheetState extends ConsumerState<DepositSettleSheet> {
  final _interest = TextEditingController();
  int? _toId;

  bool get _early => widget.mode == 'early';

  @override
  void initState() {
    super.initState();
    final detail = widget.view.deposit;
    if (detail != null) {
      final expected = (detail.principal * detail.rateBp * detail.termMonths / (10000 * 12)).round();
      _interest.text = ((_early ? 0 : expected) / 100).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _interest.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <AccountWithBalance>[];
    final targets = accounts.where((a) => ['bank', 'ewallet', 'cash'].contains(a.account.type)).toList();
    final toId = (_toId != null && targets.any((a) => a.account.id == _toId))
        ? _toId
        : (targets.isNotEmpty ? targets.first.account.id : null);
    final detail = widget.view.deposit;
    final interest = parseYuanToCents(_interest.text);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: tokens.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl))),
        child: Column(
          children: [
            SizedBox(height: tokens.space2),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull))),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _early ? '提前支取' : '到期支取',
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
                children: [
                  Container(
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Column(
                      children: [
                        _row(context, '存单', widget.view.account.name),
                        SizedBox(height: tokens.space2),
                        _row(context, '本金', formatCents(detail?.principal ?? 0)),
                        SizedBox(height: tokens.space2),
                        _row(context, '到账账户', targets.where((a) => a.account.id == toId).firstOrNull?.account.name ?? '未选择'),
                      ],
                    ),
                  ),
                  _label(context, '实际利息'),
                  TextField(
                    controller: _interest,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: _decoration(context, '0.00'),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: tokens.space1),
                  Text(
                    _early ? '按银行实际到账填写，可为 0；提前支取通常按活期计息。' : '默认按预计利息，可按银行实际到账修改。',
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                  _label(context, '到账账户'),
                  DropdownButtonFormField<int>(
                    key: ValueKey('deposit-target-$toId'),
                    initialValue: toId,
                    decoration: _decoration(context, ''),
                    icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                    items: targets.map((a) => DropdownMenuItem(value: a.account.id, child: Text(a.account.name))).toList(),
                    onChanged: (value) => setState(() => _toId = value),
                  ),
                  SizedBox(height: tokens.space3),
                  Container(
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Column(
                      children: [
                        _row(context, '本金', formatCents(detail?.principal ?? 0)),
                        SizedBox(height: tokens.space2),
                        _row(context, '利息', formatCents(interest), color: tokens.income),
                        SizedBox(height: tokens.space2),
                        _row(context, '到账本息', formatCents((detail?.principal ?? 0) + interest)),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.space2),
                  Text('本金不计收入；实际利息计入「利息」收入。', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                ],
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
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _save(toId, interest),
                      child: const Text('确认支取'),
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

  Widget _label(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space3, bottom: tokens.space1),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
    );
  }

  Widget _row(BuildContext context, String label, String value, {Color? color}) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? tokens.textPrimary))),
      ],
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

  Future<void> _save(int? toId, int interest) async {
    if (interest < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的利息')));
      return;
    }
    if (toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先添加到账账户')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).settleDeposit(
            depositAccountId: widget.view.account.id,
            toAccountId: toId,
            actualInterest: interest,
            mode: widget.mode,
            occurredAt: DateTime.now(),
          );
      ref.invalidate(accountsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(_early ? '提前支取成功' : '已支取')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}

Future<void> showDepositRenewSheet(BuildContext context, AccountWithBalance view) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DepositRenewSheet(view: view),
  );
}

class DepositRenewSheet extends ConsumerStatefulWidget {
  const DepositRenewSheet({super.key, required this.view});

  final AccountWithBalance view;

  @override
  ConsumerState<DepositRenewSheet> createState() => _DepositRenewSheetState();
}

class _DepositRenewSheetState extends ConsumerState<DepositRenewSheet> {
  final _interest = TextEditingController();
  final _rate = TextEditingController();
  final _startAt = TextEditingController();
  final _name = TextEditingController();
  int _termMonths = 12;

  @override
  void initState() {
    super.initState();
    final detail = widget.view.deposit;
    _rate.text = ((detail?.rateBp ?? 325) / 100).toStringAsFixed(2);
    _termMonths = detail?.termMonths ?? 12;
    _startAt.text = formatDate(DateTime.now());
    final expected = detail == null ? 0 : (detail.principal * detail.rateBp * detail.termMonths / (10000 * 12)).round();
    _interest.text = (expected / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _interest.dispose();
    _rate.dispose();
    _startAt.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final detail = widget.view.deposit;
    final interest = parseYuanToCents(_interest.text);
    final newPrincipal = (detail?.principal ?? 0) + interest;
    final start = DateTime.tryParse(_startAt.text.trim()) ?? DateTime.now();
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    final maturity = addMonths(start, _termMonths);
    final newInterest = (newPrincipal * (rate * 100) * _termMonths / (10000 * 12)).round();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: BoxDecoration(color: tokens.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl))),
        child: Column(
          children: [
            SizedBox(height: tokens.space2),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull))),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(child: Text('存单转存', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
                children: [
                  Container(
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.view.account.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                        SizedBox(height: 2),
                        Text(
                          '原本金 ${formatCents(detail?.principal ?? 0)} · 本息转存',
                          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _label(context, '实际利息'),
                  TextField(
                    controller: _interest,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: _decoration(context, '0.00'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(context, '新本金（本息转存）'),
                  InputDecorator(
                    decoration: _decoration(context, ''),
                    child: Text(formatCents(newPrincipal), style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
                  ),
                  _label(context, '新利率（%）'),
                  TextField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: _decoration(context, '3.25'),
                  ),
                  _label(context, '新存期'),
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
                            style: TextStyle(fontSize: 13, color: selected ? tokens.primary : tokens.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  _label(context, '新起存日'),
                  TextField(controller: _startAt, keyboardType: TextInputType.datetime, decoration: _decoration(context, 'YYYY-MM-DD')),
                  Container(
                    margin: EdgeInsets.only(top: tokens.space3),
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Row(
                      children: [
                        Expanded(child: Text('新到期 ${formatDate(maturity)}', style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
                        Text('新预计利息 ${formatCents(newInterest)}', style: TextStyle(fontSize: 13, color: tokens.income, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _label(context, '存单名称（选填）'),
                  TextField(controller: _name, decoration: _decoration(context, '如：招商银行1年存单')),
                ],
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
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _save(interest, newPrincipal, rate, start),
                      child: const Text('确认转存'),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
    );
  }

  Future<void> _save(int interest, int newPrincipal, double rate, DateTime start) async {
    if (interest < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确的利息')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final institution = widget.view.account.institution ?? '';
    final name = _name.text.trim().isEmpty ? '$institution${depositTermLabel(_termMonths)}存单' : _name.text.trim();
    try {
      await ref.read(assetRepositoryProvider).renewDeposit(
            oldDepositAccountId: widget.view.account.id,
            name: name,
            actualInterest: interest,
            newPrincipal: newPrincipal,
            rateBp: (rate * 100).round(),
            termMonths: _termMonths,
            startAt: start,
          );
      ref.invalidate(accountsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('已转存')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
