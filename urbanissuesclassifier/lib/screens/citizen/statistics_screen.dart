import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/widgets/curved_background_scaffold.dart';

import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  int _pendingCount = 0;
  int _resolvedCount = 0;
  Map<ComplaintType, int> _typeCounts = {
    ComplaintType.pothole: 0,
    ComplaintType.garbage: 0,
    ComplaintType.paintedHump: 0,
    ComplaintType.unpaintedHump: 0,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getUserComplaints();
    if (result['success']) {
      final complaints = result['complaints'] as List<ComplaintModel>;
      _processStats(complaints);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processStats(List<ComplaintModel> complaints) {
    int pending = 0;
    int resolved = 0;
    Map<ComplaintType, int> typeCounts = {
      ComplaintType.pothole: 0,
      ComplaintType.garbage: 0,
      ComplaintType.paintedHump: 0,
      ComplaintType.unpaintedHump: 0,
    };

    for (var c in complaints) {
      // Status counts
      if (c.status == ComplaintStatus.resolved) {
        resolved++;
      } else {
        pending++;
      }

      // Type counts
      if (typeCounts.containsKey(c.type)) {
        typeCounts[c.type] = (typeCounts[c.type] ?? 0) + 1;
      } else {
        // Fallback for others or potential issues
        typeCounts[c.type] = 1;
      }
    }

    if (mounted) {
      setState(() {
        _pendingCount = pending;
        _resolvedCount = resolved;
        _typeCounts = typeCounts;
        _isLoading = false;
      });
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

    final int total = _pendingCount + _resolvedCount;

    final int potholeCount = _typeCounts[ComplaintType.pothole] ?? 0;
    final int garbageCount = _typeCounts[ComplaintType.garbage] ?? 0;
    final int paintedCount = _typeCounts[ComplaintType.paintedHump] ?? 0;
    final int unpaintedCount = _typeCounts[ComplaintType.unpaintedHump] ?? 0;

    // Determine maxY for bar chart
    final List<int> counts = [
      potholeCount,
      garbageCount,
      paintedCount,
      unpaintedCount,
    ];
    // Find max value, defaulting to 5 if all are low, adding buffer
    double maxY = (counts.reduce((a, b) => a > b ? a : b).toDouble());
    if (maxY < 5) maxY = 5;
    maxY += 2;

    return CurvedBackgroundScaffold(
      title: 'My Analytics',
      topContent: Text(
        'Insights from your reported issues',
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // KPI Statistics Card (Pie Chart)
              _buildCard(
                title: 'Issue Status Distribution',
                child: total == 0
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('No reports found'),
                        ),
                      )
                    : Row(
                        children: [
                          SizedBox(
                            height: 150,
                            width: 150,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: 40,
                                sections: [
                                  if (_resolvedCount > 0)
                                    PieChartSectionData(
                                      color: AppTheme.statusResolved,
                                      value: _resolvedCount.toDouble(),
                                      title:
                                          '${(_resolvedCount / total * 100).toInt()}%',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (_pendingCount > 0)
                                    PieChartSectionData(
                                      color: AppTheme.statusPending,
                                      value: _pendingCount.toDouble(),
                                      title:
                                          '${(_pendingCount / total * 100).toInt()}%',
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(
                                  AppTheme.statusPending,
                                  'Pending',
                                  _pendingCount,
                                ),
                                const SizedBox(height: 12),
                                _buildLegendItem(
                                  AppTheme.statusResolved,
                                  'Resolved',
                                  _resolvedCount,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // Issue Categories (Bar Chart)
              _buildCard(
                title: 'Reports by Category',
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    String label;
                                    switch (group.x) {
                                      case 0:
                                        label = 'Pothole';
                                        break;
                                      case 1:
                                        label = 'Garbage';
                                        break;
                                      case 2:
                                        label = 'Painted';
                                        break;
                                      case 3:
                                        label = 'Unpainted';
                                        break;
                                      default:
                                        label = '';
                                    }
                                    return BarTooltipItem(
                                      '$label\n',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: (rod.toY - 1)
                                              .toInt()
                                              .toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                      const style = TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      );
                                      String text;
                                      switch (value.toInt()) {
                                        case 0:
                                          text = 'Pothole';
                                          break;
                                        case 1:
                                          text = 'Garbage';
                                          break;
                                        case 2:
                                          text = 'Painted';
                                          break;
                                        case 3:
                                          text = 'Unpaint';
                                          break;
                                        default:
                                          text = '';
                                      }
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        space: 4,
                                        child: Text(text, style: style),
                                      );
                                    },
                                reservedSize: 30,
                              ),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: potholeCount.toDouble(),
                                  color: AppTheme.warningOrange,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                  toY: garbageCount.toDouble(),
                                  color: AppTheme.alertRed,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                  toY: paintedCount.toDouble(),
                                  color: AppTheme.primaryTeal,
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                            BarChartGroupData(
                              x: 3,
                              barRods: [
                                BarChartRodData(
                                  toY: unpaintedCount.toDouble(),
                                  color: Colors.purple, // Distinct color
                                  width: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // User Performance Card
              _buildCard(
                title: 'Your Impact',
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryTeal,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Community Contribution',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                          Text(
                            'You have submitted $total reports to help improve the city.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}
