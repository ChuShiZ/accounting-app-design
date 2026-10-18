import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/账户详情.dart';
import '../组件/账户展示.dart';
import '../组件/账户表单.dart';
import '../组件/存单表单.dart';
import '../组件/存单动作.dart';
import '../组件/充值表单.dart';
import '../组件/还款表单.dart';
import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class AssetsPage extends ConsumerWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final categoryNames = {for (final c in categories) c.id: c.name};
    final tokens = context.tokens;
    return PageScaffold(
      title: '资产',
      action: IconButton(
        onPressed: () => _addAccount(context),
        icon: Icon(LucideIcons.plus, color: tokens.textPrimary),
        tooltip: '添加账户',
      ),
      child: accounts.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space10),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary),
            ),
          ),
        ),
        error: (error, stack) => _ErrorCard(message: '账户加载失败：$error'),
        data: (list) {
          if (list.isEmpty) return _EmptyAccounts(onAdd: () => _addAccount(context));
          return _AccountGroups(
            accounts: list,
            categoryNames: categoryNames,
            onTap: (view) => _openDetail(context, ref, view, categoryNames),
            onAddDeposit: () => showDepositForm(context),
          );
        },
      ),
    );
  }

  Future<void> _addAccount(BuildContext context) async {
    final kind = await showModalBottomSheet<AccountKind>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _AddAccountSheet(),
    );
    if (kind == null || !context.mounted) return;
    if (kind == AccountKind.deposit) {
      await showDepositForm(context);
      return;
    }
    await showAccountForm(context, kind: kind);
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    AccountWithBalance view,
    Map<int, String> categoryNames,
  ) async {
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
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
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
}

class _AccountGroups extends StatelessWidget {
  const _AccountGroups({
    required this.accounts,
    required this.categoryNames,
    required this.onTap,
    required this.onAddDeposit,
  });

  final List<AccountWithBalance> accounts;
  final Map<int, String> categoryNames;
  final ValueChanged<AccountWithBalance> onTap;
  final VoidCallback onAddDeposit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final deposits = accounts.where((a) => a.account.type == 'deposit').toList();
    final groups = <String, List<AccountWithBalance>>{
      '默认账户': accounts.where((a) => a.account.type == 'default').toList(),
      '账户': accounts.where((a) => ['bank', 'ewallet', 'cash'].contains(a.account.type)).toList(),
      '储值卡': accounts.where((a) => a.account.type == 'stored').toList(),
      '存单': deposits,
      '信用卡': accounts.where((a) => a.account.type == 'credit').toList(),
      '贷款': accounts.where((a) => a.account.type == 'loan').toList(),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in groups.entries)
          if (entry.key == '存单')
            _DepositSection(
              deposits: deposits,
              onTap: onTap,
              onAdd: onAddDeposit,
            )
          else if (entry.value.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(top: tokens.space2, bottom: tokens.space2),
              child: Text(entry.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
            ),
            Container(
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < entry.value.length; i++) ...[
                    _AccountTile(
                      view: entry.value[i],
                      categoryNames: categoryNames,
                      onTap: () => onTap(entry.value[i]),
                    ),
                    if (i < entry.value.length - 1) Divider(height: 1, indent: 60, color: tokens.divider),
                  ],
                ],
              ),
            ),
          ],
        SizedBox(height: tokens.space3),
      ],
    );
  }
}

enum _DepositFilter { all, active, expiring, ended }

enum _DepositSort { maturity, amount, rate }

class _DepositSection extends StatefulWidget {
  const _DepositSection({required this.deposits, required this.onTap, required this.onAdd});

  final List<AccountWithBalance> deposits;
  final ValueChanged<AccountWithBalance> onTap;
  final VoidCallback onAdd;

  @override
  State<_DepositSection> createState() => _DepositSectionState();
}

