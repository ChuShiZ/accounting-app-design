import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../数据/数据库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';
import '类别展示.dart';

/// 与类别图标一一对应。新增类别时可以直接在这里挑选，不依赖“其他”兜底。
const categoryIconChoices = <(String, String)>[
  ('food', '餐饮'),
  ('breakfast', '早餐'),
  ('lunch', '午餐'),
  ('dinner', '晚餐'),
  ('takeout', '外卖'),
  ('drink', '饮品'),
  ('snack', '零食'),
  ('fruit', '水果'),
  ('groceries', '买菜'),
  ('car', '交通'),
  ('bus', '公交'),
  ('bike', '单车'),
  ('fuel', '加油'),
  ('parking', '停车'),
  ('train', '火车'),
  ('plane', '飞机'),
  ('hotel', '酒店'),
  ('ticket', '门票'),
  ('travel', '旅行'),
  ('cart', '购物'),
  ('clothes', '服饰'),
  ('digital', '数码'),
  ('appliance', '家电'),
  ('beauty', '美妆'),
  ('baby', '母婴'),
  ('pet', '宠物'),
  ('package', '快递'),
  ('building', '居家'),
  ('utility', '水电'),
  ('water', '水费'),
  ('wifi', '网络'),
  ('repair', '维修'),
  ('furniture', '家具'),
  ('rent', '房租'),
  ('fun', '娱乐'),
  ('movie', '电影'),
  ('music', '音乐'),
  ('game', '游戏'),
  ('sports', '运动'),
  ('subscription', '订阅'),
  ('medical', '医疗'),
  ('medicine', '药品'),
  ('hospital', '门诊'),
  ('dental', '牙科'),
  ('health', '健康'),
  ('education', '教育'),
  ('book', '书籍'),
  ('stationery', '文具'),
  ('phone', '通讯'),
  ('salary', '工资'),
  ('bonus', '奖金'),
  ('commission', '提成'),
  ('business', '经营'),
  ('sidejob', '兼职'),
  ('gift', '礼物'),
  ('redpacket', '红包'),
  ('charity', '公益'),
  ('insurance', '保险'),
  ('fee', '手续费'),
  ('interest', '利息'),
  ('invest', '理财'),
  ('dividend', '分红'),
  ('stock', '股票'),
  ('fund', '基金'),
  ('refund', '退款'),
  ('reimburse', '报销'),
  ('cash', '现金'),
  ('bank', '银行'),
  ('mortgage', '房贷'),
  ('loan', '贷款'),
  ('card', '充值'),
  ('other', '其他'),
];

