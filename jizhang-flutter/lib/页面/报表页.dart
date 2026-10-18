import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '收支报表',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlaceholderCard(
            title: '报表在批次 6 接入',
            description: '周报/月报/季报/年报、支出/收入切换、四项汇总、趋势、分类构成、对比与排行。',
            icon: LucideIcons.barChart3,
          ),
        ],
      ),
    );
  }
}
