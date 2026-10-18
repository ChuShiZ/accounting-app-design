import 'package:flutter/material.dart';

import '../组件/页面骨架.dart';
import '../主题/令牌.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PageScaffold(
      title: '我的',
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: tokens.border),
        ),
        child: Column(
          children: [
            _row(context, Icons.settings_outlined, '设置', '默认账户 · WebDAV'),
            Divider(height: 1, color: tokens.divider),
            _row(context, Icons.category_outlined, '类别管理', ''),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, IconData icon, String title, String subtitle) {
    final tokens = context.tokens;
    return ListTile(
      leading: Icon(icon, color: tokens.primary, size: 24),
      title: Text(title, style: TextStyle(fontSize: 15, color: tokens.textPrimary)),
      subtitle: subtitle.isEmpty ? null : Text(subtitle, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: tokens.textDisabled, size: 20),
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('该页面在后续批次接入')));
      },
    );
  }
}
