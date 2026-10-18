import 'package:flutter/material.dart';

import '../组件/页面骨架.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: '资产',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PlaceholderCard(
            title: '资产在批次 1 接入',
            description: '银行卡、储值卡、存单、信用卡、贷款；添加与编辑账户；余额由流水派生。',
            icon: Icons.account_balance_outlined,
          ),
        ],
      ),
    );
  }
}
