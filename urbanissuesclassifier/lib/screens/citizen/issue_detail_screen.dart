import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/widgets/status_badge.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';
import 'package:intl/intl.dart';

class IssueDetailScreen extends StatelessWidget {
  const IssueDetailScreen({super.key});

  Color getTypeColor(ComplaintType type) {
    switch (type) {
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

  IconData getTypeIcon(ComplaintType type) {
    switch (type) {
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
    final issue = ModalRoute.of(context)?.settings.arguments as ComplaintModel?;

    // Safety check for null
    if (issue == null) {
      return const CurvedBackgroundScaffold(
        title: 'Error',
        body: Center(
          child: Text(
            'Issue not found',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return CurvedBackgroundScaffold(
      title: 'Issue Details',
      topContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getTypeIcon(issue.type),
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      issue.type.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(
                status: issue.status,
              ), // Maybe need to inverse colors? Standard badge is fine.
            ],
          ),
          const SizedBox(height: 16),
          Text(
            issue.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.7),
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lat: ${issue.latitude.toStringAsFixed(4)}, Lng: ${issue.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section (Rounded)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: issue.imageUrl != null && issue.imageUrl!.isNotEmpty
                    ? Image.network(
                        '${ApiService.baseUrl.replaceAll('/api', '')}${issue.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_rounded,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Date & AI Score
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppTheme.royalBlue,
                    title: 'Reported',
                    content: DateFormat(
                      'MMM dd, yyyy',
                    ).format(issue.reportedDate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.analytics_rounded,
                    iconColor: AppTheme.statusResolved,
                    title: 'Confidence',
                    content: '${(issue.confidenceScore * 100).toInt()}%',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
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
              child: Text(
                issue.description,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Timeline
            const Text(
              'Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              child: Column(
                children: [
                  _buildTimelineItem(
                    'Issue Reported',
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(issue.reportedDate),
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.statusResolved
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              if (title != 'Verification Pending') // Simple line logic
                Container(width: 2, height: 30, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
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
