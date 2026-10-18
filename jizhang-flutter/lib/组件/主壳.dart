import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../主题/令牌.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Scaffold(
      backgroundColor: tokens.surface,
      body: navigationShell,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        onTab: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onAdd: () => _openRecordPlaceholder(context),
      ),
    );
  }

  Future<void> _openRecordPlaceholder(BuildContext context) async {
    final tokens = context.tokens;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.space4,
            tokens.space2,
            tokens.space4,
            tokens.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('记一笔', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
              SizedBox(height: tokens.space2),
              Text(
                '批次 2 接入金额、类别、账户、日期、图片与备注。',
                style: TextStyle(fontSize: 13, color: tokens.textSecondary, height: 1.5),
              ),
              SizedBox(height: tokens.space4),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.currentIndex,
    required this.onTab,
    required this.onAdd,
  });

  final int currentIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border(top: BorderSide(color: tokens.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _tab(context, 0, LucideIcons.home, '首页'),
              _tab(context, 1, LucideIcons.barChart3, '报表'),
              Expanded(child: _addButton(context)),
              _tab(context, 2, LucideIcons.wallet, '资产'),
              _tab(context, 3, LucideIcons.user, '我的'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final tokens = context.tokens;
    final active = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? tokens.primary : tokens.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active ? tokens.primary : tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: onAdd,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tokens.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.plus, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 1),
          Text(
            '记一笔',
            style: TextStyle(fontSize: 11, color: tokens.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
