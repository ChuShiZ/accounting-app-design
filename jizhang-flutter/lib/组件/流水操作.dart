import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../数据/数据库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

/// 首页/报表等流水列表共用：长按删除普通流水，资产动作流水保持锁定。
Future<void> deleteTransactionWithConfirm(
  BuildContext context,
  WidgetRef ref,
  TransactionRow transaction,
) async {
  if (transaction.locked) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('资产动作流水不可单独编辑或删除')));
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除流水'),
      content: const Text('删除这笔流水？账户余额和报表会同步回退。'),
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
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(transactionRepositoryProvider).deleteById(transaction.id);
    ref.invalidate(homeProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(reportDataProvider);
    ref.invalidate(accountTransactionsProvider(transaction.accountId));
    messenger.showSnackBar(const SnackBar(content: Text('已删除流水')));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('删除失败：$error')));
  }
}