class _DepositSectionState extends State<_DepositSection> {
  _DepositFilter _filter = _DepositFilter.all;
  _DepositSort _sort = _DepositSort.maturity;
  bool _endedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final today = DateTime.now();
    final active = widget.deposits.where((view) => view.deposit?.closedAt == null).toList();
    final ended = widget.deposits.where((view) => view.deposit?.closedAt != null).toList();
    final activeSorted = _sorted(active, ended: false);
    final endedSorted = _sorted(ended, ended: true);
    final expiring = active.where((view) => _daysLeft(view, today) <= 30).toList();
    final expiringSorted = _sorted(expiring, ended: false);

    var totalPrincipal = 0;
    var totalInterest = 0;
    int? nearestMaturity;
    for (final view in active) {
      final detail = view.deposit;
      if (detail == null) continue;
      totalPrincipal += detail.principal;
      totalInterest += _expectedInterest(detail);
      if (nearestMaturity == null || detail.maturityAt < nearestMaturity) {
        nearestMaturity = detail.maturityAt;
      }
    }
    final expiringCount = expiring.where((view) {
      final days = _daysLeft(view, today);
      return days >= 0 && days <= 30;
    }).length;

    Widget emptyHint(String text) => Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space5),
          child: Center(child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
        );

    final content = <Widget>[];
    if (widget.deposits.isEmpty) {
      content.add(Container(
        padding: EdgeInsets.symmetric(vertical: tokens.space6, horizontal: tokens.space4),
        decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
        child: Column(
          children: [
            Icon(LucideIcons.piggyBank, size: 26, color: tokens.textDisabled),
            SizedBox(height: tokens.space2),
            Text('还没有存单', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
            SizedBox(height: tokens.space1),
            Text('添加一张存单，到期前会提醒你', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
          ],
        ),
      ));
    } else {
      content.addAll([
        _summaryCard(
          context,
          totalPrincipal: totalPrincipal,
          totalInterest: totalInterest,
          activeCount: active.length,
          expiringCount: expiringCount,
          nearestMaturity: nearestMaturity == null ? null : DateTime.fromMillisecondsSinceEpoch(nearestMaturity),
        ),
        SizedBox(height: tokens.space3),
        _filterBar(context),
        SizedBox(height: tokens.space2),
      ]);
      switch (_filter) {
        case _DepositFilter.all:
          if (activeSorted.isEmpty) {
            content.add(emptyHint('暂无存续存单'));
          } else {
            content.add(_listCard(context, activeSorted));
          }
          if (endedSorted.isNotEmpty) {
            content.add(SizedBox(height: tokens.space2));
            content.add(_endedHeader(context, endedSorted.length));
            if (_endedExpanded) content.add(_listCard(context, endedSorted));
          }
          break;
        case _DepositFilter.active:
          content.add(activeSorted.isEmpty ? emptyHint('暂无存续存单') : _listCard(context, activeSorted));
          break;
        case _DepositFilter.expiring:
          content.add(expiringSorted.isEmpty ? emptyHint('30 天内没有到期的存单') : _listCard(context, expiringSorted));
          break;
        case _DepositFilter.ended:
          content.add(endedSorted.isEmpty ? emptyHint('暂无已结束存单') : _listCard(context, endedSorted));
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('存单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
            TextButton(onPressed: widget.onAdd, child: const Text('添加存单')),
          ],
        ),
        ...content,
      ],
    );
  }

  Widget _summaryCard(
    BuildContext context, {
    required int totalPrincipal,
    required int totalInterest,
    required int activeCount,
    required int expiringCount,
    required DateTime? nearestMaturity,
  }) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('存单本金', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                    SizedBox(height: 2),
                    Text(formatCents(totalPrincipal), style: TextStyle(fontSize: 24, height: 1.2, fontWeight: FontWeight.w700, color: tokens.textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                    SizedBox(height: 2),
                    Text('存续 $activeCount 张', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('预计利息', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                    SizedBox(height: 2),
                    Text(formatCents(totalInterest), style: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w600, color: tokens.income, fontFeatures: const [FontFeature.tabularFigures()])),
                    SizedBox(height: 2),
                    Text('30 天内到期 $expiringCount 张', style: TextStyle(fontSize: 11, color: tokens.textSecondary), textAlign: TextAlign.right),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.space2),
          Row(
            children: [
              Icon(LucideIcons.calendarClock, size: 14, color: tokens.textSecondary),
              SizedBox(width: 4),
              Text(
                nearestMaturity == null ? '最近到期：--' : '最近到期：${formatDate(nearestMaturity)}',
                style: TextStyle(fontSize: 11, color: tokens.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context) {
    final tokens = context.tokens;
    final filters = <(_DepositFilter, String)>[
      (_DepositFilter.all, '全部'),
      (_DepositFilter.active, '存续中'),
      (_DepositFilter.expiring, '即将到期'),
      (_DepositFilter.ended, '已结束'),
    ];
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in filters) ...[
                  InkWell(
                    onTap: () => setState(() => _filter = value),
                    borderRadius: BorderRadius.circular(tokens.radiusFull),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _filter == value ? tokens.primaryLight : tokens.surface2,
                        borderRadius: BorderRadius.circular(tokens.radiusFull),
                        border: Border.all(color: _filter == value ? tokens.primary : Colors.transparent),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(fontSize: 12, color: _filter == value ? tokens.primary : tokens.textSecondary, fontWeight: _filter == value ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.space1),
                ],
              ],
            ),
          ),
        ),
        PopupMenuButton<_DepositSort>(
          initialValue: _sort,
          tooltip: '排序',
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (context) => const [
            PopupMenuItem(value: _DepositSort.maturity, child: Text('按到期日')),
            PopupMenuItem(value: _DepositSort.amount, child: Text('按金额')),
            PopupMenuItem(value: _DepositSort.rate, child: Text('按利率')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusFull)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_sortLabel, style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                SizedBox(width: 3),
                Icon(LucideIcons.arrowUpDown, size: 13, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _listCard(BuildContext context, List<AccountWithBalance> items) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _DepositRow(view: items[i], onTap: () => widget.onTap(items[i])),
            if (i < items.length - 1) Divider(height: 1, indent: 48, color: tokens.divider),
          ],
        ],
      ),
    );
  }

  Widget _endedHeader(BuildContext context, int count) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () => setState(() => _endedExpanded = !_endedExpanded),
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Expanded(child: Text('已结束存单（$count）', style: TextStyle(fontSize: 13, color: tokens.textSecondary, fontWeight: FontWeight.w500))),
            Icon(_endedExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight, size: 16, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case _DepositSort.amount:
        return '金额';
      case _DepositSort.rate:
        return '利率';
      case _DepositSort.maturity:
        return '到期日';
    }
  }

  List<AccountWithBalance> _sorted(List<AccountWithBalance> input, {required bool ended}) {
    final copy = List<AccountWithBalance>.from(input);
    copy.sort((a, b) {
      final da = a.deposit;
      final db = b.deposit;
      if (da == null || db == null) return 0;
      switch (_sort) {
        case _DepositSort.amount:
          return db.principal.compareTo(da.principal);
        case _DepositSort.rate:
          return db.rateBp.compareTo(da.rateBp);
        case _DepositSort.maturity:
          final comparison = da.maturityAt.compareTo(db.maturityAt);
          return ended ? -comparison : comparison;
      }
    });
    return copy;
  }

  int _daysLeft(AccountWithBalance view, DateTime today) {
    final detail = view.deposit;
    if (detail == null) return 0;
    final maturity = DateTime.fromMillisecondsSinceEpoch(detail.maturityAt);
    return DateTime(maturity.year, maturity.month, maturity.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  int _expectedInterest(DepositDetailRow detail) {
    return (detail.principal * detail.rateBp * detail.termMonths / (10000 * 12)).round();
  }
}

class _DepositRow extends StatelessWidget {
  const _DepositRow({required this.view, required this.onTap});

  final AccountWithBalance view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final detail = view.deposit;
    if (detail == null) return const SizedBox.shrink();
    final today = DateTime.now();
    final maturity = DateTime.fromMillisecondsSinceEpoch(detail.maturityAt);
    final start = DateTime.fromMillisecondsSinceEpoch(detail.startAt);
    final closed = detail.closedAt != null;
    final days = DateTime(maturity.year, maturity.month, maturity.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    final status = closed
        ? (detail.closeType == 'renew' ? '已转存' : '已支取')
        : (days < 0 ? '已到期' : (days == 0 ? '今天到期' : '剩 $days 天'));
    final statusColor = closed ? tokens.textSecondary : (days <= 30 ? tokens.liability : tokens.income);
    final totalDays = maturity.difference(start).inDays;
    final progress = closed ? 1.0 : (totalDays <= 0 ? 0.0 : (today.difference(start).inDays / totalDays).clamp(0.0, 1.0));
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: 10),
        child: Row(
          children: [
            Icon(LucideIcons.piggyBank, size: 22, color: closed ? tokens.textDisabled : tokens.primary),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          view.account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tokens.textPrimary),
                        ),
                      ),
                      SizedBox(width: tokens.space2),
                      Text(
                        formatCents(detail.principal),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: closed ? tokens.textSecondary : tokens.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${view.account.institution?.isNotEmpty == true ? view.account.institution : '存单'} · ${(detail.rateBp / 100).toStringAsFixed(2)}% · ${detail.termMonths}个月',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                        ),
                      ),
                      SizedBox(width: tokens.space2),
                      Text(formatDate(maturity), style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      if (!closed)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(tokens.radiusFull),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 2,
                              backgroundColor: tokens.surface2,
                              valueColor: AlwaysStoppedAnimation(statusColor),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      SizedBox(width: 6),
                      Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space1),
            Icon(LucideIcons.chevronRight, size: 16, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }
}


