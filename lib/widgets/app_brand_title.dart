import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBrandTitle extends StatelessWidget {
  const AppBrandTitle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/course_child_logo.png',
            width: compact ? 28 : 32,
            height: compact ? 28 : 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'Course Child Evaluation',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -.25,
            ),
          ),
        ),
      ],
    );
  }
}
