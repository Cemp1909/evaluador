import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.trackColor,
    this.complete = false,
  });

  final double value;
  final double height;
  final Color? trackColor;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color:
                trackColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutExpo,
            width: constraints.maxWidth * value.clamp(0, 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: complete
                    ? const [Color(0xFF3A9A7B), AppColors.success]
                    : const [Color(0xFF526897), AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        );
      },
    );
  }
}
