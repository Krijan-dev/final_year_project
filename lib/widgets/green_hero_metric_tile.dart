import "package:flutter/material.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

/// Inner metric cell on green gradient hero cards (dashboard, insights, habits).
class GreenHeroMetricTile extends StatelessWidget {
  const GreenHeroMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
    this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool warning;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppColors.greenHeroInnerTile(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.greenHeroCaption, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppColors.greenHeroTileLabel(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppColors.greenHeroTileValue(warning: warning),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
