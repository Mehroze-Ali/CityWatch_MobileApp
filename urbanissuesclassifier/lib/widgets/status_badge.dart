import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final bool showIcon;

  const StatusBadge({super.key, required this.status, this.showIcon = true});

  Color get backgroundColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppTheme.statusPending.withOpacity(0.1);
      case ComplaintStatus.resolved:
        return AppTheme.statusResolved.withOpacity(0.1);
    }
  }

  Color get textColor {
    switch (status) {
      case ComplaintStatus.pending:
        return AppTheme.statusPending;
      case ComplaintStatus.resolved:
        return AppTheme.statusResolved;
    }
  }

  IconData get icon {
    switch (status) {
      case ComplaintStatus.pending:
        return Icons.schedule_rounded;
      case ComplaintStatus.resolved:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
