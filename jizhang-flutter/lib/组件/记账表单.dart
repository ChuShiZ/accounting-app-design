import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../数据/数据库.dart';
import '../数据/仓库/账户仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '账户展示.dart';
import '类别展示.dart';

Future<void> showRecordSheet(BuildContext context, {TransactionRow? transaction}) {
  if (transaction?.locked == true) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('资产动作流水不可单独编辑或删除')));
    return Future<void>.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordSheet(transaction: transaction),
  );
}

class RecordSheet extends ConsumerStatefulWidget {
  const RecordSheet({super.key, this.transaction});

  final TransactionRow? transaction;

  @override
  ConsumerState<RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends ConsumerState<RecordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _date = TextEditingController();
  final _note = TextEditingController();
  String _type = 'expense';
  int? _categoryId;
  int? _accountId;
  String? _imagePath;

  bool get _editing => widget.transaction != null;
  AccountWithBalance? _accountBy(List<AccountWithBalance> list, int? id) {
    if (id == null) return null;
    for (final a in list) {
      if (a.account.id == id) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    if (tx != null) {
      _type = tx.type == 'income' ? 'income' : 'expense';
      _amount.text = (tx.amount / 100).toStringAsFixed(2);
      _categoryId = tx.categoryId;
      _accountId = tx.accountId;
      _date.text = formatDate(DateTime.fromMillisecondsSinceEpoch(tx.occurredAt));
      _note.text = tx.note ?? '';
      _imagePath = tx.imagePath;
    } else {
      _date.text = formatDate(DateTime.now());
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _date.dispose();
    _note.dispose();
    super.dispose();
  }

  List<AccountWithBalance> _accountsFor(List<AccountWithBalance> all) {
    if (_type == 'income') {
      return all.where((a) => ['bank', 'ewallet', 'cash', 'stored', 'deposit', 'default'].contains(a.account.type)).toList();
    }
    return all.where((a) => ['bank', 'ewallet', 'cash', 'stored', 'credit', 'default'].contains(a.account.type)).toList();
  }

  int? _effectiveAccount(List<AccountWithBalance> accounts, int? preferred) {
    if (accounts.isEmpty) return null;
    if (_accountId != null && accounts.any((a) => a.account.id == _accountId)) return _accountId;
    if (preferred != null && accounts.any((a) => a.account.id == preferred)) return preferred;
    return accounts.first.account.id;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final defaultAccount = ref.watch(defaultAccountProvider).valueOrNull;
    final allAccounts = accountsAsync.valueOrNull ?? const <AccountWithBalance>[];
    final allCategories = categoriesAsync.valueOrNull ?? const <CategoryRow>[];
    final accounts = _accountsFor(allAccounts);
    final categories = allCategories.where((c) => c.type == _type).toList();
    final categoryById = {for (final category in categories) category.id: category};
    final topCategories = categories.where((category) => category.parentId == null).toList();
    final specialDefault = allAccounts.where((a) => a.account.type == 'default').firstOrNull?.account.id;
    final preferredDefault = defaultAccount != null && allAccounts.any((a) => a.account.id == defaultAccount)
        ? defaultAccount
        : specialDefault;
    final accountId = _effectiveAccount(accounts, preferredDefault);
    final account = _accountBy(accounts, accountId);
    final preferredCategory = _categoryId ??
        (account?.account.type == 'stored' && _type == 'expense' ? account?.card?.defaultCategoryId : null);
    var selectedCategory = preferredCategory == null ? null : categoryById[preferredCategory];
    if (selectedCategory == null && topCategories.isNotEmpty) selectedCategory = topCategories.first;
    var topCategory = selectedCategory == null
        ? null
        : (selectedCategory.parentId == null ? selectedCategory : categoryById[selectedCategory.parentId]);
    if (topCategory == null && topCategories.isNotEmpty) {
      topCategory = topCategories.first;
      selectedCategory = topCategory;
    }
    final topCategoryId = topCategory?.id;
    final subCategories = topCategoryId == null
        ? const <CategoryRow>[]
        : categories.where((category) => category.parentId == topCategoryId).toList();
    final categoryId = selectedCategory?.id;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
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
              decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? '编辑流水' : '记一笔',
                      style: TextStyle(fontSize: 18, height: 1.2, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: tokens.textSecondary),
                    tooltip: '关闭',
                    visualDensity: VisualDensity.compact,
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
                    _typeSwitch(context),
                    SizedBox(height: tokens.space2),
                    Text('金额', style: TextStyle(fontSize: 11, height: 1.2, color: tokens.textSecondary)),
                    Container(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.border))),
                      child: Row(
                        children: [
                          Text('¥', style: TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w600, color: tokens.textSecondary)),
                          SizedBox(width: tokens.space2),
                          Expanded(
                            child: TextFormField(
                              controller: _amount,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                              style: TextStyle(fontSize: 26, height: 1.2, fontWeight: FontWeight.w700, color: tokens.textPrimary),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              validator: (value) => parseYuanToCents(value ?? '') <= 0 ? '请输入金额' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.space2),
                    Row(
                      children: [
                        Text('类别', style: TextStyle(fontSize: 11, height: 1.2, color: tokens.textSecondary)),
                        const Spacer(),
                        Text('一级 / 二级', style: TextStyle(fontSize: 10, height: 1.2, color: tokens.textDisabled)),
                      ],
                    ),
                    SizedBox(height: tokens.space1),
                    if (topCategories.isEmpty)
                      Text('暂无可用类别，请先到类别管理添加', style: TextStyle(fontSize: 12, color: tokens.textSecondary))
                    else ...[
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: topCategories.length,
                          separatorBuilder: (context, index) => SizedBox(width: 6),
                          itemBuilder: (context, index) {
                            final top = topCategories[index];
                            final active = top.id == topCategory?.id;
                            return InkWell(
                              onTap: () => setState(() => _categoryId = top.id),
                              borderRadius: BorderRadius.circular(tokens.radiusFull),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: active ? tokens.primaryLight : tokens.surface2,
                                  borderRadius: BorderRadius.circular(tokens.radiusFull),
                                  border: Border.all(color: active ? tokens.primary : Colors.transparent),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(categoryIconData(top.icon), size: 16, color: categoryColor(top.icon)),
                                    SizedBox(width: 4),
                                    Text(
                                      top.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: active ? tokens.primary : tokens.textPrimary,
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (topCategory != null && subCategories.isNotEmpty) ...[
                        SizedBox(height: 6),
                        SizedBox(
                          height: subCategories.length + 1 <= 5 ? 60 : 122,
                          child: GridView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: subCategories.length + 1,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              childAspectRatio: 1.1,
                            ),
                            itemBuilder: (context, index) {
                              final top = topCategory!;
                              final category = index == 0 ? top : subCategories[index - 1];
                              final selected = category.id == categoryId;
                              return InkWell(
                                onTap: () => setState(() => _categoryId = category.id),
                                borderRadius: BorderRadius.circular(tokens.radiusMd),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected ? tokens.primaryLight : Colors.transparent,
                                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                                    border: Border.all(color: selected ? tokens.primary : Colors.transparent),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(categoryIconData(category.icon), size: 24, color: categoryColor(category.icon)),
                                      SizedBox(height: 2),
                                      Text(
                                        index == 0 ? '不细分' : category.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          height: 1.1,
                                          color: selected ? tokens.primary : tokens.textPrimary,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else if (topCategory != null) ...[
                        SizedBox(height: 4),
                        Text('该分类无需细分，已默认选中', style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
                      ],
                    ],
                    SizedBox(height: tokens.space2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            key: ValueKey('account-$accountId'),
                            initialValue: accountId,
                            isExpanded: true,
                            decoration: _compactDecoration(context),
                            icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                            items: accounts
                                .map((a) => DropdownMenuItem(
                                      value: a.account.id,
                                      child: Text(
                                        a.account.id == preferredDefault ? '${a.account.name}（默认）' : a.account.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              final selected = _accountBy(accounts, value);
                              int? defaultCategory = _categoryId;
                              if (_type == 'expense' && selected?.account.type == 'stored') {
                                final configured = selected?.card?.defaultCategoryId;
                                if (configured != null && categories.any((c) => c.id == configured)) {
                                  defaultCategory = configured;
                                }
                              }
                              setState(() {
                                _accountId = value;
                                _categoryId = defaultCategory;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: tokens.space2),
                        SizedBox(
                          width: 116,
                          child: TextFormField(
                            controller: _date,
                            keyboardType: TextInputType.datetime,
                            style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                            decoration: _compactDecoration(context).copyWith(hintText: 'YYYY-MM-DD'),
                            validator: (value) => DateTime.tryParse((value ?? '').trim()) == null ? '日期错误' : null,
                          ),
                        ),
                      ],
                    ),
                    if (account != null && _accountHint(account).isNotEmpty) ...[
                      SizedBox(height: 2),
                      Text(
                        _accountHint(account),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                      ),
                    ],
                    SizedBox(height: tokens.space2),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _note,
                            style: TextStyle(fontSize: 13, color: tokens.textPrimary),
                            decoration: _compactDecoration(context).copyWith(hintText: '点击填写备注'),
                          ),
                        ),
                        SizedBox(width: tokens.space2),
                        _imageControl(context),
                      ],
                    ),
                    if (_editing) ...[
                      SizedBox(height: tokens.space1),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _delete,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('删除这笔流水', style: TextStyle(fontSize: 12, color: tokens.expense)),
                        ),
                      ),
                    ],
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
                      onPressed: () => _save(accountId, categoryId, account),
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

  Widget _imageControl(BuildContext context) {
    final tokens = context.tokens;
    final file = _imagePath == null ? null : File(_imagePath!);
    final hasImage = file != null && file.existsSync();
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.border),
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.file(file, fit: BoxFit.cover)
                    : Icon(LucideIcons.camera, size: 20, color: tokens.textSecondary),
              ),
            ),
          ),
          if (hasImage)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => setState(() => _imagePath = null),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: tokens.textPrimary, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, size: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(context.tokens.space4, 0, context.tokens.space4, context.tokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.camera, color: context.tokens.primary),
                title: const Text('拍照'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: context.tokens.primary),
                title: const Text('从相册选择'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1800);
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final receiptDir = Directory(p.join(dir.path, 'receipts'));
      if (!receiptDir.existsSync()) await receiptDir.create(recursive: true);
      final target = p.join(receiptDir.path, 'receipt_${DateTime.now().microsecondsSinceEpoch}${p.extension(picked.path)}');
      await File(picked.path).copy(target);
      if (!mounted) return;
      setState(() => _imagePath = target);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('选择图片失败：$error')));
    }
  }

  Widget _typeSwitch(BuildContext context) {
    final tokens = context.tokens;
    Widget button(String value, String label) {
      final active = _type == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _type = value;
            _categoryId = null;
            _accountId = null;
          }),
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? tokens.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              boxShadow: active ? const [BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 1))] : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? tokens.primary : tokens.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
      child: Row(children: [button('expense', '支出'), button('income', '收入')]),
    );
  }

  String _accountHint(AccountWithBalance view) {
    final type = view.account.type;
    if (type == 'default') return '默认账户不参与余额统计，用于未指定账户的流水';
    if (_type == 'expense' && type == 'stored') return '储值卡消费只扣余额，不再计支出（充值已计）';
    if (_type == 'expense' && type == 'credit') return '信用卡消费计入支出；还款不再计支出';
    if (_type == 'income' && type == 'deposit') return '存单利息计入收入；本金不计收入';
    return '';
  }

  InputDecoration _compactDecoration(BuildContext context) {
    final tokens = context.tokens;
    return InputDecoration(
      hintStyle: TextStyle(fontSize: 12, color: tokens.textDisabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      isDense: true,
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

  Future<void> _save(int? accountId, int? categoryId, AccountWithBalance? account) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (accountId == null || categoryId == null || account == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择账户和类别')));
      return;
    }
    final date = DateTime.tryParse(_date.text.trim());
    if (date == null) return;
    final amount = parseYuanToCents(_amount.text);
    final occurredAt = DateTime(date.year, date.month, date.day, 12);
    final reportable = !(_type == 'expense' && account.account.type == 'stored');
    final repository = ref.read(transactionRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_editing) {
        await repository.updateTransaction(
          widget.transaction!.id,
          type: _type,
          amount: amount,
          accountId: accountId,
          categoryId: categoryId,
          occurredAt: occurredAt,
          note: _note.text.trim(),
          reportable: reportable,
          imagePath: _imagePath,
        );
      } else if (_type == 'expense') {
        await repository.addExpense(
          amount: amount,
          accountId: accountId,
          categoryId: categoryId,
          occurredAt: occurredAt,
          note: _note.text.trim(),
          reportable: reportable,
          imagePath: _imagePath,
        );
      } else {
        await repository.addIncome(
          amount: amount,
          accountId: accountId,
          categoryId: categoryId,
          occurredAt: occurredAt,
          note: _note.text.trim(),
          imagePath: _imagePath,
        );
      }
      ref.invalidate(homeProvider);
      ref.invalidate(accountsProvider);
      ref.invalidate(reportDataProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      final label = _editing
          ? '已更新'
          : (_type == 'expense' && account.account.type == 'stored'
              ? '已记录储值卡消费'
              : '已记一笔 ${_type == 'expense' ? '支出' : '收入'}');
      messenger.showSnackBar(SnackBar(content: Text('$label ${formatCents(amount)}')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除流水'),
        content: const Text('删除这笔流水？账户余额和报表会同步回退。'),
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
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(transactionRepositoryProvider).deleteById(widget.transaction!.id);
    ref.invalidate(homeProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(reportDataProvider);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('已删除')));
  }
}
