import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class MaterialLabourChart extends StatefulWidget {
  const MaterialLabourChart({
    super.key,
    required this.materialCost,
    required this.labourCost,
  });

  final double materialCost;
  final double labourCost;

  @override
  State<MaterialLabourChart> createState() => _MaterialLabourChartState();
}

class _MaterialLabourChartState extends State<MaterialLabourChart>
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
  void didUpdateWidget(MaterialLabourChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.materialCost != widget.materialCost ||
        oldWidget.labourCost != widget.labourCost) {
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
    final total = widget.materialCost + widget.labourCost;
    if (total <= 0) {
      return const SizedBox(height: 180);
    }
    final materialPct = widget.materialCost / total;
    final labourPct = widget.labourCost / total;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: materialPct * _animation.value * 100,
                title: '${(materialPct * 100).toStringAsFixed(0)}%',
                color: AppColors.primary,
                radius: 48,
                titleStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              PieChartSectionData(
                value: labourPct * _animation.value * 100,
                title: '${(labourPct * 100).toStringAsFixed(0)}%',
                color: AppColors.secondary,
                radius: 48,
                titleStyle: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
