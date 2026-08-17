import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EvaluacionProgressCard extends StatelessWidget {
  const EvaluacionProgressCard({
    super.key,
    required this.completados,
    required this.total,
  });

  final int completados;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completados / total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF211329)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2417213C),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Your Progress',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$completados of $total contents completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .74),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: .16),
                  valueColor: AlwaysStoppedAnimation(
                    progress == 1 ? AppColors.success : AppColors.accent,
                  ),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
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
