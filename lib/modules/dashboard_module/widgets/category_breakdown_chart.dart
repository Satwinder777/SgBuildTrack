import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/material_model.dart';

class CategoryBreakdownChart extends StatefulWidget {
  const CategoryBreakdownChart({super.key, required this.categoryMap});

  final Map<String, double> categoryMap;

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.primaryLight,
    AppColors.secondaryDark,
    AppColors.info,
    AppColors.success,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: AppConstants.chartAnimationMs),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CategoryBreakdownChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryMap != widget.categoryMap) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.categoryMap.entries.toList();
    if (entries.isEmpty) return const SizedBox(height: 120);
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return const SizedBox(height: 120);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: total * 1.2 * _animation.value,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                    style: Get.textTheme.bodySmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx >= 0 && idx < entries.length) {
                      final cat = entries[idx].key;
                      final display = MaterialCategoryX.fromString(cat).displayName;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          display.length > 8 ? '${display.substring(0, 8)}..' : display,
                          style: Get.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            barGroups: entries.asMap().entries.map((e) {
              final i = e.key;
              final v = e.value.value * _animation.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: v,
                    color: _colors[i % _colors.length],
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }).toList(),
          ),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
