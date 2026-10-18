import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';

Future<void> showRechargeSheet(BuildContext context, AccountWithBalance stored) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RechargeSheet(stored: stored),
  );
}

class RechargeSheet extends ConsumerStatefulWidget {
  const RechargeSheet({super.key, required this.stored});

  final AccountWithBalance stored;

  @override
  ConsumerState<RechargeSheet> createState() => _RechargeSheetState();
}

class _RechargeSheetState extends ConsumerState<RechargeSheet> {
  final _paid = TextEditingController();
  final _bonus = TextEditingController();
  final _date = TextEditingController();
  final _note = TextEditingController();
  int? _fromId;

  @override
  void initState() {
    super.initState();
    _date.text = formatDate(DateTime.now());
  }

  @override
  void dispose() {
    _paid.dispose();
    _bonus.dispose();
    _date.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const <AccountWithBalance>[];
    final sources = accounts.where((a) => ['bank', 'ewallet', 'cash'].contains(a.account.type)).toList();
    final fromId = (_fromId != null && sources.any((a) => a.account.id == _fromId))
        ? _fromId
        : (sources.isNotEmpty ? sources.first.account.id : null);
    final paid = parseYuanToCents(_paid.text);
    final bonus = parseYuanToCents(_bonus.text);
    final total = paid + bonus;
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
                  Expanded(child: Text('充值', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
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
                        Text(widget.stored.account.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                        SizedBox(height: 2),
                        Text('当前余额 ${formatCents(widget.stored.balance)}', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                      ],
                    ),
                  ),
                  _label(context, '实付金额'),
                  TextField(
                    controller: _paid,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: _decoration(context, '0.00'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(context, '赠送金额（选填）'),
                  TextField(
                    controller: _bonus,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: _decoration(context, '0.00'),
                    onChanged: (_) => setState(() {}),
                  ),
                  _label(context, '付款账户'),
                  DropdownButtonFormField<int>(
                    key: ValueKey('recharge-source-$fromId'),
                    initialValue: fromId,
                    decoration: _decoration(context, ''),
                    icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                    items: sources.map((a) => DropdownMenuItem(value: a.account.id, child: Text(a.account.name))).toList(),
                    onChanged: (value) => setState(() => _fromId = value),
                  ),
                  _label(context, '日期'),
                  TextField(controller: _date, keyboardType: TextInputType.datetime, decoration: _decoration(context, 'YYYY-MM-DD')),
                  _label(context, '备注'),
                  TextField(controller: _note, decoration: _decoration(context, '选填')),
                  SizedBox(height: tokens.space3),
                  Container(
                    padding: EdgeInsets.all(tokens.space3),
                    decoration: BoxDecoration(border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Column(
                      children: [
                        _row(context, '到账金额', formatCents(total), color: tokens.income),
                        SizedBox(height: tokens.space2),
                        _row(context, '充值后余额', formatCents(widget.stored.balance + total)),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.space2),
                  Text(
                    '充值实付计入支出；赠送金额计入收入；卡内消费不再重复计支出。',
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
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
                      onPressed: () => _save(fromId, paid, bonus),
                      child: const Text('确认充值'),
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
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? tokens.textPrimary)),
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

  Future<void> _save(int? fromId, int paid, int bonus) async {
    if (paid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入实付金额')));
      return;
    }
    if (bonus < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('赠送金额不能为负')));
      return;
    }
    if (fromId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先添加付款账户')));
      return;
    }
    final date = DateTime.tryParse(_date.text.trim());
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入正确日期')));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(assetRepositoryProvider).rechargeStored(
            storedAccountId: widget.stored.account.id,
            fromAccountId: fromId,
            paid: paid,
            bonus: bonus,
            occurredAt: DateTime(date.year, date.month, date.day, 12),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      ref.invalidate(accountsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('充值成功')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    }
  }
}
