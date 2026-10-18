import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';

enum AccountKind { bank, stored, credit, deposit, loan }

extension AccountKindX on AccountKind {
  String get label {
    switch (this) {
      case AccountKind.bank:
        return '银行卡';
      case AccountKind.stored:
        return '储值卡';
      case AccountKind.credit:
        return '信用卡';
      case AccountKind.deposit:
        return '存单';
      case AccountKind.loan:
        return '贷款';
    }
  }

  String get description {
    switch (this) {
      case AccountKind.bank:
        return '名称、开户行、期初余额';
      case AccountKind.stored:
        return '商户、余额、默认消费类别';
      case AccountKind.credit:
        return '额度、账单日、还款日';
      case AccountKind.deposit:
        return '本金、利率、存期、起存日';
      case AccountKind.loan:
        return '本金、利率、期数、还款日';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountKind.bank:
        return LucideIcons.landmark;
      case AccountKind.stored:
        return LucideIcons.creditCard;
      case AccountKind.credit:
        return LucideIcons.creditCard;
      case AccountKind.deposit:
        return LucideIcons.piggyBank;
      case AccountKind.loan:
        return LucideIcons.home;
    }
  }
}

String accountTypeLabel(String type) {
  switch (type) {
    case 'bank':
      return '银行卡';
    case 'ewallet':
      return '电子钱包';
    case 'stored':
      return '储值卡';
    case 'credit':
      return '信用卡';
    case 'deposit':
      return '存单';
    case 'loan':
      return '贷款';
    case 'cash':
      return '现金';
    default:
      return type;
  }
}

IconData accountIcon(AccountWithBalance view) {
  final icon = view.account.icon;
  switch (icon) {
    case 'bank':
    case 'landmark':
      return LucideIcons.landmark;
    case 'wallet':
      return LucideIcons.wallet;
    case 'cart':
      return LucideIcons.shoppingCart;
    case 'credit':
      return LucideIcons.creditCard;
    case 'deposit':
      return LucideIcons.piggyBank;
    case 'mortgage':
    case 'loan':
      return LucideIcons.home;
    case 'car':
      return LucideIcons.car;
    case 'cash':
      return LucideIcons.banknote;
    default:
      return LucideIcons.wallet;
  }
}

String formatCents(int cents, {bool signed = false}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final yuan = abs ~/ 100;
  final fraction = (abs % 100).toString().padLeft(2, '0');
  final grouped = yuan.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match[1]},',
      );
  final sign = negative ? '-' : (signed && cents > 0 ? '+' : '');
  return '$sign¥$grouped.$fraction';
}

String formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int parseYuanToCents(String value) {
  final parsed = double.tryParse(value.trim()) ?? 0;
  return (parsed * 100).round();
}

String accountSubtitle(AccountWithBalance view, {Map<int, String> categoryNames = const {}}) {
  final account = view.account;
  switch (account.type) {
    case 'bank':
    case 'ewallet':
      return account.institution?.isNotEmpty == true
          ? account.institution!
          : accountTypeLabel(account.type);
    case 'stored':
      final category = view.card?.defaultCategoryId;
      final categoryName = category == null ? null : categoryNames[category];
      if (categoryName != null) return '储值卡 · 默认 $categoryName';
      return account.institution?.isNotEmpty == true ? account.institution! : '储值卡';
    case 'credit':
      final day = view.card?.repaymentDay;
      return day == null ? '信用卡' : '$day 号还款';
    case 'deposit':
      final deposit = view.deposit;
      if (deposit == null) return '存单';
      if (deposit.closedAt != null) {
        return deposit.closeType == 'renew' ? '存单 · 已转存' : '存单 · 已支取';
      }
      final maturity = DateTime.fromMillisecondsSinceEpoch(deposit.maturityAt);
      return '${(deposit.rateBp / 100).toStringAsFixed(2)}% · ${deposit.termMonths}个月 · 到期 ${formatDate(maturity)}';
    case 'loan':
      final loan = view.loan;
      if (loan == null) return '贷款';
      final due = DateTime.fromMillisecondsSinceEpoch(loan.nextDueAt);
      return '剩余本金 · 下次 ${formatDate(due)}';
    default:
      return account.institution?.isNotEmpty == true ? account.institution! : accountTypeLabel(account.type);
  }
}
