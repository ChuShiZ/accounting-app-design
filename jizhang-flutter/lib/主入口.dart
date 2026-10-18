import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '主题/主题.dart';
import '路由/路由.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: JizhangApp()));
}

class JizhangApp extends StatelessWidget {
  const JizhangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '记账',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
