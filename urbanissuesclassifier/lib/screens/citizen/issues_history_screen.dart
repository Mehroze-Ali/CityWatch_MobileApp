import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/widgets/issue_card.dart';
import 'package:urbanissuesclassifier/widgets/custom_bottom_nav.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';
import 'package:urbanissuesclassifier/routes/app_routes.dart';

class IssuesHistoryScreen extends StatefulWidget {
  const IssuesHistoryScreen({super.key});

  @override
  State<IssuesHistoryScreen> createState() => _IssuesHistoryScreenState();
}

class _IssuesHistoryScreenState extends State<IssuesHistoryScreen> {
  final int _currentNavIndex = 1;
  ComplaintStatus? _selectedFilter;
  final ApiService _apiService = ApiService();

  List<ComplaintModel> _allComplaints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getUserComplaints();

      if (mounted) {
        if (result['success']) {
          final List<ComplaintModel> fetchedComplaints =
              List<ComplaintModel>.from(result['complaints']);

          // Sort by date descending
          fetchedComplaints.sort(
            (a, b) => b.reportedDate.compareTo(a.reportedDate),
          );

          setState(() {
            _allComplaints = fetchedComplaints;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to load complaints';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading complaints: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<ComplaintModel> get filteredIssues {
    if (_selectedFilter == null) {
      return _allComplaints;
    }
    return _allComplaints.where((c) => c.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CurvedBackgroundScaffold(
      title: 'My Reports',
      topContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track status of your submissions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', null),
                const SizedBox(width: 8),
                _buildFilterChip('Pending', ComplaintStatus.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', ComplaintStatus.resolved),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Issues List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryTeal,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading your reports...',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchComplaints,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : filteredIssues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == null
                              ? 'No reports yet'
                              : 'No ${_selectedFilter!.displayName.toLowerCase()} reports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by reporting an issue',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchComplaints,
                    color: AppTheme.primaryTeal,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filteredIssues.length,
                      itemBuilder: (context, index) {
                        return IssueCard(
                          issue: filteredIssues[index],
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.issueDetail,
                              arguments: filteredIssues[index],
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            // Stay here
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.adminLogin);
          }
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ComplaintStatus? status) {
    final isSelected = _selectedFilter == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
