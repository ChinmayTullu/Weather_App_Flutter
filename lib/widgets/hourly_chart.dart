import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';

class HourlyChart extends StatelessWidget {
  final List<HourlyWeather> hourlyData;

  const HourlyChart({super.key, required this.hourlyData});

  @override
  Widget build(BuildContext context) {
    // Calculate temperature range for better Y-axis spacing
    final temperatures = hourlyData.map((e) => e.temperature).toList();
    final minTemp = temperatures.isNotEmpty
        ? temperatures.reduce((a, b) => a < b ? a : b)
        : 0.0;
    final maxTemp = temperatures.isNotEmpty
        ? temperatures.reduce((a, b) => a > b ? a : b)
        : 30.0;

    final tempRange = maxTemp - minTemp;
    final padding = tempRange * 0.2; // 20% padding
    final adjustedMin = minTemp - padding;
    final adjustedMax = maxTemp + padding;

    // Calculate interval for Y-axis labels (ensure minimum 3-degree spacing)
    final interval = ((adjustedMax - adjustedMin) / 4).ceilToDouble();
    final finalInterval = interval < 3 ? 3.0 : interval;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.show_chart,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hourly Temperature Trend',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hourlyData.isNotEmpty ? hourlyData.first.temperature.round() : 0}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: finalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: finalInterval,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '${value.toInt()}°',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < hourlyData.length) {
                          final hour = hourlyData[value.toInt()].time;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('HH:mm').format(hour),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: hourlyData.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.temperature);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF00D4FF), // Bright cyan color
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFF00D4FF),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF00D4FF).withOpacity(0.3),
                          const Color(0xFF00D4FF).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    shadow: const Shadow(
                      color: Color(0xFF00D4FF),
                      blurRadius: 8,
                    ),
                  ),
                ],
                minY: adjustedMin,
                maxY: adjustedMax,
              ),
            ),
          ),
        ],
      ),
    );
  }
}