import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/widgets/issue_card.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';

import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/routes/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  ComplaintStatus? _statusFilter; // null = All
  bool _isLoading = true;

  List<ComplaintModel> _allIssues = [];
  Map<String, dynamic> _stats = {
    'total': 0,
    'pending': 0,
    'inProgress': 0,
    'resolved': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final complaintsResult = await _apiService.getAllComplaints();
      if (complaintsResult['success']) {
        _allIssues = List<ComplaintModel>.from(complaintsResult['complaints']);
        // Sort by date descending (newest first)
        _allIssues.sort((a, b) => b.reportedDate.compareTo(a.reportedDate));
      }

      // Calculate stats locally for 100% accuracy
      int pending = 0;
      int resolved = 0;

      for (var issue in _allIssues) {
        if (issue.status == ComplaintStatus.resolved) {
          resolved++;
        } else {
          pending++;
        }
      }

      _stats = {
        'total': _allIssues.length,
        'pending': pending,
        'resolved': resolved,
      };
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final lowerQuery = _searchQuery.toLowerCase();
    final filteredIssues = _allIssues.where((issue) {
      return issue.title.toLowerCase().contains(lowerQuery) ||
          issue.type.displayName.toLowerCase().contains(lowerQuery);
    }).toList();

    final displayedIssues = _statusFilter == null
        ? filteredIssues.toList()
        : filteredIssues
              .where((issue) => issue.status == _statusFilter)
              .toList();

    return CurvedBackgroundScaffold(
      topHeightFactor: 0.55,
      topContent: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      _apiService.clearAuth();
                      Navigator.pushReplacementNamed(context, AppRoutes.auth);
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row (show Total, Pending, In Progress, Resolved)
              Row(
                children: [
                  _buildStatItem(
                    'Total',
                    _stats['total'].toString(),
                    Icons.analytics_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Pending',
                    _stats['pending'].toString(),
                    Icons.hourglass_empty_rounded,
                  ),
                  const SizedBox(width: 12),
                  _buildStatItem(
                    'Resolved',
                    _stats['resolved'].toString(),
                    Icons.check_circle_outline_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar with curved bottom like image
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                          )
                        : null,
                    hintText: 'Search complaints...',
                    hintStyle: const TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Complaints',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '${displayedIssues.length} found',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Filter chips: All, Pending, In Progress, Resolved
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _statusFilter == null,
                      onSelected: (sel) {
                        setState(() => _statusFilter = null);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Pending'),
                      selected: _statusFilter == ComplaintStatus.pending,
                      onSelected: (sel) {
                        setState(() => _statusFilter = ComplaintStatus.pending);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Resolved'),
                      selected: _statusFilter == ComplaintStatus.resolved,
                      onSelected: (sel) {
                        setState(
                          () => _statusFilter = ComplaintStatus.resolved,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (displayedIssues.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No complaints found matching your search',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: displayedIssues.length,
                  itemBuilder: (context, index) {
                    return IssueCard(
                      issue: displayedIssues[index],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.adminIssueDetail,
                          arguments: displayedIssues[index],
                        ).then((_) => _loadData());
                      },
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
