import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../主题/令牌.dart';
import '账户展示.dart';

enum AccountDetailAction { edit, delete }

Future<AccountDetailAction?> showAccountDetail(
  BuildContext context,
  AccountWithBalance view, {
  Map<int, String> categoryNames = const {},
}) {
  return showModalBottomSheet<AccountDetailAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AccountDetailSheet(view: view, categoryNames: categoryNames),
  );
}

class _AccountDetailSheet extends StatelessWidget {
  const _AccountDetailSheet({required this.view, required this.categoryNames});

  final AccountWithBalance view;
  final Map<int, String> categoryNames;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final account = view.account;
    final isLiability = account.type == 'credit' || account.type == 'loan';
    final loan = view.loan;
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
                    decoration: BoxDecoration(
                      color: tokens.primaryLight,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                    ),
                    child: Icon(
                      accountIcon(view),
                      size: 20,
                      color: isLiability ? tokens.liability : tokens.primary,
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                        ),
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
              Container(
                padding: EdgeInsets.all(tokens.space4),
                decoration: BoxDecoration(
                  color: tokens.bg,
                  border: Border.all(color: tokens.border),
                  borderRadius: BorderRadius.circular(tokens.radiusLg),
                ),
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
                    Text(
                      accountSubtitle(view, categoryNames: categoryNames),
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.space4),
              if (loan != null) ...[
                _row(context, '贷款类型', _loanKindLabel(loan.kind)),
                _row(context, '原始本金', formatCents(loan.originalPrincipal)),
                _row(context, '年利率', '${(loan.rateBp / 100).toStringAsFixed(2)}%'),
                _row(context, '总期数', '${loan.termMonths} 个月'),
                _row(context, '起贷日', formatDate(DateTime.fromMillisecondsSinceEpoch(loan.startAt))),
                _row(context, '下次还款', formatDate(DateTime.fromMillisecondsSinceEpoch(loan.nextDueAt))),
                if ((loan.perAmount ?? 0) > 0) _row(context, '每期还款', formatCents(loan.perAmount!)),
                _row(context, '还款方式', _repaymentMethodLabel(loan.repaymentMethod)),
              ] else ...[
                _row(context, '账户类型', accountTypeLabel(account.type)),
                if (account.institution != null && account.institution!.isNotEmpty)
                  _row(context, '机构', account.institution!),
                if (account.type == 'stored') ...[
                  _row(context, '默认消费类别', _defaultCategoryName(view)),
                  _row(context, '近期流水', '批次 2 接入'),
                ] else
                  _row(context, '近期流水', '批次 2 接入'),
              ],
              if (account.note != null && account.note!.isNotEmpty) _row(context, '备注', account.note!),
              SizedBox(height: tokens.space6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(AccountDetailAction.edit),
                      icon: Icon(LucideIcons.pencil, size: 18),
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
                      icon: Icon(LucideIcons.trash2, size: 18),
                      label: const Text('删除'),
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: tokens.expense,
                      ),
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
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: tokens.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: tokens.textPrimary),
            ),
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
