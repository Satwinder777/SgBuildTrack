import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Bar chart: labour cost per day for the selected filter period.
class LabourCostChart extends StatefulWidget {
  const LabourCostChart({
    super.key,
    required this.costByDay,
  });

  final Map<DateTime, double> costByDay;

  @override
  State<LabourCostChart> createState() => _LabourCostChartState();
}

class _LabourCostChartState extends State<LabourCostChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  void didUpdateWidget(LabourCostChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.costByDay != widget.costByDay) {
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
    final entries = widget.costByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No labour cost data for this period'),
        ),
      );
    }
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final maxYAxis = (maxY * 1.2).clamp(1.0, double.infinity);
    final dateFormat = DateFormat('d/M');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxYAxis * _animation.value,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  getTitlesWidget: (value, meta) => Text(
                    value >= 1000
                        ? '${(value / 1000).toStringAsFixed(0)}k'
                        : value.toStringAsFixed(0),
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
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          dateFormat.format(entries[idx].key),
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
                    color: AppColors.secondary,
                    width: 16,
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
