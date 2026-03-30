import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../config.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _totalTopics = 0;
  int _strongTopics = 0;
  int _moderateTopics = 0;
  int _weakTopics = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh analytics when route is revisited
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$apiBase/api/analytics/dashboard'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _totalTopics = data['total_topics'] ?? 0;
          _strongTopics = data['strong_topics'] ?? 0;
          _moderateTopics = data['moderate_topics'] ?? 0;
          _weakTopics = data['weak_topics'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Failed to fetch analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(_totalTopics, _strongTopics, _moderateTopics, _weakTopics, theme),
            const SizedBox(height: 40),
            Text('Memory Strength Distribution', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildPieChart(_strongTopics, _moderateTopics, _weakTopics, theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(int t, int s, int m, int w, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('Total\nTopics', t.toString(), theme.textTheme.bodyLarge!.color!, theme.primaryColor.withOpacity(0.1), theme),
        const SizedBox(width: 6),
        _buildStatCard('Strong\nMemory', s.toString(), const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.1), theme),
        const SizedBox(width: 6),
        _buildStatCard('Moderate', m.toString(), const Color(0xFFF59E0B), const Color(0xFFF59E0B).withOpacity(0.1), theme),
        const SizedBox(width: 6),
        _buildStatCard('Needs\nReview', w.toString(), const Color(0xFFEF4444), const Color(0xFFEF4444).withOpacity(0.1), theme),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor, Color bgColor, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(int strong, int mod, int weak, ThemeData theme) {
    final total = strong + mod + weak;
    if (total == 0) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    // Only show sections with value > 0 to avoid rendering issues
    final sections = <PieChartSectionData>[];
    if (strong > 0) {
      sections.add(PieChartSectionData(
        color: const Color(0xFF10B981),
        value: strong.toDouble(),
        title: '${((strong / total) * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
    }
    if (mod > 0) {
      sections.add(PieChartSectionData(
        color: const Color(0xFFF59E0B),
        value: mod.toDouble(),
        title: '${((mod / total) * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
    }
    if (weak > 0) {
      sections.add(PieChartSectionData(
        color: const Color(0xFFEF4444),
        value: weak.toDouble(),
        title: '${((weak / total) * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ));
    }

    return Card(
      elevation: 4,
      shadowColor: theme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 30,
                    startDegreeOffset: -90,
                    sections: sections,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Strong', const Color(0xFF10B981), theme),
                    const SizedBox(height: 12),
                    _buildLegendItem('Moderate', const Color(0xFFF59E0B), theme),
                    const SizedBox(height: 12),
                    _buildLegendItem('Weak', const Color(0xFFEF4444), theme),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
