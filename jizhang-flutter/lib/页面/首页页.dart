import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/类别展示.dart';
import '../组件/账户详情.dart';
import '../组件/账户展示.dart';
import '../组件/账户表单.dart';
import '../组件/记账表单.dart';
import '../组件/存单表单.dart';
import '../组件/存单动作.dart';
import '../组件/充值表单.dart';
import '../组件/还款表单.dart';
import '../数据/首页数据.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final snapshot = ref.watch(homeProvider);
    final now = DateTime.now();
    return PageScaffold(
      subtitle: '${now.year}年${now.month}月${now.day}日 ${_weekday(now.weekday)}',
      title: '我的账单',
      action: snapshot.valueOrNull?.dueItems.isNotEmpty == true
          ? _DuePill(count: snapshot.value!.dueItems.length, onTap: () => _openDue(context))
          : null,
      child: snapshot.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space10),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary)),
        ),
        error: (error, stack) => _ErrorCard(message: '首页加载失败：$error'),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeSnapshot data) {
    final tokens = context.tokens;
    final keyword = _search.text.trim().toLowerCase();
    final groups = keyword.isEmpty
        ? data.groups
        : data.groups
            .map((g) => HomeGroup(
                  label: g.label,
                  expense: g.expense,
                  items: g.items.where((item) {
                    final t = item.transaction;
                    return item.categoryName.toLowerCase().contains(keyword) ||
                        (t.note ?? '').toLowerCase().contains(keyword) ||
                        item.accountName.toLowerCase().contains(keyword);
                  }).toList(),
                ))
            .where((g) => g.items.isNotEmpty)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(tokens.space3),
          decoration: BoxDecoration(
            color: tokens.bg,
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日支出', style: TextStyle(fontSize: 11, height: 1.2, color: tokens.textSecondary)),
              SizedBox(height: 2),
              Text(
                formatCents(data.todayExpense),
                style: TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: tokens.space2),
              Row(
                children: [
                  Expanded(child: _metric(context, '本月支出', formatCents(data.monthExpense))),
                  Expanded(child: _metric(context, '本月收入', formatCents(data.monthIncome), alignEnd: true)),
                ],
              ),
              SizedBox(height: tokens.space2),
              Container(
                padding: EdgeInsets.only(top: tokens.space3),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('本月结余', style: TextStyle(fontSize: 12, height: 1.2, color: tokens.textSecondary))),
                    Text(
                      formatCents(data.monthBalance, signed: true),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.space3),
        Container(
          height: 38,
          padding: EdgeInsets.symmetric(horizontal: tokens.space3),
          decoration: BoxDecoration(
            color: tokens.surface2,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search, size: 18, color: tokens.textSecondary),
              SizedBox(width: tokens.space2),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '搜索类别、备注、账户',
                    hintStyle: TextStyle(fontSize: 14, color: tokens.textDisabled),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 14, color: tokens.textPrimary),
                ),
              ),
              if (_search.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _search.clear();
                    setState(() {});
                  },
                  child: Text('清除', style: TextStyle(fontSize: 13, color: tokens.primary, fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ),
        SizedBox(height: tokens.space3),
        Row(
          children: [
            Text('最近交易', style: TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
          ],
        ),
        SizedBox(height: tokens.space1),
        if (groups.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: tokens.space8),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusFull)),
                  child: Icon(LucideIcons.receipt, size: 22, color: tokens.textDisabled),
                ),
                SizedBox(height: tokens.space2),
                Text(keyword.isEmpty ? '还没有记录' : '没有匹配记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                SizedBox(height: tokens.space1),
                Text(
                  keyword.isEmpty ? '点底部 + 记一笔' : '换个关键词试试，或点清除',
                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                ),
              ],
            ),
          )
        else
          for (final group in groups) ...[
            Padding(
              padding: EdgeInsets.only(top: tokens.space2, bottom: tokens.space1),
              child: Row(
                children: [
                  Expanded(child: Text(group.label, style: TextStyle(fontSize: 12, height: 1.2, color: tokens.textSecondary))),
                  if (group.expense > 0)
                    Text(formatCents(group.expense), style: TextStyle(fontSize: 12, height: 1.2, color: tokens.textSecondary, fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < group.items.length; i++) ...[
                    _FlowTile(
                      item: group.items[i],
                      onTap: () => showRecordSheet(context, transaction: group.items[i].transaction),
                    ),
                    if (i < group.items.length - 1) Divider(height: 1, indent: 52, color: tokens.divider),
                  ],
                ],
              ),
            ),
          ],
        SizedBox(height: tokens.space6),
      ],
    );
  }

  Widget _metric(BuildContext context, String label, String value, {bool alignEnd = false}) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, height: 1.2, color: tokens.textSecondary)),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Future<void> _openDue(BuildContext context) async {
    final data = ref.read(homeProvider).valueOrNull;
    if (data == null || data.dueItems.isEmpty) return;
    final accountId = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DueSheet(items: data.dueItems),
    );
    if (accountId == null || !context.mounted) return;
    final accounts = await ref.read(accountsProvider.future);
    final view = accounts.where((a) => a.account.id == accountId).firstOrNull;
    if (view == null || !context.mounted) return;
    final categories = ref.read(categoriesProvider).valueOrNull ?? const [];
    final categoryNames = {for (final c in categories) c.id: c.name};
    final action = await showAccountDetail(context, view, categoryNames: categoryNames);
    if (action == null || !context.mounted) return;
    if (action == AccountDetailAction.recharge) {
      await showRechargeSheet(context, view);
      return;
    }
    if (action == AccountDetailAction.repay) {
      await showRepaySheet(context, view);
      return;
    }
    if (action == AccountDetailAction.settleEarly || action == AccountDetailAction.settleMaturity) {
      await showDepositSettleSheet(context, view, mode: action == AccountDetailAction.settleEarly ? 'early' : 'maturity');
      return;
    }
    if (action == AccountDetailAction.renew) {
      await showDepositRenewSheet(context, view);
      return;
    }
    if (action == AccountDetailAction.edit) {
      if (view.account.type == 'deposit') {
        await showDepositForm(context, account: view);
        return;
      }
      final kind = view.account.type == 'loan'
          ? AccountKind.loan
          : (view.account.type == 'stored'
              ? AccountKind.stored
              : (view.account.type == 'credit' ? AccountKind.credit : AccountKind.bank));
      await showAccountForm(context, kind: kind, account: view);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除账户'),
        content: Text('删除「${view.account.name}」？有流水的账户会自动归档，历史流水保留。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: context.tokens.expense),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = view.account.type == 'deposit'
        ? await ref.read(assetRepositoryProvider).deleteDeposit(view.account.id)
        : await ref.read(accountRepositoryProvider).deleteOrArchiveAccount(view.account.id);
    ref.invalidate(accountsProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(reportDataProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(deleted ? '已删除账户' : '账户有流水，已归档')));
  }

  String _weekday(int weekday) {
    const names = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[(weekday - 1).clamp(0, 6)];
  }
}

