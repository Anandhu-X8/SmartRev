import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dummy Analytics Data
    final totalTopics = 120;
    final strongTopics = 65;
    final moderateTopics = 35;
    final weakTopics = 20;

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(totalTopics, strongTopics, moderateTopics, weakTopics, theme),
            const SizedBox(height: 40),
            Text('Memory Strength Distribution', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildPieChart(strongTopics, moderateTopics, weakTopics, theme),
            const SizedBox(height: 40),
            Text('Weekly Revision Activity', style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildLineChart(theme), // Using LineChart with gradient fill for premium look
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
        const SizedBox(width: 8),
        _buildStatCard('Strong\nMemory', s.toString(), const Color(0xFF10B981), const Color(0xFF10B981).withOpacity(0.1), theme),
        const SizedBox(width: 8),
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
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF10B981), // Strong
                        value: strong.toDouble(),
                        title: '${((strong / (strong + mod + weak)) * 100).toInt()}%',
                        radius: 40,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFF59E0B), // Moderate
                        value: mod.toDouble(),
                        title: '${((mod / (strong + mod + weak)) * 100).toInt()}%',
                        radius: 35,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      PieChartSectionData(
                        color: const Color(0xFFEF4444), // Weak
                        value: weak.toDouble(),
                        title: '${((weak / (strong + mod + weak)) * 100).toInt()}%',
                        radius: 30,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ],
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

  Widget _buildLineChart(ThemeData theme) {
    return Card(
      elevation: 4,
      shadowColor: theme.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, right: 32.0, left: 16.0, bottom: 16.0),
        child: SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(days[value.toInt()], style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString(), style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12));
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: 20,
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 5),
                    FlSpot(1, 15),
                    FlSpot(2, 8),
                    FlSpot(3, 12),
                    FlSpot(4, 9),
                    FlSpot(5, 18),
                    FlSpot(6, 14),
                  ],
                  isCurved: true,
                  color: theme.primaryColor,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: theme.primaryColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withOpacity(0.3),
                        theme.primaryColor.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
