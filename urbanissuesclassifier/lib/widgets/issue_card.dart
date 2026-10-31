import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/widgets/status_badge.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:intl/intl.dart';

class IssueCard extends StatelessWidget {
  final ComplaintModel issue;
  final VoidCallback onTap;

  const IssueCard({super.key, required this.issue, required this.onTap});

  Color get typeColor {
    switch (issue.type) {
      case ComplaintType.pothole:
        return AppTheme.warningOrange;
      case ComplaintType.garbage:
        return AppTheme.alertRed;
      case ComplaintType.paintedHump:
        return AppTheme.primaryTeal;
      case ComplaintType.unpaintedHump:
        return AppTheme.primaryTeal;
      case ComplaintType.other:
        return AppTheme.mediumGrey;
    }
  }

  IconData get typeIcon {
    switch (issue.type) {
      case ComplaintType.pothole:
        return Icons.warning_rounded;
      case ComplaintType.garbage:
        return Icons.delete_rounded;
      case ComplaintType.paintedHump:
        return Icons.speed_rounded;
      case ComplaintType.unpaintedHump:
        return Icons.speed_rounded;
      case ComplaintType.other:
        return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Type Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      issue.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Coordinates (from latitude/longitude)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${issue.latitude.toStringAsFixed(4)}, ${issue.longitude.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date and Status
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM dd, yyyy').format(issue.reportedDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusBadge(status: issue.status, showIcon: false),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
