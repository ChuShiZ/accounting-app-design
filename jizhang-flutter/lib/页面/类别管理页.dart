import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/类别展示.dart';
import '../组件/类别表单.dart';
import '../数据/数据库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  String _type = 'expense';
  final Set<int> _expanded = <int>{};

  Future<void> _addChild(CategoryRow group) async {
    await showCategoryForm(context, type: _type, parentId: group.id);
    if (!mounted) return;
    setState(() => _expanded.add(group.id));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    final usage = ref.watch(categoryUsageProvider).valueOrNull ?? const <int, int>{};
    return Scaffold(
      backgroundColor: tokens.surface,
      body: PageScaffold(
        title: '类别管理',
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(LucideIcons.arrowLeft, color: tokens.textPrimary),
          tooltip: '返回',
        ),
        action: IconButton(
          onPressed: () => showCategoryForm(context, type: _type),
          icon: Icon(LucideIcons.plus, color: tokens.textPrimary),
          tooltip: '新增一级分类',
        ),
        child: categoriesAsync.when(
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.space10),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary)),
          ),
          error: (error, stack) => Text('类别加载失败：$error', style: TextStyle(color: tokens.expense)),
          data: (all) {
            final list = all.where((c) => c.type == _type).toList();
            final tops = list.where((c) => c.parentId == null).toList();
            final children = <int, List<CategoryRow>>{};
            for (final category in list) {
              final parentId = category.parentId;
              if (parentId != null) children.putIfAbsent(parentId, () => <CategoryRow>[]).add(category);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusFull)),
                    child: Row(
                      children: [
                        _tab(context, 'expense', '支出'),
                        _tab(context, 'income', '收入'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: tokens.space3),
                if (tops.isEmpty)
                  Container(
                    padding: EdgeInsets.all(tokens.space6),
                    decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
                    child: Center(child: Text('暂无类别', style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
                  )
                else
                  Container(
                    decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
                    child: Column(
                      children: [
                        for (var i = 0; i < tops.length; i++) ...[
                          _GroupTile(
                            group: tops[i],
                            children: children[tops[i].id] ?? const <CategoryRow>[],
                            usage: usage,
                            expanded: _expanded.contains(tops[i].id),
                            onToggle: () => setState(() {
                              if (!_expanded.remove(tops[i].id)) _expanded.add(tops[i].id);
                            }),
                            onEdit: () => showCategoryForm(context, category: tops[i], type: tops[i].type),
                            onAddChild: tops[i].isFixed ? null : () => _addChild(tops[i]),
                            onEditChild: (child) => showCategoryForm(context, category: child, type: child.type),
                          ),
                          if (i < tops.length - 1) Divider(height: 1, color: tokens.divider),
                        ],
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.space3),
                  child: Text(
                    '一级分类用于报表汇总，二级分类用于日常记账。点击一级分类展开二级分类；点 + 新增二级分类，点铅笔编辑。删除已用类别时流水归入【其他】。',
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary, height: 1.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, String value, String label) {
    final tokens = context.tokens;
    final active = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? tokens.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(tokens.radiusFull),
            boxShadow: active ? const [BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 1))] : null,
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: active ? tokens.primary : tokens.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.children,
    required this.usage,
    required this.expanded,
    required this.onToggle,
    required this.onEdit,
    required this.onAddChild,
    required this.onEditChild,
  });

  final CategoryRow group;
  final List<CategoryRow> children;
  final Map<int, int> usage;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onAddChild;
  final ValueChanged<CategoryRow> onEditChild;

  int get _totalUsage {
    var total = usage[group.id] ?? 0;
    for (final child in children) {
      total += usage[child.id] ?? 0;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      children: [
        InkWell(
          onTap: children.isEmpty ? onEdit : onToggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(tokens.space3, tokens.space3, tokens.space2, tokens.space3),
            child: Row(
              children: [
                Icon(categoryIconData(group.icon), size: 24, color: categoryColor(group.icon)),
                SizedBox(width: tokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: tokens.textPrimary),
                      ),
                      SizedBox(height: 1),
                      Text(
                        children.isEmpty ? '一级分类 · 已用 $_totalUsage 笔' : '${children.length} 个二级分类 · 已用 $_totalUsage 笔',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (group.isFixed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(4)),
                    child: Text('默认', style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
                  ),
                if (onAddChild != null)
                  IconButton(
                    onPressed: onAddChild,
                    icon: Icon(LucideIcons.plus, size: 18, color: tokens.textSecondary),
                    tooltip: '新增二级分类',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    padding: EdgeInsets.zero,
                  ),
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(LucideIcons.pencil, size: 17, color: tokens.textSecondary),
                  tooltip: '编辑分类',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  padding: EdgeInsets.zero,
                ),
                if (children.isNotEmpty)
                  Icon(
                    expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                    size: 18,
                    color: tokens.textDisabled,
                  ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final child in children)
            InkWell(
              onTap: () => onEditChild(child),
              child: Padding(
                padding: EdgeInsets.fromLTRB(tokens.space4 + 30, tokens.space2, tokens.space3, tokens.space2),
                child: Row(
                  children: [
                    Icon(categoryIconData(child.icon), size: 20, color: categoryColor(child.icon)),
                    SizedBox(width: tokens.space2),
                    Expanded(
                      child: Text(
                        child.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: tokens.textPrimary),
                      ),
                    ),
                    Text('已用 ${usage[child.id] ?? 0} 笔', style: TextStyle(fontSize: 11, color: tokens.textSecondary)),
                    SizedBox(width: tokens.space1),
                    Icon(LucideIcons.chevronRight, size: 16, color: tokens.textDisabled),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
