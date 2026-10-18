import 'package:flutter/material.dart';

import '../组件/页面骨架.dart';
import '../主题/令牌.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return PageScaffold(
      subtitle: '2026年6月22日 周一',
      title: '我的账单',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(tokens.space5),
            decoration: BoxDecoration(
              color: tokens.bg,
              borderRadius: BorderRadius.circular(tokens.radiusXl),
              border: Border.all(color: tokens.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日支出', style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                SizedBox(height: tokens.space1),
                Text('—', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: tokens.textPrimary)),
                SizedBox(height: tokens.space4),
                Row(
                  children: [
                    Expanded(child: _miniMetric(context, '本月支出', '—')),
                    Expanded(child: _miniMetric(context, '本月收入', '—', alignEnd: true)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: tokens.space4),
          const PlaceholderCard(
            title: '工程骨架已就绪',
            description: '批次 0：主题令牌、4 Tab、drift schema、Repository 与测试。批次 1 开始接入资产与账户。',
            icon: Icons.layers_outlined,
          ),
          SizedBox(height: tokens.space3),
          const PlaceholderCard(
            title: '下一步：资产与账户',
            description: '银行卡、储值卡、贷款的新增/编辑，随后接入首页流水与记一笔。',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(BuildContext context, String label, String value, {bool alignEnd = false}) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
        SizedBox(height: tokens.space1),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary)),
      ],
    );
  }
}
