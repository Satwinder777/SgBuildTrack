import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Grouped bar chart: present vs absent per day for the selected filter period.
class AttendanceChart extends StatefulWidget {
  const AttendanceChart({
    super.key,
    required this.attendanceByDay,
  });

  final Map<DateTime, ({int present, int absent})> attendanceByDay;

  @override
  State<AttendanceChart> createState() => _AttendanceChartState();
}

class _AttendanceChartState extends State<AttendanceChart>
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
  void didUpdateWidget(AttendanceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendanceByDay != widget.attendanceByDay) {
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
    final entries = widget.attendanceByDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (entries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No attendance data for this period'),
        ),
      );
    }
    final maxVal = entries.fold<int>(
      0,
      (m, e) {
        final t = e.value.present + e.value.absent;
        return t > m ? t : m;
      },
    );
    final maxY = (maxVal * 1.2).clamp(1.0, double.infinity);
    final dateFormat = DateFormat('d/M');

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * _animation.value,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
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
              final v = e.value.value;
              return BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: (v.present * _animation.value).toDouble(),
                    color: AppColors.success,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                  BarChartRodData(
                    toY: (v.absent * _animation.value).toDouble(),
                    color: AppColors.error,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ],
                showingTooltipIndicators: [0, 1],
              );
            }).toList(),
          ),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
