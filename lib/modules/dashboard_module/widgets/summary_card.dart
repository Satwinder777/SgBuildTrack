import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/widgets/animated_card.dart';
import '../../../../presentation/widgets/animated_counter.dart';
import '../../../../core/constants/app_constants.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.gradient,
    this.delayMs = 0,
    this.prefix = '₹',
    this.suffix = '',
  });

  final String title;
  final double amount;
  final IconData icon;
  final Gradient? gradient;
  final int delayMs;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      delayMs: delayMs,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient ?? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.08),
                AppColors.primaryLight.withOpacity(0.04),
              ],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.primary, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: Get.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedCounter(
                      value: amount,
                      style: Get.textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      durationMs: AppConstants.chartAnimationMs,
                      prefix: prefix,
                      suffix: suffix,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
