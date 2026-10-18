import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../数据/仓库/交易仓库.dart';
import '../数据/仓库/类别仓库.dart';
import '../数据/仓库/报表仓库.dart';

class HomeTransaction {
  const HomeTransaction({
    required this.transaction,
    required this.categoryName,
    required this.categoryGroupName,
    required this.categoryIcon,
    required this.accountName,
    required this.accountType,
  });

  final TransactionRow transaction;
  final String categoryName;
  final String categoryGroupName;
  final String categoryIcon;
  final String accountName;
  final String accountType;
}

class HomeGroup {
  const HomeGroup({required this.label, required this.items, required this.expense});

  final String label;
  final List<HomeTransaction> items;
  final int expense;
}

class DueItem {
  const DueItem({
    required this.kind,
    required this.accountId,
    required this.title,
    required this.sub,
    required this.days,
    required this.urgent,
  });

  final String kind;
  final int accountId;
  final String title;
  final String sub;
  final int days;
  final bool urgent;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.todayExpense,
    required this.monthIncome,
    required this.monthExpense,
    required this.groups,
    required this.dueItems,
  });

  final int todayExpense;
  final int monthIncome;
  final int monthExpense;
  final List<HomeGroup> groups;
  final List<DueItem> dueItems;

  int get monthBalance => monthIncome - monthExpense;
}

class HomeRepository {
  HomeRepository(this.db);

  final AppDatabase db;

  Future<HomeSnapshot> snapshot({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0, 23, 59, 59, 999);

    final accounts = await AccountRepository(db).listWithBalances();
    final accountMap = {for (final a in accounts) a.account.id: a};
    final categories = await CategoryRepository(db).listAll();
    final categoryById = {for (final c in categories) c.id: c};
    final rows = await TransactionRepository(db).listRecent(limit: 300, reportableOnly: false);
    final visible = rows.where((t) {
      final account = accountMap[t.accountId]?.account;
      if (t.reportable) return true;
      return t.type == 'expense' && account?.type == 'stored';
    }).toList();

    final transactionViews = visible
        .map((t) {
              final category = t.categoryId == null ? null : categoryById[t.categoryId];
              final group = category == null
                  ? null
                  : (category.parentId == null ? category : categoryById[category.parentId]);
              return HomeTransaction(
                transaction: t,
                categoryName: category?.name ?? group?.name ?? '其他',
                categoryGroupName: group?.name ?? '',
                categoryIcon: category?.icon ?? group?.icon ?? 'other',
                accountName: accountMap[t.accountId]?.account.name ?? '',
                accountType: accountMap[t.accountId]?.account.type ?? '',
              );
            })
        .toList();

    final groups = <String, List<HomeTransaction>>{};
    final yesterday = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1));
    for (final view in transactionViews) {
      final date = DateTime.fromMillisecondsSinceEpoch(view.transaction.occurredAt);
      final sameToday = date.year == today.year && date.month == today.month && date.day == today.day;
      final sameYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
      final key = sameToday ? '今天' : (sameYesterday ? '昨天' : '${date.month}-${date.day.toString().padLeft(2, '0')}');
      groups.putIfAbsent(key, () => []).add(view);
    }
    final homeGroups = groups.entries.map((entry) {
      var expense = 0;
      for (final item in entry.value) {
        if (item.transaction.type == 'expense' && item.transaction.reportable) {
          expense += item.transaction.amount;
        }
      }
      return HomeGroup(label: entry.key, items: entry.value, expense: expense);
    }).toList();

    var todayExpense = 0;
    for (final view in transactionViews) {
      final t = view.transaction;
      final date = DateTime.fromMillisecondsSinceEpoch(t.occurredAt);
      if (t.type == 'expense' && t.reportable && !date.isBefore(startOfDay) && !date.isAfter(endOfDay)) {
        todayExpense += t.amount;
      }
    }
    final month = await ReportRepository(db).totalsFor(monthStart, monthEnd);
    final due = await _dueItems(today, accounts);

    return HomeSnapshot(
      todayExpense: todayExpense,
      monthIncome: month.income,
      monthExpense: month.expense,
      groups: homeGroups,
      dueItems: due,
    );
  }

  Future<List<DueItem>> _dueItems(DateTime today, List<AccountWithBalance> accounts) async {
    final items = <DueItem>[];
    final deposits = await db.select(db.depositDetails).get();
    final depositMap = {for (final d in deposits) d.accountId: d};
    for (final view in accounts) {
      final account = view.account;
      if (account.type == 'deposit') {
        final d = depositMap[account.id];
        if (d == null || d.closedAt != null) continue;
        final maturity = DateTime.fromMillisecondsSinceEpoch(d.maturityAt);
        final days = DateTime(maturity.year, maturity.month, maturity.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;
        if (days <= 30) {
          items.add(DueItem(
            kind: 'deposit',
            accountId: account.id,
            title: account.name,
            sub: days < 0 ? '已到期 · 待支取' : (days == 0 ? '今天到期' : '还有 $days 天到期'),
            days: days,
            urgent: days <= 0,
          ));
        }
      }
      if (account.type == 'credit' && view.balance < 0) {
        final day = view.card?.repaymentDay;
        if (day != null && day > 0) {
          var next = DateTime(today.year, today.month, day);
          if (next.isBefore(DateTime(today.year, today.month, today.day))) {
            next = DateTime(today.year, today.month + 1, day);
          }
          final days = next.difference(DateTime(today.year, today.month, today.day)).inDays;
          if (days <= 7) {
            items.add(DueItem(
              kind: 'credit',
              accountId: account.id,
              title: account.name,
              sub: days == 0 ? '今天还款日' : '还款日还有 $days 天',
              days: days,
              urgent: days <= 0,
            ));
          }
        }
      }
      if (account.type == 'loan' && view.loan != null) {
        final due = DateTime.fromMillisecondsSinceEpoch(view.loan!.nextDueAt);
        final days = DateTime(due.year, due.month, due.day)
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;
        if (days <= 7) {
          items.add(DueItem(
            kind: 'loan',
            accountId: account.id,
            title: account.name,
            sub: '下次还款 ${due.month}-${due.day.toString().padLeft(2, '0')}',
            days: days,
            urgent: days <= 0,
          ));
        }
      }
    }
    items.sort((a, b) => a.days.compareTo(b.days));
    return items;
  }
}
