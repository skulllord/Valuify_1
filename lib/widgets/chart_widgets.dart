import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/colors.dart';

class TrendLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;

  const TrendLineChart({
    super.key,
    required this.data,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30, // to prevent cutting off bottom words
                getTitlesWidget: (value, meta) {
                  if (value % 1 == 0 && value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[value.toInt()],
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value);
              }).toList(),
              isCurved: true,
              gradient: AppColors.primaryGradient,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.3),
                    AppColors.primaryLight.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, Color> colors;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            final total = data.values.fold(0.0, (sum, val) => sum + val);
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            
            return PieChartSectionData(
              color: colors[entry.key] ?? Colors.grey,
              value: entry.value,
              title: '$percentage%',
              radius: 80,
              titleStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
