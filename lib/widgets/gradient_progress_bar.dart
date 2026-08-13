import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.trackColor = const Color(0xFFE5ECEB),
    this.complete = false,
  });

  final double value;
  final double height;
  final Color trackColor;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(height),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            width: constraints.maxWidth * value.clamp(0, 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: complete
                    ? const [Color(0xFF4AA77E), AppColors.success]
                    : const [AppColors.accent, Color(0xFFFFC25D)],
              ),
              borderRadius: BorderRadius.circular(height),
              boxShadow: value > 0
                  ? const [BoxShadow(color: Color(0x33F29F3D), blurRadius: 6)]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
