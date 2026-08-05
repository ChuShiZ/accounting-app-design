# 设计-UI架构

> 状态：定稿 ｜ 关联：ADR-017（技术栈）/ ADR-018（主题映射）/ ADR-019（导航模型）
> 基准：`DESIGN.md`（令牌/组件规范）｜ `ANDROID_PLAN.md`（批次）

## 1. 状态管理：Riverpod

| 方案 | 权衡 |
|---|---|
| Provider | 过薄，无依赖注入体系，页面多了靠 setState 传递 |
| Bloc | 事件驱动完备，但自用规模（页面 ≤12）属于过度设计 |
| **Riverpod（选定）** | 声明式 + 自动依赖追踪 + 编译期安全 + 测试友好，AI 生成代码清晰 |

**结构约定**：
- `Provider<Repository>`：注入仓库单例（顶层）
- 页面级 `AsyncNotifierProvider`：首页流水、报表聚合、卡片列表、周期列表、搜索
- 数据变更（记账/删卡/导入/恢复）→ `invalidate` 相关 provider 或 notifier 内刷新；页面 `watch` 消费
- WebDAV 恢复整库替换 → 全局刷新所有 provider

## 2. 路由：go_router + StatefulShellRoute

**导航模型（原型还原）**：
- 4 Tab 主框架 = `StatefulShellRoute.indexedStack`（各 Tab 独立状态，保持滚动位置）
- Tab 内全屏页用 `Navigator.push`（栈式）
- **Sheet 类页面不走路由**，统一 `showModalBottomSheet`

**路由表**：

| 路径 | 页面 | 类型 |
|---|---|---|
| `/`（Shell） | 首页 / 报表 / 卡片 / 我的 | 4 Tab |
| `/periodic` | 周期性支出 | push |
| `/search` | 明细搜索 | push |
| `/categories` | 类别管理 | push |
| `/settings` | 设置 | push |

**BottomSheet 清单（不走路由）**：记账、卡片详情+编辑、添加卡片、周期详情、提前还款、有效期编辑、编辑周期、筛选、充值
**二级 Sheet**（sub-sheet 层叠）：提前还款 / 有效期编辑 / 编辑周期

## 3. 主题映射（DESIGN.md 令牌 → Flutter）

**令牌层**：`AppTokens`（ThemeExtension）承载全部令牌——色板、圆角、间距、阴影、字号；组件只消费令牌，禁止硬编码（延续 DESIGN.md §5 纪律）。

| 类别 | 映射 |
|---|---|
| ColorScheme | primary `#4F46E5`、primaryContainer `#EEF2FF`、error `#E5484D`、surface `#F7F8FA`、surfaceVariant `#F1F3F7`、outline `#E5E8EF`；四态语义色入 AppTokens（income/expense/liability/balance） |
| TextTheme | amount-xl 34/700、amount-lg 22/600、amount-md 17/600、h1 20/600、h2 17/600、body-lg 16/500、body 15/400、caption 13、micro 12；金额一律 `fontFeatures: [tabularFigures]` |
| 圆角/间距/阴影 | radius sm6/md10/lg16/xl20/full999；space 4 基准；shadow xs/sm/md/lg/fab |

**组件级定制清单**：
- TabBar：顶部 2px×24px 圆角指示条 + 文字着色（**不用 Material 默认胶囊**）
- FAB：56px 圆角 999、primary 底、fab 阴影、按压缩放 .96
- BottomSheet：顶部 radius-xl（showModalBottomSheet 的 shape）
- Chip：radius-sm 胶囊，选中态 primary-light 底 + primary 边框文字
- 金额组件 `金额.dart`：右对齐 + tnum + 千分位 + fitAmount 自适应（禁止缩写）
- 分段控件：surface-2 胶囊容器 + 选中白底阴影
- Toast/空态/进度条：按 DESIGN.md 组件规范实现
- **仅浅色**（MaterialApp `themeMode: ThemeMode.light`）

## 4. 工程配置

| 项 | 值 |
|---|---|
| applicationId | `com.self.jizhang` |
| 应用显示名 | 记账 |
| minSdk / targetSdk | 26 / 36（Android 16） |
| 权限 | INTERNET（WebDAV）、CAMERA（拍照）；photo picker 免权限 |
| 深色模式 | 不做（DESIGN.md 仅浅色） |

## 5. 状态-路由-数据流小结

```
页面(watch Riverpod) → Notifier → Repository → drift
                                   ↕
                     WebDAV 同步层（备份/恢复后 invalidate 全局）
```

- 页面不直接碰数据库（延续 Repository 单入口原则）
- 恢复流程：关连接→替换→重开→invalidate 全部 provider
