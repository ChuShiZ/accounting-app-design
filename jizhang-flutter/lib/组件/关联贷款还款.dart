import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/资产仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';
import '类别展示.dart';

Future<int?> showLoanRepaymentLinkSheet(
  BuildContext context,
  WidgetRef ref,
  AccountWithBalance view,
) async {
  final candidates = await ref.read(loanRepaymentCandidatesProvider(view.account.id).future);
  if (!context.mounted) return null;
  return showModalBottomSheet<int>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LoanRepaymentLinkSheet(loan: view, candidates: candidates),
  );
}

class LoanRepaymentLinkSheet extends ConsumerStatefulWidget {
  const LoanRepaymentLinkSheet({super.key, required this.loan, required this.candidates});

  final AccountWithBalance loan;
  final List<LoanRepaymentCandidate> candidates;

  @override
  ConsumerState<LoanRepaymentLinkSheet> createState() => _LoanRepaymentLinkSheetState();
}

class _LoanRepaymentLinkSheetState extends ConsumerState<LoanRepaymentLinkSheet> {
  late final Set<int> _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selected = {
      for (final candidate in widget.candidates)
        if (candidate.selectedByDefault) candidate.transaction.id,
    };
  }

  int get _selectedCount => _selected.length;

  int get _selectedTotal {
    var total = 0;
    for (final candidate in widget.candidates) {
      if (_selected.contains(candidate.transaction.id)) total += candidate.transaction.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final allSelected = widget.candidates.isNotEmpty && _selectedCount == widget.candidates.length;
    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl)),
      ),
      child: Column(
        children: [
          SizedBox(height: tokens.space2),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull))),
          Padding(
            padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space1),
            child: Row(
              children: [
                Expanded(
                  child: Text('关联历史还款', style: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
                ),
                IconButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                  tooltip: '关闭',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '选择已记录的支出，关联到「${widget.loan.account.name}」的历史还款。',
                  style: TextStyle(fontSize: 12, height: 1.5, color: tokens.textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  '关联后当前剩余本金保持不变；这些流水会锁定为资产动作，不能单独编辑或删除。',
                  style: TextStyle(fontSize: 11, height: 1.5, color: tokens.liability),
                ),
                SizedBox(height: tokens.space3),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: tokens.space2),
                  decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '已选 $_selectedCount 笔 · 合计 ${formatCents(_selectedTotal)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy || widget.candidates.isEmpty
                            ? null
                            : () => setState(() {
                                  if (allSelected) {
                                    _selected.clear();
                                  } else {
                                    _selected
                                      ..clear()
                                      ..addAll(widget.candidates.map((candidate) => candidate.transaction.id));
                                  }
                                }),
                        child: Text(allSelected ? '取消全选' : '全选'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.space2),
          Expanded(
            child: widget.candidates.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.space6),
                      child: Text(
                        '没有找到可关联的流水。\n请确认历史支出已归到金融/房贷/车贷/贷款，或备注里包含“还款”。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, height: 1.5, color: tokens.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: tokens.space4),
                    itemCount: widget.candidates.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: tokens.divider),
                    itemBuilder: (context, index) {
                      final candidate = widget.candidates[index];
                      final transaction = candidate.transaction;
                      final selected = _selected.contains(transaction.id);
                      final title = transaction.note?.trim().isNotEmpty == true ? transaction.note!.trim() : candidate.categoryName;
                      return InkWell(
                        onTap: _busy ? null : () => _toggle(transaction.id),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: tokens.space2),
                          child: Row(
                            children: [
                              Checkbox(
                                value: selected,
                                onChanged: _busy ? null : (_) => _toggle(transaction.id),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              SizedBox(width: tokens.space1),
                              Icon(categoryIconData(candidate.categoryIcon), size: 22, color: categoryColor(candidate.categoryIcon)),
                              SizedBox(width: tokens.space2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: tokens.textPrimary)),
                                    SizedBox(height: 2),
                                    Text(
                                      '${formatDate(DateTime.fromMillisecondsSinceEpoch(transaction.occurredAt))} · ${candidate.accountName} · ${candidate.categoryName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: tokens.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: tokens.space2),
                              Text(
                                formatCents(transaction.amount),
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.expense, fontFeatures: const [FontFeature.tabularFigures()]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space4, tokens.space4),
            decoration: BoxDecoration(color: tokens.bg, border: Border(top: BorderSide(color: tokens.border))),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                    child: const Text('取消'),
                  ),
                ),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy || _selectedCount == 0 ? null : _confirm,
                    child: Text(_busy ? '关联中…' : '关联 $_selectedCount 笔'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(int id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _confirm() async {
    final tokens = context.tokens;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认关联历史还款'),
        content: Text(
          '将 $_selectedCount 笔支出（合计 ${formatCents(_selectedTotal)}）关联到「${widget.loan.account.name}」？\n\n'
          '当前剩余本金保持不变，会同步调整贷款的初始欠款；关联后这些流水会锁定，不能单独编辑或删除。',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: tokens.primary),
            child: const Text('确认关联'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final count = await ref.read(assetRepositoryProvider).bindLoanRepayments(
            loanAccountId: widget.loan.account.id,
            transactionIds: _selected.toList(),
          );
      ref.invalidate(accountsProvider);
      ref.invalidate(accountTransactionsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      ref.invalidate(loanRepaymentCandidatesProvider(widget.loan.account.id));
      if (!mounted) return;
      Navigator.of(context).pop(count);
      messenger.showSnackBar(SnackBar(content: Text('已关联 $count 笔历史还款')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('关联失败：$error')));
    }
  }
}
