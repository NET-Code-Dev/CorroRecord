import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';

class LiveGraph extends StatefulWidget {
  const LiveGraph({super.key});

  @override
  createState() => _LiveGraphState();
}

class _LiveGraphState extends State<LiveGraph> {
  List<FlSpot> dataPoints = [];
  final int maxDataPoints = 50;

  @override
  Widget build(BuildContext context) {
    // Fetch the multimeter service from the Provider context
    final multimeterService = Provider.of<MultimeterService>(context, listen: true);
    Reading currentReading = multimeterService.currentReading;

// Update dataPoints list
    if (dataPoints.length >= maxDataPoints) {
      dataPoints.clear(); // Clear the data points to start over
    }

    // Add the new data point
    dataPoints.add(FlSpot(dataPoints.length.toDouble(), currentReading.value));

    double getNiceNumber(double value, bool roundUp) {
      // print('getNiceNumber - value: $value, roundUp: $roundUp');

      if (value == 0) {
        return 0; // or handle in a way suitable for your case
      }

      double exponent = log(value.abs()) / log(10);
      double fraction = (pow(10, exponent % 1)).toDouble();
      double niceFraction;

      if (roundUp) {
        if (fraction <= 1) {
          niceFraction = 1;
        } else if (fraction <= 2) {
          niceFraction = 2;
        } else if (fraction <= 5) {
          niceFraction = 5;
        } else {
          niceFraction = 10;
        }
      } else {
        if (fraction >= 5) {
          niceFraction = 5;
        } else if (fraction >= 2) {
          niceFraction = 2;
        } else if (fraction >= 1) {
          niceFraction = 1;
        } else {
          niceFraction = 0.5;
        }
      }

      double result = (niceFraction * pow(10, (exponent.floor()))).toDouble();

      // print('getNiceNumber - result: $result');
      return value < 0 ? -result : result; // Return negative if original value was negative
    }

    double determineInterval(double min, double max) {
      double range = max - min;
      double interval;

      if (range <= 1) {
        interval = 0.2; // smaller interval for smaller range
      } else if (range <= 5) {
        interval = 0.5;
      } else if (range <= 10) {
        interval = 1;
      } else {
        interval = (range / 5).floorToDouble(); // adjust interval based on range
      }

      // Ensure interval is not too small
      return interval > 0 ? interval : 0.1;
    }

    double minY, maxY;

    if (dataPoints.isNotEmpty) {
      minY = getNiceNumber(dataPoints.map((e) => e.y).reduce(min) - 1, false);
      maxY = getNiceNumber(dataPoints.map((e) => e.y).reduce(max) + 1, true);

      if (minY.isNaN || minY.isInfinite || maxY.isNaN || maxY.isInfinite) {
        minY = -0.5; // default value, adjust as needed
        maxY = 0.5; // default value, adjust as needed
      }

      //  print('minY: $minY, maxY: $maxY');
    } else {
      minY = -0.5;
      maxY = 0.5;
    }
    double titleInterval = determineInterval(minY, maxY);

// Ensure titleInterval is not zero
    if (titleInterval == 0) {
      titleInterval = 0.1; // Or some suitable small value
    }

    // Create a LineChart for fixed lines at 0 and -0.850
    Widget fixedLineChart = LineChart(
      LineChartData(
        lineBarsData: [
          // No data points, just the fixed lines
          LineChartBarData(spots: [])
        ],
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            if (value == 0 || value == -0.850) {
              return const FlLine(
                color: Color(0xff37434d),
                strokeWidth: 1,
                // ... additional styling as needed
              );
            }
            return const FlLine(color: Colors.transparent); // Invisible for other values
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false), // Hide titles for the fixed line chart
        minX: 0,
        maxX: maxDataPoints.toDouble(),
        minY: minY,
        maxY: maxY,
      ),
    );

    // Create the main LineChart with actual data points
    Widget mainLineChart = LineChart(
      LineChartData(
        backgroundColor: Colors.black,
        gridData: FlGridData(
          show: true,
          horizontalInterval: titleInterval,
          getDrawingHorizontalLine: (value) {
            // Always draw a red line for 0 and -0.850 if they are within the visible range
            if ((value == 0 || value == -0.850) && value >= minY && value <= maxY) {
              return const FlLine(
                color: Colors.red,
                strokeWidth: 1,
              );
            }
            return const FlLine(
              color: Colors.white,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: titleInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  (value).toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: maxDataPoints.toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: false,
            color: Colors.yellow,
            barWidth: 1,
            isStrokeCapRound: false,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.yellow.withOpacity(0.5),
            ),
            dotData: const FlDotData(show: false), // Hide the dots
          ),
        ],
      ),
    );