Future<void> showCategoryForm(
  BuildContext context, {
  CategoryRow? category,
  required String type,
  int? parentId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CategoryFormSheet(category: category, type: type, parentId: parentId),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, required this.type, this.category, this.parentId});

  final String type;
  final CategoryRow? category;
  final int? parentId;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _name = TextEditingController();
  late String _type;
  late String _icon;
  late int _parentChoice;

  bool get _editing => widget.category != null;

  List<CategoryRow> get _allCategories => ref.watch(categoriesProvider).valueOrNull ?? const <CategoryRow>[];

  Map<int, int> get _usageMap => ref.watch(categoryUsageProvider).valueOrNull ?? const <int, int>{};

  bool get _hasChildren {
    final category = widget.category;
    if (category == null) return false;
    return _allCategories.any((item) => item.parentId == category.id);
  }

  int get _usage {
    final category = widget.category;
    if (category == null) return 0;
    var total = _usageMap[category.id] ?? 0;
    for (final item in _allCategories) {
      if (item.parentId == category.id) total += _usageMap[item.id] ?? 0;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _type = widget.category?.type ?? widget.type;
    _icon = widget.category?.icon ?? (_type == 'income' ? 'salary' : 'cart');
    _parentChoice = widget.category?.parentId ?? widget.parentId ?? 0;
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
    final all = _allCategories;
    final parentOptions = all
        .where((item) => item.type == _type && item.parentId == null && !item.isFixed && item.id != widget.category?.id)
        .toList();
    final parentChoice = parentOptions.any((item) => item.id == _parentChoice) ? _parentChoice : 0;
    final parent = parentChoice == 0 ? null : parentOptions.firstWhere((item) => item.id == parentChoice);
    final lockedParent = _hasChildren || widget.category?.isFixed == true;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                  if (_editing && _hasChildren)
                    Padding(
                      padding: EdgeInsets.only(top: tokens.space1),
                      child: Text('该分类下已有子分类，不能修改收支类型或移动到其他一级分类', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                    ),
                  _label(context, '名称'),
                  TextField(
                    controller: _name,
                    readOnly: widget.category?.isFixed == true,
                    maxLength: 20,
                    decoration: _decoration(context, widget.category?.isFixed == true ? '固定类别' : '如：咖啡、宠物、房租'),
                  ),
                  _label(context, '上级分类'),
                  DropdownButtonFormField<int>(
                    key: ValueKey('parent-$_type-$parentChoice-${parentOptions.length}-${lockedParent ? 1 : 0}'),
                    initialValue: lockedParent ? 0 : parentChoice,
                    isExpanded: true,
                    decoration: _decoration(context, ''),
                    icon: Icon(LucideIcons.chevronDown, color: tokens.textDisabled),
                    items: [
                      DropdownMenuItem(value: 0, child: Text('无（一级分类）', style: TextStyle(fontSize: 14, color: tokens.textPrimary))),
                      ...parentOptions.map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Row(
                            children: [
                              Icon(categoryIconData(item.icon), size: 18, color: categoryColor(item.icon)),
                              SizedBox(width: 6),
                              Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: lockedParent
                        ? null
                        : (value) => setState(() => _parentChoice = value ?? 0),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      widget.category?.isFixed == true
                          ? '固定类别保持为一级分类。'
                          : (lockedParent
                              ? '一级分类下已有子分类，不能移动。'
                              : (parent == null
                                  ? '将创建/保留为一级分类；一级分类下可继续添加二级分类。'
                                  : '将归入「${parent.name}」下面，作为二级分类。')),
                      style: TextStyle(fontSize: 11, height: 1.4, color: tokens.textSecondary),
                    ),
                  ),
                  _label(context, '图标'),
                  Text('挑选一个图标，图标颜色固定，无需底色。', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                  SizedBox(height: tokens.space2),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusMd)),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: categoryIconChoices.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final item = categoryIconChoices[index];
                        final selected = item.$1 == _icon;
                        return InkWell(
                          onTap: () => setState(() => _icon = item.$1),
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? tokens.primaryLight : Colors.transparent,
                              border: Border.all(color: selected ? tokens.primary : Colors.transparent),
                              borderRadius: BorderRadius.circular(tokens.radiusMd),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(categoryIconData(item.$1), size: 24, color: categoryColor(item.$1)),
                                SizedBox(height: 3),
                                Text(
                                  item.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    height: 1.1,
                                    color: selected ? tokens.primary : tokens.textSecondary,
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
                  if (_editing && widget.category?.isFixed != true) ...[
                    SizedBox(height: tokens.space4),
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
          if (_editing && _hasChildren) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已有子分类的类别不能修改收支类型')));
            return;
          }
          if (active) return;
          setState(() {
            _type = value;
            _parentChoice = 0;
          });
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
    final all = ref.read(categoriesProvider).valueOrNull ?? const <CategoryRow>[];
    final hasChildren = widget.category != null && all.any((item) => item.parentId == widget.category!.id);
    final parentOptions = all
        .where((item) => item.type == type && item.parentId == null && !item.isFixed && item.id != widget.category?.id)
        .toList();
    final parentChoice = parentOptions.any((item) => item.id == _parentChoice) ? _parentChoice : 0;
    final parentId = fixed || hasChildren || parentChoice == 0 ? null : parentChoice;
    if (parentId != null) {
      final parent = parentOptions.firstWhere((item) => item.id == parentId);
      if (parent.parentId != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('只能选择一级分类作为上级')));
        return;
      }
    }
    final repository = ref.read(categoryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    if (await repository.nameExists(name, type, excludeId: widget.category?.id)) {
      messenger.showSnackBar(const SnackBar(content: Text('该类别已存在')));
      return;
    }
    try {
      if (_editing) {
        await repository.updateCategory(widget.category!.id, name: name, icon: _icon, type: type, parentId: parentId);
      } else {
        await repository.create(name: name, type: type, icon: _icon, parentId: parentId);
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
    final category = widget.category;
    if (category == null) return;
    final repository = ref.read(categoryRepositoryProvider);
    if (await repository.hasChildren(category.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先删除或移动子分类')));
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除类别'),
        content: Text('删除「${category.name}」？已有流水会归入【其他】。'),
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
      await repository.deleteCategory(category.id);
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
