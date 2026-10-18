import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/存单动作.dart';
import '../组件/存单表单.dart';
import '../组件/账户详情.dart';
import '../组件/账户展示.dart';
import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

enum _DepositFilter { all, active, expiring, ended }

enum _DepositSort { maturity, amount, rate }

class DepositPage extends ConsumerStatefulWidget {
  const DepositPage({super.key});

  @override
  ConsumerState<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends ConsumerState<DepositPage> {
  _DepositFilter _filter = _DepositFilter.all;
  _DepositSort _sort = _DepositSort.maturity;
  bool _endedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsAsync = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <CategoryRow>[];
    final categoryNames = {for (final category in categories) category.id: category.name};
    return Scaffold(
      backgroundColor: tokens.surface,
      body: PageScaffold(
        title: '存单',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: tokens.textPrimary),
          tooltip: '返回',
        ),
        action: IconButton(
          onPressed: () => showDepositForm(context),
          icon: Icon(LucideIcons.plus, color: tokens.textPrimary),
          tooltip: '添加存单',
        ),
        child: accountsAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.space10),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary)),
          ),
          error: (error, stack) => Text('存单加载失败：$error', style: TextStyle(color: tokens.expense)),
          data: (accounts) {
            final deposits = accounts.where((view) => view.account.type == 'deposit').toList();
            if (deposits.isEmpty) return _emptyState(context);
            return _content(context, deposits, categoryNames);
          },
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: EdgeInsets.only(top: tokens.space8),
      padding: EdgeInsets.all(tokens.space6),
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusXl)),
      child: Column(
        children: [
          Icon(LucideIcons.piggyBank, size: 40, color: tokens.textDisabled),
          SizedBox(height: tokens.space3),
          Text('还没有存单', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
          SizedBox(height: tokens.space1),
          Text('把定期存款集中管理，到期前会提醒你', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, height: 1.5, color: tokens.textSecondary)),
          SizedBox(height: tokens.space4),
          FilledButton.icon(
            onPressed: () => showDepositForm(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('添加第一张存单'),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, List<AccountWithBalance> deposits, Map<int, String> categoryNames) {
    final tokens = context.tokens;
    final today = DateTime.now();
    final active = deposits.where((view) => view.deposit?.closedAt == null).toList();
    final ended = deposits.where((view) => view.deposit?.closedAt != null).toList();
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

    final list = <Widget>[
      _hero(
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
    ];

    switch (_filter) {
      case _DepositFilter.all:
        list.add(activeSorted.isEmpty ? emptyHint('暂无存续存单') : _listCard(context, activeSorted, categoryNames));
        if (endedSorted.isNotEmpty) {
          list.add(SizedBox(height: tokens.space2));
          list.add(_endedHeader(context, endedSorted.length));
          if (_endedExpanded) {
            list.add(_listCard(context, endedSorted, categoryNames));
          }
        }
        break;
      case _DepositFilter.active:
        list.add(activeSorted.isEmpty ? emptyHint('暂无存续存单') : _listCard(context, activeSorted, categoryNames));
        break;
      case _DepositFilter.expiring:
        list.add(expiringSorted.isEmpty ? emptyHint('30 天内没有到期的存单') : _listCard(context, expiringSorted, categoryNames));
        break;
      case _DepositFilter.ended:
        list.add(endedSorted.isEmpty ? emptyHint('暂无已结束存单') : _listCard(context, endedSorted, categoryNames));
        break;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: list);
  }

  Widget _hero(
    BuildContext context, {
    required int totalPrincipal,
    required int totalInterest,
    required int activeCount,
    required int expiringCount,
    required DateTime? nearestMaturity,
  }) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tokens.primary, tokens.primaryHover],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.piggyBank, size: 20, color: Colors.white.withValues(alpha: .85)),
              SizedBox(width: 6),
              Text('存单资产', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: .85))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(tokens.radiusFull)),
                child: Text('$activeCount 张存续', style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: tokens.space3),
          Text(
            formatCents(totalPrincipal),
            style: const TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w700, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          SizedBox(height: tokens.space4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('预计利息', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .7))),
                    SizedBox(height: 2),
                    Text(formatCents(totalInterest), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()])),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('最近到期', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .7))),
                    SizedBox(height: 2),
                    Text(nearestMaturity == null ? '--' : formatDate(nearestMaturity), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (expiringCount > 0) ...[
            SizedBox(height: tokens.space3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(tokens.radiusMd)),
              child: Row(
                children: [
                  Icon(LucideIcons.calendarClock, size: 14, color: Colors.white.withValues(alpha: .9)),
                  SizedBox(width: 6),
                  Text('30 天内到期 $expiringCount 张，记得处理', style: const TextStyle(fontSize: 11, color: Colors.white)),
                ],
              ),
            ),
          ],
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

  Widget _listCard(BuildContext context, List<AccountWithBalance> items, Map<int, String> categoryNames) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _DepositRow(
              view: items[i],
              onTap: () => _openDetail(items[i], categoryNames),
            ),
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

  Future<void> _openDetail(AccountWithBalance view, Map<int, String> categoryNames) async {
    final action = await showAccountDetail(context, view, categoryNames: categoryNames);
    if (action == null || !mounted) return;
    if (action == AccountDetailAction.settleEarly) {
      await showDepositSettleSheet(context, view, mode: 'early');
    } else if (action == AccountDetailAction.settleMaturity) {
      await showDepositSettleSheet(context, view, mode: 'maturity');
    } else if (action == AccountDetailAction.renew) {
      await showDepositRenewSheet(context, view);
    } else if (action == AccountDetailAction.edit) {
      await showDepositForm(context, account: view);
    } else if (action == AccountDetailAction.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除存单'),
          content: Text('删除「${view.account.name}」？有流水的存单会归档，历史流水保留。'),
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
      if (confirmed == true && mounted) {
        await ref.read(assetRepositoryProvider).deleteDeposit(view.account.id);
      }
    }
    ref.invalidate(accountsProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(reportDataProvider);
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
