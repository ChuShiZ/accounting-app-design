import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../主题/令牌.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PageScaffold(
      title: '我的',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              children: [
                _row(
                  context,
                  LucideIcons.settings,
                  '设置',
                  '默认账户 · WebDAV · 备份',
                  onTap: () => context.push('/settings'),
                ),
                Divider(height: 1, color: tokens.divider),
                _row(
                  context,
                  LucideIcons.database,
                  '类别管理',
                  '名称、图标、删除归入其他',
                  onTap: () => context.push('/categories'),
                ),
                Divider(height: 1, color: tokens.divider),
                _row(
                  context,
                  LucideIcons.upload,
                  'Excel 导入',
                  '后续批次接入',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(content: Text('Excel 导入在后续批次实现')));
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.space4),
          Container(
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(color: tokens.border),
            ),
            child: _row(
              context,
              LucideIcons.helpCircle,
              '帮助与反馈',
              '离线记账说明',
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('帮助与反馈在后续批次实现')));
              },
            ),
          ),
          SizedBox(height: tokens.space6),
          Center(
            child: Text('记账 · v16 · Flutter', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
          ),
          SizedBox(height: tokens.space2),
          Center(
            child: Text('数据只保存在本机，WebDAV 仅用于备份', style: TextStyle(fontSize: 11, color: tokens.textDisabled)),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    final tokens = context.tokens;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: tokens.primary, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
      trailing: Icon(LucideIcons.chevronRight, color: tokens.textDisabled, size: 18),
    );
  }
}
