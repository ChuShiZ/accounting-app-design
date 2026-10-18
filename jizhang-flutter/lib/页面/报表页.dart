import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../组件/页面骨架.dart';
import '../组件/类别展示.dart';
import '../组件/账户展示.dart';
import '../组件/记账表单.dart';
import '../数据/仓库/报表仓库.dart';
import '../状态/提供者.dart';
import '../主题/令牌.dart';

class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  String? _selectedCategory;
  bool _showAllCats = false;
  bool _showAllTop = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final period = ref.watch(reportPeriodProvider);
    final kind = ref.watch(reportKindProvider);
    final offset = ref.watch(reportOffsetProvider);
    final dataAsync = ref.watch(reportDataProvider);
    return PageScaffold(
      title: '收支报表',
      child: dataAsync.when(
        loading: () => Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.space10),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: tokens.primary)),
        ),
        error: (error, stack) => Text('报表加载失败：$error', style: TextStyle(color: tokens.expense)),
        data: (data) {
          final filteredTop = _selectedCategory == null
              ? data.top
              : data.top.where((item) => item.categoryName == _selectedCategory).toList();
          final visibleTop = filteredTop.take(_showAllTop ? 20 : 8).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PeriodTabs(
                period: period,
                onChanged: (value) {
                  ref.read(reportPeriodProvider.notifier).state = value;
                  ref.read(reportOffsetProvider.notifier).state = 0;
                  setState(() {
                    _selectedCategory = null;
                    _showAllCats = false;
                    _showAllTop = false;
                  });
                },
              ),
              SizedBox(height: tokens.space3),
              Row(
                children: [
                  _periodArrow(context, LucideIcons.chevronLeft, () {
                    ref.read(reportOffsetProvider.notifier).state = offset - 1;
                  }),
                  Expanded(
                    child: Center(
                      child: Text(
                        _periodText(period, data),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                      ),
                    ),
                  ),
                  _periodArrow(
                    context,
                    LucideIcons.chevronRight,
                    offset >= 0 ? null : () => ref.read(reportOffsetProvider.notifier).state = offset + 1,
                    mirrored: true,
                  ),
                  SizedBox(width: tokens.space2),
                  _KindSwitch(
                    kind: kind,
                    onChanged: (value) {
                      ref.read(reportKindProvider.notifier).state = value;
                      setState(() {
                        _selectedCategory = null;
                        _showAllCats = false;
                        _showAllTop = false;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: tokens.space4),
              _SummaryCard(data: data, period: period, kind: kind),
              SizedBox(height: tokens.space4),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHead(context, '${kind == 'income' ? '收入' : '支出'}趋势', _periodText(period, data)),
                    SizedBox(height: tokens.space3),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: _TrendPainter(
                          values: data.trend,
                          color: kind == 'income' ? tokens.income : tokens.primary,
                          gridColor: tokens.divider,
                          labelColor: tokens.textSecondary,
                          labels: data.trendLabels,
                          kindLabel: kind == 'income' ? '收入' : '支出',
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.space4),
              _CategoryCard(
                data: data,
                kind: kind,
                showAll: _showAllCats,
                onToggleAll: () => setState(() => _showAllCats = !_showAllCats),
                selected: _selectedCategory,
                onSelect: (name) => setState(() {
                  _selectedCategory = _selectedCategory == name ? null : name;
                  _showAllTop = false;
                }),
              ),
              SizedBox(height: tokens.space4),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHead(context, '${period == '年' ? '年' : (period == '季' ? '季' : (period == '周' ? '周' : '月'))}${kind == 'income' ? '收入' : '支出'}对比', '近 5 期'),
                    SizedBox(height: tokens.space4),
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final item in data.comparison)
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: tokens.space1),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      _compact(item.amount),
                                      style: TextStyle(fontSize: 10, color: tokens.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: tokens.space1),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: FractionallySizedBox(
                                          heightFactor: _barFactor(item.amount, data.comparison),
                                          child: Container(
                                            width: 22,
                                            decoration: BoxDecoration(
                                              color: item.current ? tokens.primary : tokens.primarySoft,
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(tokens.radiusSm)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: tokens.space2),
                                    Text(item.label, style: TextStyle(fontSize: 10, color: tokens.textSecondary)),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.space4),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory == null
                                ? '${_periodText(period, data)}${kind == 'income' ? '收入' : '支出'}排行'
                                : '「$_selectedCategory」${kind == 'income' ? '收入' : '支出'}排行',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary),
                          ),
                        ),
                        if (_selectedCategory != null)
                          TextButton(
                            onPressed: () => setState(() => _selectedCategory = null),
                            child: const Text('清除筛选'),
                          ),
                      ],
                    ),
                    SizedBox(height: tokens.space2),
                    if (filteredTop.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: tokens.space8),
                        child: Center(child: Text('暂无记录', style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
                      )
                    else ...[
                      for (var i = 0; i < visibleTop.length; i++) ...[
                        _RankRow(item: visibleTop[i], kind: kind, onTap: () => showRecordSheet(context, transaction: visibleTop[i].transaction)),
                        if (i < visibleTop.length - 1) Divider(height: 1, color: tokens.divider),
                      ],
                      if (filteredTop.length > 8)
                        TextButton(
                          onPressed: () => setState(() => _showAllTop = !_showAllTop),
                          child: Text(_showAllTop ? '收起' : '全部排行'),
                        ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: tokens.space6),
            ],
          );
        },
      ),
    );
  }

  Widget _periodArrow(BuildContext context, IconData icon, VoidCallback? onTap, {bool mirrored = false}) {
    final tokens = context.tokens;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: onTap == null ? tokens.textDisabled : tokens.textSecondary),
      style: IconButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
      tooltip: mirrored ? '下一期' : '上一期',
    );
  }

  Widget _sectionHead(BuildContext context, String title, String caption) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
        Text(caption, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
      ],
    );
  }

  String _periodText(String period, ReportData data) {
    final from = data.from;
    if (period == '周') {
      final to = data.to;
      return '${from.month}-${from.day.toString().padLeft(2, '0')} 至 ${to.month}-${to.day.toString().padLeft(2, '0')}';
    }
    if (period == '季') return '${from.year} Q${((from.month - 1) ~/ 3) + 1}';
    if (period == '年') return '${from.year}年';
    return '${from.year}年${from.month}月';
  }

  double _barFactor(int amount, List<ReportComparison> comparison) {
    final max = comparison.map((e) => e.amount).fold<int>(0, math.max);
    if (max <= 0) return 0;
    return math.max(0.03, amount / max);
  }

  String _compact(int cents) {
    final yuan = cents / 100;
    if (yuan.abs() >= 10000) return '${(yuan / 10000).toStringAsFixed(2)}万';
    return yuan.toStringAsFixed(0);
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.period, required this.onChanged});

  final String period;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const tabs = ['周报', '月报', '季报', '年报'];
    const keys = ['周', '月', '季', '年'];
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.border))),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(keys[i]),
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        tabs[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: period == keys[i] ? FontWeight.w600 : FontWeight.w500,
                          color: period == keys[i] ? tokens.primary : tokens.textSecondary,
                        ),
                      ),
                      if (period == keys[i])
                        Positioned(
                          bottom: 0,
                          child: Container(
                            width: 22,
                            height: 2,
                            decoration: BoxDecoration(color: tokens.primary, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KindSwitch extends StatelessWidget {
  const _KindSwitch({required this.kind, required this.onChanged});

  final String kind;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: tokens.surface2, borderRadius: BorderRadius.circular(tokens.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(context, '支出', kind == 'expense', () => onChanged('expense')),
          _button(context, '收入', kind == 'income', () => onChanged('income')),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, String label, bool active, VoidCallback onTap) {
    final tokens = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? tokens.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusFull),
          boxShadow: active ? const [BoxShadow(color: Color(0x0F101828), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: active ? tokens.primary : tokens.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data, required this.period, required this.kind});

  final ReportData data;
  final String period;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final kindLabel = kind == 'income' ? '收入' : '支出';
    final periodWord = period == '年' ? '本年' : (period == '季' ? '本季' : (period == '周' ? '本周' : '本月'));
    final prevWord = period == '年' ? '上年' : (period == '季' ? '上季' : (period == '周' ? '上周' : '上月'));
    final avgLabel = (period == '年' || period == '季') ? '月均$kindLabel' : '日均$kindLabel';
    final avg = period == '年' ? data.total ~/ 12 : (period == '季' ? data.total ~/ 3 : data.daily);
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _metric(context, '$periodWord$kindLabel', formatCents(data.total))),
              Expanded(child: _metric(context, avgLabel, formatCents(avg))),
            ],
          ),
          SizedBox(height: tokens.space4),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  '比$prevWord$kindLabel${data.changePct == null ? '' : ' ${data.changePct! >= 0 ? '+' : ''}${data.changePct}%'}',
                  formatCents(data.change, signed: true),
                ),
              ),
              Expanded(child: _metric(context, '收支结余', formatCents(data.balance, signed: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: tokens.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: tokens.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.data,
    required this.kind,
    required this.showAll,
    required this.onToggleAll,
    required this.selected,
    required this.onSelect,
  });

  final ReportData data;
  final String kind;
  final bool showAll;
  final VoidCallback onToggleAll;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final list = showAll ? data.categories : data.categories.take(6).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('${kind == 'income' ? '收入' : '支出'}分类构成', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: tokens.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: tokens.primaryLight, borderRadius: BorderRadius.circular(tokens.radiusFull)),
                child: Text('主分类', style: TextStyle(fontSize: 11, color: tokens.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (data.categories.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.space8),
              child: Center(child: Text('暂无${kind == 'income' ? '收入' : '支出'}记录', style: TextStyle(fontSize: 13, color: tokens.textSecondary))),
            )
          else ...[
            SizedBox(height: tokens.space4),
            _DonutWithLabels(
              categories: data.categories,
              total: data.total,
              kind: kind,
            ),
            SizedBox(height: tokens.space3),
            for (var i = 0; i < list.length; i++) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(list[i].name),
                child: Container(
                  color: selected == list[i].name ? tokens.primaryLight : Colors.transparent,
                  padding: EdgeInsets.symmetric(vertical: tokens.space3, horizontal: selected == list[i].name ? tokens.space2 : 0),
                  child: Row(
                    children: [
                      Text('#${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tokens.primary)),
                      SizedBox(width: tokens.space2),
                      Icon(categoryIconData(list[i].icon), size: 24, color: categoryColor(list[i].icon)),
                      SizedBox(width: tokens.space2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(list[i].name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tokens.textPrimary)),
                            SizedBox(height: 1),
                            Text('${list[i].count} 笔 · ${list[i].pct}%', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        formatCents(list[i].amount),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kind == 'income' ? tokens.income : tokens.expense, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      SizedBox(width: tokens.space1),
                      Icon(LucideIcons.chevronRight, size: 16, color: tokens.textDisabled),
                    ],
                  ),
                ),
              ),
              if (i < list.length - 1) Divider(height: 1, color: tokens.divider),
            ],
            if (data.categories.length > 6)
              TextButton(onPressed: onToggleAll, child: Text(showAll ? '收起' : '查看更多')),
          ],
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.item, required this.kind, required this.onTap});

  final ReportItem item;
  final String kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final t = item.transaction;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.space3),
        child: Row(
          children: [
            Icon(
              categoryIconData(item.categoryIcon),
              size: 24,
              color: categoryColor(item.categoryIcon),
            ),
            SizedBox(width: tokens.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.note?.isNotEmpty == true ? t.note! : item.categoryName, style: TextStyle(fontSize: 15, color: tokens.textPrimary), overflow: TextOverflow.ellipsis),
                  SizedBox(height: 2),
                  Text('${formatDate(DateTime.fromMillisecondsSinceEpoch(t.occurredAt))} · ${item.accountName}', style: TextStyle(fontSize: 11, color: tokens.textSecondary), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            SizedBox(width: tokens.space2),
            Text(
              '${kind == 'income' ? '+' : '-'}${formatCents(t.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kind == 'income' ? tokens.income : tokens.expense,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutWithLabels extends StatelessWidget {
  const _DonutWithLabels({required this.categories, required this.total, required this.kind});

  final List<ReportCategory> categories;
  final int total;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    const width = 310.0;
    const height = 220.0;
    const center = Offset(155, 110);
    const radius = 62.0;
    final items = <_DonutLabel>[];
    var off = 0.0;
    final top = categories.take(6).toList();
    for (final cat in top) {
      final fraction = total <= 0 ? 0.0 : cat.amount / total;
      final mid = -math.pi / 2 + (off + fraction / 2) * math.pi * 2;
      off += fraction;
      items.add(_DonutLabel(
        name: cat.name,
        pct: cat.pct,
        x: center.dx + math.cos(mid) * radius,
        y: center.dy + math.sin(mid) * radius,
        naturalY: center.dy + math.sin(mid) * 84,
        right: math.cos(mid) >= 0,
        color: categoryColor(cat.icon),
      ));
    }
    for (final right in [false, true]) {
      final side = items.where((e) => e.right == right).toList()..sort((a, b) => a.naturalY.compareTo(b.naturalY));
      var y = 18.0;
      for (final item in side) {
        y = math.max(y, item.naturalY);
        item.labelY = y;
        y += 22;
      }
      final overflow = y - 22 - (height - 8);
      if (overflow > 0) {
        for (final item in side) {
          item.labelY -= overflow;
        }
      }
    }
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(width, height),
            painter: _DonutPainter(
              categories: categories,
              total: total,
              center: center,
              radius: radius,
              showLeaders: true,
              labels: items,
            ),
          ),
          Positioned(
            left: center.dx - 70,
            top: center.dy - 24,
            width: 140,
            child: Column(
              children: [
                Text('${kind == 'income' ? '收入' : '支出'}合计', style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
                Text(
                  formatCents(total),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tokens.textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          for (final item in items)
            Positioned(
              right: item.right ? 4 : null,
              left: item.right ? null : 4,
              top: item.labelY - 8,
              width: 84,
              child: Row(
                mainAxisAlignment: item.right ? MainAxisAlignment.start : MainAxisAlignment.end,
                children: [
                  if (!item.right) ...[],
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: item.color, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${item.name.length > 5 ? '${item.name.substring(0, 5)}…' : item.name} ${item.pct}%',
                      style: TextStyle(fontSize: 9.5, color: tokens.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DonutLabel {
  _DonutLabel({
    required this.name,
    required this.pct,
    required this.x,
    required this.y,
    required this.naturalY,
    required this.right,
    required this.color,
  });

  final String name;
  final int pct;
  final double x;
  final double y;
  final double naturalY;
  final bool right;
  final Color color;
  double labelY = 0;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsets.all(tokens.space4),
      decoration: BoxDecoration(
        color: tokens.bg,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: child,
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.color,
    required this.gridColor,
    required this.labelColor,
    required this.labels,
    required this.kindLabel,
  });

  final List<int> values;
  final Color color;
  final Color gridColor;
  final Color labelColor;
  final List<String> labels;
  final String kindLabel;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const top = 18.0;
    final bottom = size.height - 24;
    final left = 8.0;
    final right = size.width - 8;
    final max = values.fold<int>(0, math.max);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = top + (bottom - top) * i / 3;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
    }
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? (left + right) / 2 : left + (right - left) * i / (values.length - 1);
      final y = max <= 0 ? bottom : bottom - (bottom - top) * values[i] / max;
      points.add(Offset(x, y));
    }
    final area = Path()
      ..moveTo(points.first.dx, bottom)
      ..lineTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      area.lineTo(points[i].dx, points[i].dy);
    }
    area
      ..lineTo(points.last.dx, bottom)
      ..close();
    final fill = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withValues(alpha: .22), color.withValues(alpha: .01)]).createShader(Rect.fromLTRB(left, top, right, bottom));
    canvas.drawPath(area, fill);
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);
    final maxIndex = values.indexOf(max);
    if (max > 0) {
      final p = points[maxIndex];
      final dot = Paint()..color = color;
      canvas.drawCircle(p, 3.5, dot);
      final text = '${labels.length > maxIndex ? labels[maxIndex] : ''}$kindLabel ${formatCents(max)}';
      final tp = TextPainter(
        text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(p.dx, math.max(12, p.dy - 22)), width: tp.width + 12, height: 20),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = color);
      tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
    }
    for (var i = 0; i < labels.length; i++) {
      final x = labels.length == 1 ? (left + right) / 2 : left + (right - left) * i / (labels.length - 1);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: TextStyle(color: labelColor, fontSize: 9)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.categories,
    required this.total,
    this.center,
    this.radius,
    this.showLeaders = false,
    this.labels = const [],
  });

  final List<ReportCategory> categories;
  final int total;
  final Offset? center;
  final double? radius;
  final bool showLeaders;
  final List<_DonutLabel> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final centerPoint = center ?? size.center(Offset.zero);
    final radiusValue = radius ?? math.min(size.width, size.height) / 2 - 16;
    final rect = Rect.fromCircle(center: centerPoint, radius: radiusValue);
    final background = Paint()
      ..color = const Color(0xFFF0F2F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18;
    canvas.drawCircle(centerPoint, radiusValue, background);
    var start = -math.pi / 2;
    for (final cat in categories) {
      final sweep = total <= 0 ? 0.0 : cat.amount / total * math.pi * 2;
      final paint = Paint()
        ..color = categoryColor(cat.icon)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, math.max(0, sweep - 0.01), false, paint);
      start += sweep;
    }
    if (showLeaders) {
      for (final label in labels) {
        final leader = Paint()
          ..color = label.color.withValues(alpha: .45)
          ..strokeWidth = 1;
        final targetX = label.right ? size.width - 92.0 : 92.0;
        canvas.drawLine(Offset(label.x, label.y), Offset(targetX, label.labelY), leader);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories || oldDelegate.total != total || oldDelegate.labels != labels;
}
