import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';
import '关联贷款还款.dart';

enum AccountDetailAction { edit, delete, recharge, repay, settleEarly, settleMaturity, renew }

Future<AccountDetailAction?> showAccountDetail(
  BuildContext context,
  AccountWithBalance view, {
  Map<int, String> categoryNames = const {},
}) {
  return showModalBottomSheet<AccountDetailAction>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AccountDetailSheet(view: view, categoryNames: categoryNames),
  );
}

class _AccountDetailSheet extends ConsumerWidget {
  const _AccountDetailSheet({required this.view, required this.categoryNames});

  final AccountWithBalance view;
  final Map<int, String> categoryNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final account = view.account;
    final isLiability = account.type == 'credit' || account.type == 'loan';
    final isDefault = account.type == 'default';
    final loan = view.loan;
    final deposit = view.deposit;
    final closed = deposit?.closedAt != null;
    final transactions = ref.watch(accountTransactionsProvider(account.id));
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space1, tokens.space4, tokens.space4),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: tokens.primaryLight, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Icon(accountIcon(view), size: 20, color: isLiability ? tokens.liability : tokens.primary),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                        SizedBox(height: tokens.space1),
                        Text(
                          '${accountTypeLabel(account.type)}${account.institution == null || account.institution!.isEmpty ? '' : ' · ${account.institution}'}',
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                    tooltip: '关闭',
                  ),
                ],
              ),
              SizedBox(height: tokens.space4),
              if (isDefault)
                Container(
                  padding: EdgeInsets.all(tokens.space4),
                  decoration: BoxDecoration(color: tokens.surface2, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
                  child: Row(
                    children: [
                      Icon(LucideIcons.inbox, size: 24, color: tokens.textSecondary),
                      SizedBox(width: tokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('系统默认账户', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                            SizedBox(height: 2),
                            Text('未指定账户的流水归入这里，不参与余额统计', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(tokens.space4),
                  decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.type == 'credit' || account.type == 'loan' ? '剩余本金 / 待还' : '当前余额',
                        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                      ),
                      SizedBox(height: tokens.space1),
                      Text(
                        formatCents(isLiability ? view.balance.abs() : view.balance),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: isLiability ? tokens.liability : tokens.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      SizedBox(height: tokens.space1),
                      Text(accountSubtitle(view, categoryNames: categoryNames), style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                    ],
                  ),
                ),
              SizedBox(height: tokens.space4),
              if (deposit != null) ...[
                _row(context, '存单状态', closed ? (deposit.closeType == 'renew' ? '已转存' : '已支取') : '存续中'),
                _row(context, '存单本金', formatCents(deposit.principal)),
                _row(context, '年利率', '${(deposit.rateBp / 100).toStringAsFixed(2)}%'),
                _row(context, '存期', '${deposit.termMonths} 个月'),
                _row(context, '起存日', formatDate(DateTime.fromMillisecondsSinceEpoch(deposit.startAt))),
                _row(context, '到期日', formatDate(DateTime.fromMillisecondsSinceEpoch(deposit.maturityAt))),
                if (deposit.certificateNo?.isNotEmpty == true) _row(context, '存单号', deposit.certificateNo!),
                _row(
                  context,
                  '预计利息',
                  formatCents((deposit.principal * deposit.rateBp * deposit.termMonths / (10000 * 12)).round()),
                ),
                if (deposit.actualInterest != null) _row(context, '实际利息', formatCents(deposit.actualInterest!)),
              ] else ...[
                _row(context, '账户类型', accountTypeLabel(account.type)),
                if (account.institution != null && account.institution!.isNotEmpty) _row(context, '机构', account.institution!),
                if (account.type == 'stored') _row(context, '默认消费类别', _defaultCategoryName(view)),
                if (account.type == 'credit') ...[
                  _row(context, '信用额度', view.card?.creditLimit == null ? '未设置' : formatCents(view.card!.creditLimit!)),
                  _row(context, '账单日', view.card?.billingDay == null ? '未设置' : '${view.card!.billingDay} 号'),
                  _row(context, '还款日', view.card?.repaymentDay == null ? '未设置' : '${view.card!.repaymentDay} 号'),
                ],
                if (loan != null) ...[
                  _row(context, '贷款类型', _loanKindLabel(loan.kind)),
                  _row(context, '原始本金', formatCents(loan.originalPrincipal)),
                  _row(context, '年利率', '${(loan.rateBp / 100).toStringAsFixed(2)}%'),
                  _row(context, '总期数', '${loan.termMonths} 个月'),
                  _row(context, '起贷日', formatDate(DateTime.fromMillisecondsSinceEpoch(loan.startAt))),
                  _row(context, '下次还款', formatDate(DateTime.fromMillisecondsSinceEpoch(loan.nextDueAt))),
                  if ((loan.perAmount ?? 0) > 0) _row(context, '每期还款', formatCents(loan.perAmount!)),
                  _row(context, '还款方式', _repaymentMethodLabel(loan.repaymentMethod)),
                ],
              ],
              if (account.note != null && account.note!.isNotEmpty) _row(context, '备注', account.note!),
              SizedBox(height: tokens.space4),
              Row(
                children: [
                  Expanded(
                    child: Text('近期流水', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                  ),
                  Icon(LucideIcons.receipt, size: 16, color: tokens.textDisabled),
                ],
              ),
              SizedBox(height: tokens.space1),
              transactions.when(
                loading: () => Padding(padding: EdgeInsets.all(tokens.space3), child: Text('加载中…', style: TextStyle(fontSize: 12, color: tokens.textSecondary))),
                error: (error, stack) => Text('流水加载失败', style: TextStyle(fontSize: 12, color: tokens.expense)),
                data: (rows) {
                  if (rows.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: tokens.space3),
                      child: Text('暂无流水', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < rows.length; i++) ...[
                        _transactionRow(context, rows[i]),
                        if (i < rows.length - 1) Divider(height: 1, color: tokens.divider),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: tokens.space5),
              if (account.type == 'stored') ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(AccountDetailAction.recharge),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('充值'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                SizedBox(height: tokens.space2),
              ],
              if (account.type == 'loan') ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final linked = await showLoanRepaymentLinkSheet(context, ref, view);
                    if (linked != null && context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(LucideIcons.link2, size: 18),
                  label: const Text('关联历史还款'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: tokens.border),
                    foregroundColor: tokens.primary,
                  ),
                ),
                SizedBox(height: tokens.space2),
              ],
              if (account.type == 'credit' || account.type == 'loan') ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(AccountDetailAction.repay),
                  icon: const Icon(LucideIcons.banknote, size: 18),
                  label: const Text('还款'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                SizedBox(height: tokens.space2),
              ],
              if (deposit != null && !closed) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(AccountDetailAction.settleMaturity),
                  icon: const Icon(LucideIcons.piggyBank, size: 18),
                  label: const Text('到期支取'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                SizedBox(height: tokens.space2),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(AccountDetailAction.settleEarly),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                        child: const Text('提前支取'),
                      ),
                    ),
                    SizedBox(width: tokens.space2),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(AccountDetailAction.renew),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                        child: const Text('转存'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.space2),
              ],
              if (!isDefault)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(AccountDetailAction.edit),
                        icon: const Icon(LucideIcons.pencil, size: 18),
                        label: const Text('编辑'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(color: tokens.border),
                          foregroundColor: tokens.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.space3),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(AccountDetailAction.delete),
                        icon: const Icon(LucideIcons.trash2, size: 18),
                        label: const Text('删除'),
                        style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: tokens.expense),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionRow(BuildContext context, TransactionRow transaction) {
    final tokens = context.tokens;
    final type = transaction.type;
    final amount = transaction.amount;
    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';
    final incomingTransfer = isTransfer && transaction.toAccountId == view.account.id;
    final categoryId = transaction.categoryId;
    final categoryName = categoryNames[categoryId] ?? (isTransfer ? '账户转账' : '其他');
    final signedAmount = isTransfer ? (incomingTransfer ? amount : -amount) : (isIncome ? amount : -amount);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.space2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        categoryName,
                        style: TextStyle(fontSize: 14, color: tokens.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (transaction.locked)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(4)),
                        child: Text('内部', style: TextStyle(fontSize: 9, color: tokens.textSecondary)),
                      ),
                  ],
                ),
                SizedBox(height: 1),
                Text(
                  formatDate(DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt)),
                  style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${signedAmount >= 0 ? '+' : '-'}${formatCents(signedAmount.abs())}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: signedAmount >= 0 ? tokens.income : tokens.expense,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _defaultCategoryName(AccountWithBalance view) {
    final categoryId = view.card?.defaultCategoryId;
    if (categoryId == null) return '未设置';
    return categoryNames[categoryId] ?? '未设置';
  }

  Widget _row(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(vertical: tokens.space3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.divider))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: TextStyle(fontSize: 14, color: tokens.textSecondary))),
          SizedBox(width: tokens.space3),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
          ),
        ],
      ),
    );
  }

  String _loanKindLabel(String kind) {
    switch (kind) {
      case 'mortgage':
        return '房贷';
      case 'car':
        return '车贷';
      case 'consumer':
        return '消费贷';
      default:
        return '其他';
    }
  }

  String _repaymentMethodLabel(String method) {
    switch (method) {
      case 'equal_principal_interest':
        return '等额本息';
      case 'equal_principal':
        return '等额本金';
      case 'interest_only':
        return '先息后本';
      default:
        return '其他';
    }
  }
}
