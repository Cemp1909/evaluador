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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1B2444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '$completados of $total contents completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .74),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 104,
            height: 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8.5,
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
