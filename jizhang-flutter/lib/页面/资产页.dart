import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/账户详情.dart';
import '../组件/账户展示.dart';
import '../组件/账户表单.dart';
import '../组件/存单表单.dart';
import '../组件/存单动作.dart';
import '../组件/充值表单.dart';
import '../组件/还款表单.dart';
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
            onOpenDeposits: () => context.push('/deposits'),
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
    required this.onOpenDeposits,
  });

  final List<AccountWithBalance> accounts;
  final Map<int, String> categoryNames;
  final ValueChanged<AccountWithBalance> onTap;
  final VoidCallback onOpenDeposits;

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
            _DepositEntry(
              deposits: deposits,
              onTap: onOpenDeposits,
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

class _DepositEntry extends StatelessWidget {
  const _DepositEntry({required this.deposits, required this.onTap});

  final List<AccountWithBalance> deposits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final active = deposits.where((view) => view.deposit?.closedAt == null).toList();
    final ended = deposits.where((view) => view.deposit?.closedAt != null).toList();
    var principal = 0;
    var interest = 0;
    int? nearestMaturity;
    for (final view in active) {
      final detail = view.deposit;
      if (detail == null) continue;
      principal += detail.principal;
      interest += (detail.principal * detail.rateBp * detail.termMonths / (10000 * 12)).round();
      if (nearestMaturity == null || detail.maturityAt < nearestMaturity) {
        nearestMaturity = detail.maturityAt;
      }
    }
    final title = deposits.isEmpty
        ? '还没有存单'
        : (active.isEmpty ? '已结束 ${ended.length} 张' : '存续 ${active.length} 张');
    final subtitle = deposits.isEmpty
        ? '点此添加第一张存单'
        : (active.isEmpty
            ? '查看历史存单'
            : '预计利息 ${formatCents(interest)}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('存单', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
            TextButton(onPressed: onTap, child: const Text('查看全部')),
          ],
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          child: Container(
            padding: EdgeInsets.all(tokens.space4),
            decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
            child: Row(
              children: [
                Icon(LucideIcons.piggyBank, size: 24, color: deposits.isEmpty ? tokens.textDisabled : tokens.primary),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
                          Text(
                            active.isEmpty ? '—' : formatCents(principal),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: tokens.textSecondary))),
                          if (nearestMaturity != null)
                            Text(
                              '最近到期 ${formatDate(DateTime.fromMillisecondsSinceEpoch(nearestMaturity))}',
                              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: tokens.space1),
                Icon(LucideIcons.chevronRight, size: 18, color: tokens.textDisabled),
              ],
            ),
          ),
        ),
      ],
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
