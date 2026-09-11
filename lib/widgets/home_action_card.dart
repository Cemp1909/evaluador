import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeActionCard extends StatefulWidget {
  const HomeActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.accentColor,
    this.prominent = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? accentColor;
  final bool prominent;

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accentColor ?? AppColors.accent;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? .984 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 3,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: dark ? .26 : .16),
                          accent.withValues(alpha: dark ? .10 : .05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.small + 2),
                      border: Border.all(
                        color: accent.withValues(alpha: dark ? .35 : .22),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      color: dark ? Colors.white : scheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: dark ? .20 : .12),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: dark ? .35 : .25,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              widget.badge!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: scheme.onSurfaceVariant.withValues(alpha: .6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
