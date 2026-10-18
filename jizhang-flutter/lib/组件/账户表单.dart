import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';

Future<void> showAccountForm(
  BuildContext context, {
  required AccountKind kind,
  AccountWithBalance? account,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AccountFormSheet(kind: kind, account: account),
  );
}

class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, required this.kind, this.account});

  final AccountKind kind;
  final AccountWithBalance? account;

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _institution = TextEditingController();
  final _balance = TextEditingController();
  final _originalPrincipal = TextEditingController();
  final _remainingPrincipal = TextEditingController();
  final _rate = TextEditingController();
  final _termMonths = TextEditingController();
  final _perAmount = TextEditingController();
  final _note = TextEditingController();
  final _startAt = TextEditingController();
  final _nextDueAt = TextEditingController();
  final _creditDebt = TextEditingController();
  final _creditLimit = TextEditingController();
  final _billingDay = TextEditingController();
  final _repaymentDay = TextEditingController();
  int? _defaultCategoryId;
  String _loanKind = 'mortgage';
  String _repaymentMethod = 'equal_principal_interest';

  bool get _editing => widget.account != null;

  AccountKind get _kind {
    final account = widget.account?.account;
    if (account == null) return widget.kind;
    if (account.type == 'loan') return AccountKind.loan;
    if (account.type == 'stored') return AccountKind.stored;
    if (account.type == 'credit') return AccountKind.credit;
    if (account.type == 'deposit') return AccountKind.deposit;
    return AccountKind.bank;
  }

  @override
  void initState() {
    super.initState();
    final view = widget.account;
    if (view != null) {
      _name.text = view.account.name;
      _institution.text = view.account.institution ?? '';
      _note.text = view.account.note ?? '';
      _balance.text = (view.balance / 100).toStringAsFixed(2);
      _defaultCategoryId = view.card?.defaultCategoryId;
      _creditDebt.text = (view.balance.abs() / 100).toStringAsFixed(2);
      _creditLimit.text = view.card?.creditLimit == null ? '' : (view.card!.creditLimit! / 100).toStringAsFixed(2);
      _billingDay.text = view.card?.billingDay?.toString() ?? '';
      _repaymentDay.text = view.card?.repaymentDay?.toString() ?? '';
      final loan = view.loan;
      if (loan != null) {
        _loanKind = loan.kind;
        _originalPrincipal.text = (loan.originalPrincipal / 100).toStringAsFixed(2);
        _remainingPrincipal.text = (view.balance.abs() / 100).toStringAsFixed(2);
        _rate.text = (loan.rateBp / 100).toStringAsFixed(2);
        _termMonths.text = loan.termMonths.toString();
        _startAt.text = formatDate(DateTime.fromMillisecondsSinceEpoch(loan.startAt));
        _nextDueAt.text = formatDate(DateTime.fromMillisecondsSinceEpoch(loan.nextDueAt));
        _perAmount.text = ((loan.perAmount ?? 0) / 100).toStringAsFixed(2);
        _repaymentMethod = loan.repaymentMethod;
      }
    } else {
      _balance.text = '';
      _originalPrincipal.text = '';
      _remainingPrincipal.text = '';
      _rate.text = '';
      _termMonths.text = '';
      _perAmount.text = '';
    }
    if (_startAt.text.isEmpty) _startAt.text = formatDate(DateTime.now());
    if (_nextDueAt.text.isEmpty) _nextDueAt.text = formatDate(DateTime.now().add(const Duration(days: 30)));
  }

  @override
  void dispose() {
    _name.dispose();
    _institution.dispose();
    _balance.dispose();
    _originalPrincipal.dispose();
    _remainingPrincipal.dispose();
    _rate.dispose();
    _termMonths.dispose();
    _perAmount.dispose();
    _note.dispose();
    _startAt.dispose();
    _nextDueAt.dispose();
    _creditDebt.dispose();
    _creditLimit.dispose();
    _billingDay.dispose();
    _repaymentDay.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isLoan = _kind == AccountKind.loan;
    final isStored = _kind == AccountKind.stored;
    final isCredit = _kind == AccountKind.credit;
    final isDeposit = _kind == AccountKind.deposit;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final categoryById = {for (final category in categories) category.id: category};
    final expenseCategories = categories.where((c) => c.type == 'expense').toList();
    final parentCategoryIds = expenseCategories.map((c) => c.parentId).whereType<int>().toSet();
    final expenseDefaults = expenseCategories.where((c) => !parentCategoryIds.contains(c.id)).toList();
    if (_defaultCategoryId != null && !expenseDefaults.any((c) => c.id == _defaultCategoryId)) {
      final selected = categoryById[_defaultCategoryId];
      if (selected != null) expenseDefaults.add(selected);
    }
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl)),
        ),
        child: Column(
          children: [
            SizedBox(height: tokens.space2),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tokens.borderStrong,
                borderRadius: BorderRadius.circular(tokens.radiusFull),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_editing ? '编辑' : '添加'}${_kind.label}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
                  children: [
                    _label(context, '名称'),
                    TextFormField(
                      controller: _name,
                      maxLength: 20,
                      decoration: _decoration(
                        context,
                        _kind == AccountKind.loan
                            ? '如：招商银行房贷'
                            : (_kind == AccountKind.stored
                                ? '如：银座购物卡'
                                : (_kind == AccountKind.credit ? '如：招商银行信用卡' : '如：招商银行卡')),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) return '请输入账户名称';
                        return null;
                      },
                    ),
                    SizedBox(height: tokens.space2),
                    _label(context, isStored ? '商户 / 平台' : (isLoan ? '贷款机构' : (isCredit ? '发卡行 / 平台' : '开户行 / 平台'))),
                    TextFormField(
                      controller: _institution,
                      maxLength: 20,
                      decoration: _decoration(context, isStored ? '如：银座' : '如：招商银行'),
                    ),
                    if (!isLoan && !isCredit && !isDeposit && !_editing) ...[
                      _label(context, '期初余额'),
                      TextFormField(
                        controller: _balance,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '0.00'),
                        validator: (value) {
                          final cents = parseYuanToCents(value ?? '');
                          if (cents < 0) return '余额不能为负';
                          return null;
                        },
                      ),
                    ],
                    if (!isLoan && !isCredit && !isDeposit && _editing) ...[
                      _label(context, '当前余额'),
                      InputDecorator(
                        decoration: _decoration(context, ''),
                        child: Text(
                          formatCents(widget.account!.balance),
                          style: TextStyle(fontSize: 15, color: tokens.textPrimary),
                        ),
                      ),
                      SizedBox(height: tokens.space1),
                      Text(
                        '余额由流水自动变化，不在资料里直接修改',
                        style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      ),
                    ],
                    if (isStored) ...[
                      _label(context, '默认消费类别'),
                      DropdownButtonFormField<int?>(
                        initialValue: _defaultCategoryId,
                        decoration: _decoration(context, ''),
                        icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('不设置')),
                          ...expenseDefaults.map((c) {
                            final parent = c.parentId == null ? null : categoryById[c.parentId];
                            return DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                parent == null ? c.name : '${parent.name} · ${c.name}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => _defaultCategoryId = value),
                      ),
                      SizedBox(height: tokens.space1),
                      Text(
                        '记账选择这张储值卡时，默认选中该类别',
                        style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      ),
                    ],
                    if (isCredit) ...[
                      if (!_editing) ...[
                        _label(context, '当前待还'),
                        TextFormField(
                          controller: _creditDebt,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: _decoration(context, '0.00'),
                          validator: (value) => parseYuanToCents(value ?? '') < 0 ? '待还不能为负' : null,
                        ),
                      ] else ...[
                        _label(context, '当前待还'),
                        InputDecorator(
                          decoration: _decoration(context, ''),
                          child: Text(formatCents(widget.account!.balance.abs()), style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
                        ),
                        SizedBox(height: tokens.space1),
                        Text('待还金额由信用卡消费和还款流水自动变化', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                      ],
                      _label(context, '信用额度（选填）'),
                      TextFormField(
                        controller: _creditLimit,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '如：50000.00'),
                      ),
                      _label(context, '账单日（选填）'),
                      TextFormField(
                        controller: _billingDay,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _decoration(context, '1-31'),
                        validator: (value) => _validateDay(value) ? null : '请输入 1-31',
                      ),
                      _label(context, '还款日（选填）'),
                      TextFormField(
                        controller: _repaymentDay,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _decoration(context, '1-31'),
                        validator: (value) => _validateDay(value) ? null : '请输入 1-31',
                      ),
                    ],
                    if (isDeposit) ...[
                      Text(
                        '存单请使用「添加存单」表单填写本金、利率和存期。',
                        style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                      ),
                    ],
                    if (isLoan) ...[
                      _label(context, '贷款类型'),
                      DropdownButtonFormField<String>(
                        initialValue: _loanKind,
                        decoration: _decoration(context, ''),
                        icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                        items: const [
                          DropdownMenuItem(value: 'mortgage', child: Text('房贷')),
                          DropdownMenuItem(value: 'car', child: Text('车贷')),
                          DropdownMenuItem(value: 'consumer', child: Text('消费贷')),
                          DropdownMenuItem(value: 'other', child: Text('其他')),
                        ],
                        onChanged: (value) => setState(() => _loanKind = value ?? 'mortgage'),
                      ),
                      _label(context, '原始本金'),
                      TextFormField(
                        controller: _originalPrincipal,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '0.00'),
                        validator: (value) => parseYuanToCents(value ?? '') <= 0 ? '请输入原始本金' : null,
                      ),
                      _label(context, '剩余本金'),
                      TextFormField(
                        controller: _remainingPrincipal,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '默认等于原始本金'),
                        validator: (value) {
                          final remaining = parseYuanToCents(value ?? '');
                          final original = parseYuanToCents(_originalPrincipal.text);
                          if (remaining < 0 || remaining > original) return '剩余本金应在 0 到原始本金之间';
                          return null;
                        },
                      ),
                      _label(context, '年利率（%）'),
                      TextFormField(
                        controller: _rate,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '如：4.10'),
                        validator: (value) {
                          final rate = double.tryParse(value ?? '') ?? 0;
                          if (rate < 0) return '请输入正确的利率';
                          return null;
                        },
                      ),
                      _label(context, '总期数（月）'),
                      TextFormField(
                        controller: _termMonths,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: _decoration(context, '如：360'),
                        validator: (value) {
                          final term = int.tryParse(value ?? '') ?? 0;
                          if (term <= 0 || term > 600) return '请输入正确的总期数';
                          return null;
                        },
                      ),
                      _label(context, '起贷日'),
                      TextFormField(
                        controller: _startAt,
                        keyboardType: TextInputType.datetime,
                        decoration: _decoration(context, 'YYYY-MM-DD'),
                        validator: (value) => DateTime.tryParse((value ?? '').trim()) == null ? '请输入起贷日' : null,
                      ),
                      _label(context, '下次还款日'),
                      TextFormField(
                        controller: _nextDueAt,
                        keyboardType: TextInputType.datetime,
                        decoration: _decoration(context, 'YYYY-MM-DD'),
                        validator: (value) => DateTime.tryParse((value ?? '').trim()) == null ? '请输入下次还款日' : null,
                      ),
                      _label(context, '每期还款额（选填）'),
                      TextFormField(
                        controller: _perAmount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        decoration: _decoration(context, '如：6800.00'),
                      ),
                      _label(context, '还款方式'),
                      DropdownButtonFormField<String>(
                        initialValue: _repaymentMethod,
                        decoration: _decoration(context, ''),
                        icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                        items: const [
                          DropdownMenuItem(value: 'equal_principal_interest', child: Text('等额本息')),
                          DropdownMenuItem(value: 'equal_principal', child: Text('等额本金')),
                          DropdownMenuItem(value: 'interest_only', child: Text('先息后本')),
                          DropdownMenuItem(value: 'other', child: Text('其他')),
                        ],
                        onChanged: (value) => setState(() => _repaymentMethod = value ?? 'equal_principal_interest'),
                      ),
                    ],
                    _label(context, '备注'),
                    TextFormField(
                      controller: _note,
                      decoration: _decoration(context, '添加备注（选填）'),
                    ),
                    SizedBox(height: tokens.space4),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space4, tokens.space4),
              decoration: BoxDecoration(
                color: tokens.bg,
                border: Border(top: BorderSide(color: tokens.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: tokens.border),
                        foregroundColor: tokens.textPrimary,
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('保存'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.only(top: tokens.space3, bottom: tokens.space1),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final tokens = context.tokens;
    return InputDecoration(
      hintText: hint,
      counterText: '',
      hintStyle: TextStyle(fontSize: 14, color: tokens.textDisabled),
      contentPadding: EdgeInsets.symmetric(horizontal: tokens.space3, vertical: 12),
      filled: true,
      fillColor: tokens.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        borderSide: BorderSide(color: tokens.primary, width: 1.5),
      ),
    );
  }

  bool _validateDay(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return true;
    final day = int.tryParse(text);
    return day != null && day >= 1 && day <= 31;
  }

  Future<void> _save() async {    if (!(_formKey.currentState?.validate() ?? false)) return;
    final repository = ref.read(accountRepositoryProvider);
    final name = _name.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await repository.nameExists(name, excludeId: widget.account?.account.id)) {
        messenger.showSnackBar(const SnackBar(content: Text('账户名称已存在')));
        return;
      }

      if (_kind == AccountKind.loan) {
        final original = parseYuanToCents(_originalPrincipal.text);
        final remainingText = _remainingPrincipal.text.trim();
        final remaining = remainingText.isEmpty ? original : parseYuanToCents(remainingText);
        final rate = double.tryParse(_rate.text.trim()) ?? 0;
        final term = int.tryParse(_termMonths.text.trim()) ?? 0;
        final per = parseYuanToCents(_perAmount.text);
        final startDate = DateTime.tryParse(_startAt.text.trim());
        final nextDueDate = DateTime.tryParse(_nextDueAt.text.trim());
        if (remaining < 0 || remaining > original) {
          messenger.showSnackBar(const SnackBar(content: Text('剩余本金应在 0 到原始本金之间')));
          return;
        }
        if (startDate == null || nextDueDate == null) {
          messenger.showSnackBar(const SnackBar(content: Text('请输入正确的日期，格式 YYYY-MM-DD')));
          return;
        }
        if (_editing) {
          await repository.updateLoanAccount(
            widget.account!.account.id,
            name: name,
            institution: _institution.text.trim(),
            kind: _loanKind,
            originalPrincipal: original,
            remainingPrincipal: remaining,
            rateBp: (rate * 100).round(),
            termMonths: term,
            startAt: startDate,
            nextDueAt: nextDueDate,
            perAmount: per,
            repaymentMethod: _repaymentMethod,
            note: _note.text.trim(),
          );
        } else {
          await repository.createLoanAccount(
            name: name,
            institution: _institution.text.trim(),
            kind: _loanKind,
            originalPrincipal: original,
            remainingPrincipal: remaining,
            rateBp: (rate * 100).round(),
            termMonths: term,
            startAt: startDate,
            nextDueAt: nextDueDate,
            perAmount: per,
            repaymentMethod: _repaymentMethod,
            note: _note.text.trim(),
          );
        }
      } else if (_kind == AccountKind.stored) {
        if (_editing) {
          await repository.updateStoredAccount(
            widget.account!.account.id,
            name: name,
            institution: _institution.text.trim(),
            defaultCategoryId: _defaultCategoryId,
            note: _note.text.trim(),
          );
        } else {
          await repository.createStoredAccount(
            name: name,
            institution: _institution.text.trim(),
            openingBalance: parseYuanToCents(_balance.text),
            defaultCategoryId: _defaultCategoryId,
            note: _note.text.trim(),
          );
        }
      } else if (_kind == AccountKind.credit) {
        final limit = _creditLimit.text.trim().isEmpty ? null : parseYuanToCents(_creditLimit.text);
        final billing = _billingDay.text.trim().isEmpty ? null : int.tryParse(_billingDay.text.trim());
        final repayment = _repaymentDay.text.trim().isEmpty ? null : int.tryParse(_repaymentDay.text.trim());
        if (_editing) {
          await repository.updateCreditAccount(
            widget.account!.account.id,
            name: name,
            institution: _institution.text.trim(),
            creditLimit: limit,
            billingDay: billing,
            repaymentDay: repayment,
            note: _note.text.trim(),
          );
        } else {
          await repository.createCreditAccount(
            name: name,
            institution: _institution.text.trim(),
            openingDebt: parseYuanToCents(_creditDebt.text),
            creditLimit: limit,
            billingDay: billing,
            repaymentDay: repayment,
            note: _note.text.trim(),
          );
        }
      } else if (_kind == AccountKind.deposit) {
        messenger.showSnackBar(const SnackBar(content: Text('请使用添加存单表单')));
        return;
      } else {
        if (_editing) {
          await repository.updateBankAccount(
            widget.account!.account.id,
            name: name,
            institution: _institution.text.trim(),
            note: _note.text.trim(),
          );
        } else {
          await repository.createBankAccount(
            name: name,
            institution: _institution.text.trim(),
            openingBalance: parseYuanToCents(_balance.text),
            note: _note.text.trim(),
          );
        }
      }
      ref.invalidate(accountsProvider);
      ref.invalidate(homeProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(_editing ? '已更新${_kind.label}' : '已添加${_kind.label}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }
}
