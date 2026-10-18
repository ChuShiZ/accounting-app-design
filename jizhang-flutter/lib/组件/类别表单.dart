import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/数据库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '类别展示.dart';

const categoryIconChoices = [
  ('food', '餐饮'),
  ('car', '交通'),
  ('cart', '购物'),
  ('building', '居家'),
  ('fun', '娱乐'),
  ('coffee', '咖啡'),
  ('medical', '医疗'),
  ('education', '教育'),
  ('phone', '通讯'),
  ('mortgage', '房贷'),
  ('loan', '贷款'),
  ('card', '充值'),
  ('salary', '工资'),
  ('gift', '礼物'),
  ('interest', '利息'),
  ('invest', '理财'),
  ('other', '其他'),
];

Future<void> showCategoryForm(
  BuildContext context, {
  CategoryRow? category,
  required String type,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryFormSheet(category: category, type: type),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.category});

  final String type;
  final CategoryRow? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _name = TextEditingController();
  late String _type;
  late String _icon;

  bool get _editing => widget.category != null;
  int get _usage => widget.category == null ? 0 : (ref.watch(categoryUsageProvider).valueOrNull?[widget.category!.id] ?? 0);

  @override
  void initState() {
    super.initState();
    _type = widget.category?.type ?? widget.type;
    _icon = widget.category?.icon ?? (_type == 'income' ? 'salary' : 'cart');
    _name.text = widget.category?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(color: tokens.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusXl))),
        child: Column(
          children: [
            SizedBox(height: tokens.space2),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: tokens.borderStrong, borderRadius: BorderRadius.circular(tokens.radiusFull))),
            Padding(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space2, tokens.space2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? '编辑类别' : '新增类别',
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
              child: ListView(
                padding: EdgeInsets.fromLTRB(tokens.space4, 0, tokens.space4, tokens.space4),
                children: [
                  _label(context, '收支类型'),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Row(
                      children: [
                        _typeButton(context, 'expense', '支出'),
                        _typeButton(context, 'income', '收入'),
                      ],
                    ),
                  ),
                  if (_editing && _usage > 0)
                    Padding(
                      padding: EdgeInsets.only(top: tokens.space1),
                      child: Text('已有 $_usage 笔流水，不能修改收支类型', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                    ),
                  _label(context, '名称'),
                  TextField(
                    controller: _name,
                    readOnly: widget.category?.isFixed == true,
                    maxLength: 20,
                    decoration: _decoration(context, widget.category?.isFixed == true ? '固定类别' : '如：咖啡、宠物、房租'),
                  ),
                  _label(context, '图标'),
                  Container(
                    padding: EdgeInsets.all(tokens.space2),
                    decoration: BoxDecoration(border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: Wrap(
                      children: categoryIconChoices.map((item) {
                        final selected = item.$1 == _icon;
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width - 64) / 4,
                          child: InkWell(
                            onTap: () => setState(() => _icon = item.$1),
                            borderRadius: BorderRadius.circular(tokens.radiusMd),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              padding: EdgeInsets.symmetric(vertical: tokens.space2),
                              decoration: BoxDecoration(
                                color: selected ? tokens.primaryLight : Colors.transparent,
                                border: Border.all(color: selected ? tokens.primary : Colors.transparent),
                                borderRadius: BorderRadius.circular(tokens.radiusMd),
                              ),
                              child: Column(
                                children: [
                                  Icon(categoryIconData(item.$1), size: 24, color: categoryColor(item.$1)),
                                  SizedBox(height: 3),
                                  Text(
                                    item.$2,
                                    style: TextStyle(fontSize: 11, color: selected ? tokens.primary : tokens.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_editing && widget.category?.isFixed != true) ...[
                    SizedBox(height: tokens.space5),
                    Center(
                      child: TextButton.icon(
                        onPressed: _delete,
                        icon: Icon(LucideIcons.trash2, size: 16, color: tokens.expense),
                        label: Text('删除类别', style: TextStyle(color: tokens.expense)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(tokens.space4, tokens.space3, tokens.space4, tokens.space4),
              decoration: BoxDecoration(color: tokens.bg, border: Border(top: BorderSide(color: tokens.border))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: BorderSide(color: tokens.border), foregroundColor: tokens.textPrimary),
                      child: const Text('取消'),
                    ),
                  ),
                  SizedBox(width: tokens.space3),
                  Expanded(
                    child: FilledButton(onPressed: _save, child: const Text('保存')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(BuildContext context, String value, String label) {
    final tokens = context.tokens;
    final active = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_editing && _usage > 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已有流水的类别不能修改收支类型')));
            return;
          }
          setState(() => _type = value);
        },
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? tokens.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            boxShadow: active ? const [BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 1))] : null,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: active ? tokens.primary : tokens.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
          ),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(tokens.radiusMd), borderSide: BorderSide(color: tokens.primary, width: 1.5)),
    );
  }

  Future<void> _save() async {
    final fixed = widget.category?.isFixed == true;
    final name = fixed ? widget.category!.name : _name.text.trim();
    final type = fixed ? widget.category!.type : _type;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入类别名称')));
      return;
    }
    final repository = ref.read(categoryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (await repository.nameExists(name, type, excludeId: widget.category?.id)) {
      messenger.showSnackBar(const SnackBar(content: Text('该类别已存在')));
      return;
    }
    try {
      if (_editing) {
        await repository.updateCategory(widget.category!.id, name: name, icon: _icon, type: type);
      } else {
        await repository.create(name: name, type: type, icon: _icon);
      }
      _invalidate(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(_editing ? '类别已更新' : '类别已添加')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('删除「${widget.category!.name}」？已有流水会归入【其他】。'),
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
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(widget.category!.id);
      _invalidate(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('类别已删除')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$error')));
    }
  }

  void _invalidate(WidgetRef ref) {
    ref.invalidate(categoriesProvider);
    ref.invalidate(categoryUsageProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(homeProvider);
    ref.invalidate(reportDataProvider);
  }
}