class _FlowTile extends StatelessWidget {
  const _FlowTile({required this.item, required this.onTap});

  final HomeTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isIncome = item.transaction.type == 'income';
    final liability = ['房贷', '车贷', '贷款'].contains(item.categoryName);
    final color = isIncome ? tokens.income : (liability ? tokens.liability : tokens.expense);
    final time = DateTime.fromMillisecondsSinceEpoch(item.transaction.occurredAt);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: 9),
        child: Row(
          children: [
            Icon(categoryIconData(item.categoryIcon), size: 24, color: categoryColor(item.categoryIcon)),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName,
                    style: TextStyle(fontSize: 16, height: 1.2, fontWeight: FontWeight.w500, color: tokens.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.transaction.imagePath != null) ...[
                        Icon(LucideIcons.image, size: 12, color: tokens.textSecondary),
                        const SizedBox(width: 3),
                      ],
                      Expanded(
                        child: Text(
                          '${item.transaction.note?.isNotEmpty == true ? item.transaction.note : item.accountName} · $hh:$mm',
                          style: TextStyle(fontSize: 13, height: 1.2, color: tokens.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space2),
            Text(
              '${isIncome ? '+' : '-'}${formatCents(item.transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DuePill extends StatelessWidget {
  const _DuePill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusFull),
      child: Container(
        height: 28,
        padding: EdgeInsets.symmetric(horizontal: tokens.space3),
        decoration: BoxDecoration(color: tokens.liabilityBg, borderRadius: BorderRadius.circular(tokens.radiusFull)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: tokens.liability, shape: BoxShape.circle)),
            SizedBox(width: 6),
            Text('待办 $count', style: TextStyle(fontSize: 12, color: tokens.liability, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _DueSheet extends StatelessWidget {
  const _DueSheet({required this.items});

  final List<DueItem> items;

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
            Text('近期待办', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
            SizedBox(height: tokens.space2),
            for (final item in items)
              InkWell(
                onTap: () => Navigator.of(context).pop(item.accountId),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space3),
                  child: Row(
                    children: [
                      Icon(
                        item.kind == 'deposit' ? LucideIcons.piggyBank : (item.kind == 'credit' ? LucideIcons.creditCard : LucideIcons.home),
                        size: 24,
                        color: item.urgent ? tokens.liability : tokens.primary,
                      ),
                      SizedBox(width: tokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tokens.textPrimary)),
                            SizedBox(height: 2),
                            Text(item.sub, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: tokens.textDisabled),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: EdgeInsets.only(top: tokens.space4),
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: Text(message, style: TextStyle(fontSize: 13, color: tokens.expense)),
    );
  }
}