    return Stack(
      children: [
        fixedLineChart, // Placed first, so it's behind the main chart
        mainLineChart, // Placed second, so it overlays the fixed line chart
      ],
    );
  }
}


/*  @override
  Widget build(BuildContext context) {
    // Fetch the multimeter service from the Provider context
    final multimeterService =
        Provider.of<MultimeterService>(context, listen: true);
    Reading? currentReading = multimeterService.currentReading;

// Update dataPoints list
    if (currentReading != null) {
      if (dataPoints.length >= maxDataPoints) {
        dataPoints.clear(); // Clear the data points to start over
      }

      // Add the new data point
      dataPoints
          .add(FlSpot(dataPoints.length.toDouble(), currentReading.value));
    }

    double getNiceNumber(double value, bool roundUp) {
      // print('getNiceNumber - value: $value, roundUp: $roundUp');

      if (value == 0) {
        return 0; // or handle in a way suitable for your case
      }

      double exponent = log(value.abs()) / log(10);
      double fraction = (pow(10, exponent % 1)).toDouble();
      double niceFraction;

      if (roundUp) {
        if (fraction <= 1) {
          niceFraction = 1;
        } else if (fraction <= 2) {
          niceFraction = 2;
        } else if (fraction <= 5) {
          niceFraction = 5;
        } else {
          niceFraction = 10;
        }
      } else {
        if (fraction >= 5) {
          niceFraction = 5;
        } else if (fraction >= 2) {
          niceFraction = 2;
        } else if (fraction >= 1) {
          niceFraction = 1;
        } else {
          niceFraction = 0.5;
        }
      }

      double result = (niceFraction * pow(10, (exponent.floor()))).toDouble();

      // print('getNiceNumber - result: $result');
      return value < 0
          ? -result
          : result; // Return negative if original value was negative
    }

    double determineInterval(double min, double max) {
      double range = max - min;
      double interval;

      if (range <= 1) {
        interval = 0.2; // smaller interval for smaller range
      } else if (range <= 5) {
        interval = 0.5;
      } else if (range <= 10) {
        interval = 1;
      } else {
        interval =
            (range / 5).floorToDouble(); // adjust interval based on range
      }

      // Ensure interval is not too small
      return interval > 0 ? interval : 0.1;
    }

    double minY, maxY;

    if (dataPoints.isNotEmpty) {
      minY = getNiceNumber(dataPoints.map((e) => e.y).reduce(min) - 1, false);
      maxY = getNiceNumber(dataPoints.map((e) => e.y).reduce(max) + 1, true);

      if (minY.isNaN || minY.isInfinite || maxY.isNaN || maxY.isInfinite) {
        minY = -0.5; // default value, adjust as needed
        maxY = 0.5; // default value, adjust as needed
      }

      //  print('minY: $minY, maxY: $maxY');
    } else {
      minY = -0.5;
      maxY = 0.5;
    }
    double titleInterval = determineInterval(minY, maxY);

// Ensure titleInterval is not zero
    if (titleInterval == 0) {
      titleInterval = 0.1; // Or some suitable small value
    }

    return LineChart(
      LineChartData(
        backgroundColor: Colors.black,
        gridData: FlGridData(
          show: true,
          horizontalInterval: titleInterval,
          getDrawingHorizontalLine: (value) {
            // Always draw a red line for 0 and -0.850 if they are within the visible range
            if ((value == 0 || value == -0.850) &&
                value >= minY &&
                value <= maxY) {
              return FlLine(
                color: Colors.red,
                strokeWidth: 1,
              );
            }
            return FlLine(
              color: Colors.white,
              strokeWidth: 0.5,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: titleInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  (value).toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        minX: 0,
        maxX: maxDataPoints.toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: false,
            color: Colors.yellow,
            barWidth: 1,
            isStrokeCapRound: false,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.yellow.withOpacity(0.5),
            ),
            dotData: FlDotData(show: false), // Hide the dots
          ),
        ],
      ),
    );
  }
  */