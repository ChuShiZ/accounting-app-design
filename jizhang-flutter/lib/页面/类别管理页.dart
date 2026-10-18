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
        tooltip: '新增类别',
      ),
      child: categoriesAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space10),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary)),
        ),
        error: (error, stack) => Text('类别加载失败：$error', style: TextStyle(color: tokens.expense)),
        data: (all) {
          final list = all.where((c) => c.type == _type).toList();
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
              Container(
                decoration: BoxDecoration(color: tokens.bg, border: Border.all(color: tokens.border), borderRadius: BorderRadius.circular(tokens.radiusLg)),
                child: Column(
                  children: [
                    for (var i = 0; i < list.length; i++) ...[
                      _CategoryTile(
                        category: list[i],
                        usage: usage[list[i].id] ?? 0,
                        onTap: () => showCategoryForm(context, category: list[i], type: list[i].type),
                      ),
                      if (i < list.length - 1) Divider(height: 1, indent: 56, color: tokens.divider),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.space3),
                child: Text(
                  '点击类别可修改名称和图标；右上 + 新增类别。删除已用类别时流水归入【其他】。',
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.usage, required this.onTap});

  final CategoryRow category;
  final int usage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.space4, vertical: tokens.space3),
        child: Row(
          children: [
            Icon(categoryIconData(category.icon), size: 24, color: categoryColor(category.icon)),
            SizedBox(width: tokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: tokens.textPrimary)),
                  SizedBox(height: 1),
                  Text('已用 $usage 笔', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                ],
              ),
            ),
            if (category.isFixed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(4)),
                child: Text('固定', style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
              ),
            SizedBox(width: tokens.space1),
            Icon(LucideIcons.chevronRight, size: 18, color: tokens.textDisabled),
          ],
        ),
      ),
    );
  }
}
