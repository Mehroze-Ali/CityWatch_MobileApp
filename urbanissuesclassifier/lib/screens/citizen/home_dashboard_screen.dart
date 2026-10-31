import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/models/user_model.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/widgets/custom_bottom_nav.dart';
import 'package:urbanissuesclassifier/widgets/issue_card.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';
import 'package:urbanissuesclassifier/routes/app_routes.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentNavIndex = 0;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  Map<String, dynamic> _stats = {'total': 0, 'byStatus': {}};
  List<ComplaintModel> _recentComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = _apiService.currentUser;

      // Fetch user's complaints
      final complaintsResult = await _apiService.getUserComplaints();
      if (complaintsResult['success']) {
        final List<ComplaintModel> allUserComplaints =
            List<ComplaintModel>.from(complaintsResult['complaints']);

        // Sort by date descending (newest first)
        allUserComplaints.sort(
          (a, b) => b.reportedDate.compareTo(a.reportedDate),
        );

        _recentComplaints = allUserComplaints.take(5).toList();

        // Calculate stats from user complaints
        int total = allUserComplaints.length;
        int resolved = allUserComplaints
            .where((c) => c.status == ComplaintStatus.resolved)
            .length;

        _stats = {
          'total': total,
          'byStatus': {'resolved': resolved},
        };
      }

      // We no longer need global stats for this view
      // final statsResult = await _apiService.getStatistics();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      );
    }

    final userName = _currentUser?.name.split(' ').first ?? 'Citizen';
    final int totalIssues = _stats['total'] ?? 0;
    final int resolvedIssues = (_stats['byStatus']?['resolved'] ?? 0).toInt();
    final double completionRate = totalIssues > 0
        ? (resolvedIssues / totalIssues)
        : 0.0;

    return CurvedBackgroundScaffold(
      topHeightFactor: 0.50,
      topContent: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            userName.isNotEmpty ? userName[0] : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Analytics Card
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.statistics);
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2A777C), Color(0xFF0B4B54)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Performance Overview',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$totalIssues Total Reports',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: completionRate,
                                strokeWidth: 5,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                color: AppTheme.warningOrange,
                              ),
                              Text(
                                '${(completionRate * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Action Button: "Report New Issue"
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.reportIssue);
                },
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Report New Issue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryTeal.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Recent Reports Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Recent Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.issuesHistory);
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List View of Recent Reports
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _recentComplaints.isEmpty
                    ? const Center(child: Text('No reports yet.'))
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _recentComplaints.length,
                        itemBuilder: (context, index) {
                          return IssueCard(
                            issue: _recentComplaints[index],
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.issueDetail,
                                arguments: _recentComplaints[index],
                              ).then((_) => _loadData());
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _currentNavIndex = 0;
            });
          } else if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.issuesHistory).then((_) {
              _loadData();
              setState(() {
                _currentNavIndex = 0;
              });
            });
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.adminLogin);
          }
        },
      ),
    );
  }
}

// Curve clipper is provided by CurvedBackgroundScaffold; no local clipper needed.