class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.view, required this.categoryNames, required this.onTap});

  final AccountWithBalance view;
  final Map<int, String> categoryNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isLiability = view.account.type == 'credit' || view.account.type == 'loan';
    final isDefault = view.account.type == 'default';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
        child: Row(
          children: [
            Icon(
              accountIcon(view),
              size: 24,
              color: isLiability ? tokens.liability : tokens.primary,
            ),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          view.account.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: tokens.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isDefault) ...[
                        SizedBox(width: tokens.space2),
                        Text(
                          formatCents(isLiability ? view.balance.abs() : view.balance),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isLiability ? tokens.liability : tokens.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    accountSubtitle(view, categoryNames: categoryNames),
                    style: TextStyle(fontSize: 12, height: 1.3, color: tokens.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.space1),
            Icon(LucideIcons.chevronRight, size: 18, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }
}

class _AddAccountSheet extends StatelessWidget {
  const _AddAccountSheet();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('添加账户', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
            SizedBox(height: tokens.space1),
            Text('银行卡 / 储值卡 / 信用卡 / 存单 / 贷款', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
            SizedBox(height: tokens.space3),
            for (final kind in AccountKind.values) ...[
              InkWell(
                onTap: () => Navigator.of(context).pop(kind),
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space3),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: tokens.primaryLight,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                        ),
                        child: Icon(kind.icon, size: 20, color: tokens.primary),
                      ),
                      SizedBox(width: tokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(kind.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                            SizedBox(height: 2),
                            Text(kind.description, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 18, color: tokens.textDisabled),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: tokens.divider),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space10),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: tokens.primaryLight, borderRadius: BorderRadius.circular(tokens.radiusFull)),
            child: Icon(LucideIcons.wallet, size: 26, color: tokens.primary),
          ),
          SizedBox(height: tokens.space3),
          Text('还没有账户', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
          SizedBox(height: tokens.space1),
          Text('先添加一张银行卡、储值卡、信用卡或贷款', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
          SizedBox(height: tokens.space4),
          FilledButton(onPressed: onAdd, child: const Text('添加账户')),
        ],
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
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Text(message, style: TextStyle(fontSize: 13, color: tokens.expense)),
    );
  }
}
