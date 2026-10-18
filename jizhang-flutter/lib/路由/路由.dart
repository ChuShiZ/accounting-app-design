import 'package:go_router/go_router.dart';

import '../页面/首页页.dart';
import '../页面/报表页.dart';
import '../页面/资产页.dart';
import '../页面/我的页.dart';
import '../页面/类别管理页.dart';
import '../页面/设置页.dart';
import '../页面/Excel导入页.dart';
import '../组件/主壳.dart';

GoRouter createAppRouter() {
  return GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [GoRoute(path: '/home', builder: (context, state) => const HomePage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/report', builder: (context, state) => const ReportPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/assets', builder: (context, state) => const AssetsPage())],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfilePage())],
        ),
      ],
    ),
    GoRoute(path: '/categories', builder: (context, state) => const CategoriesPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/import', builder: (context, state) => const ExcelImportPage()),
  ],
  );
}
