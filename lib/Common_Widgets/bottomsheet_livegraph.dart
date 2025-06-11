import 'dart:async';
import 'dart:math';

import 'package:asset_inspections/Pokit_Multimeter/Providers/multimeterservice.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BottomSheetLiveGraph extends StatefulWidget {
  final double minY; // Minimum value for the y-axis
  const BottomSheetLiveGraph({
    super.key,
    this.minY = -0.5,
  });

  @override
  createState() => _BottomSheetLiveGraphState();
}

class _BottomSheetLiveGraphState extends State<BottomSheetLiveGraph> {
  List<FlSpot> dataPoints = []; // List of data points to show on the graph
  int maxDataPoints = 50; // Maximum number of data points to show
  double alpha = 1; // Smoothing factor. Between 0 and 1.
  double lastSmoothValue = 0; // Initial value for smoothing
  StreamSubscription<double>? readingSubscription;
  double minY = -0.5; // Default values
  double maxY = 0.5; // Default values
  double titleInterval = 0.1; // Default value

  int scaleX = 80; // This can be any integer from 1 to 100
  double scaleXAxis = 0.8;

  @override
  void initState() {
    super.initState();
    // Set the minimum and maximum values for the y-axis
    minY = widget.minY;
    scaleXAxis = scaleToDecimal(scaleX);
    bottomSheetGraphSubscribeToReadingStream();
  }

  double scaleToDecimal(int scaleX) {
    return scaleX / 100;
  }

  /// Subscribes to the reading stream of the [MultimeterService] and updates the graph with the received readings.
  /// Applies smoothing to the readings using the alpha value.
  /// Removes the oldest data point if the maximum number of data points is reached.
  /// Ensures that the x values are continuous and scaled. The default scale is 80% of the graph, which can be changed by the [scaleX] parameter.
  void bottomSheetGraphSubscribeToReadingStream() {
    final multimeterService = Provider.of<MultimeterService>(context, listen: false);
    readingSubscription = multimeterService.currentReadingStream.listen((currentReading) {
      // Apply smoothing
      double smoothValue = alpha * currentReading + (1 - alpha) * lastSmoothValue;
      lastSmoothValue = smoothValue;
      setState(() {
        if (dataPoints.length >= maxDataPoints) {
          // Remove the oldest data point
          // dataPoints.removeAt(0);
          dataPoints.clear();
        }
        // Add the new data point
        double newXValue = dataPoints.isNotEmpty ? dataPoints.last.x + (1 * maxDataPoints / (maxDataPoints - 1)) : 0;
        //dataPoints.add(FlSpot(newXValue, currentReading));
        // Use smoothValue instead of currentReading for the y-value
        dataPoints.add(FlSpot(newXValue, smoothValue));

        // Ensure that the x values are continuous and scaled to occupy 80% of the graph
        if (dataPoints.length == maxDataPoints) {
          dataPoints = dataPoints.asMap().entries.map((entry) {
            int idx = entry.key;
            FlSpot spot = entry.value;
            return FlSpot(idx * (scaleXAxis * maxDataPoints / (maxDataPoints - 1)), spot.y);
          }).toList();
        }
      });
    });
  }

  @override
  void dispose() {
    readingSubscription?.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  /// Calculates a nice number based on the given value and rounding preference.
  ///
  /// The nice number is calculated by determining the exponent of the value and
  /// finding a fraction that is considered "nice" based on the rounding preference.
  /// The nice fraction is then multiplied by 10 raised to the power of the
  /// exponent floor to obtain the final result.
  ///
  /// If the original value is negative, the result will also be negative.
  ///
  /// Parameters:
  /// - [value]: The value for which to calculate the nice number.
  /// - [roundUp]: A boolean indicating whether to round up or down.
  ///
  /// Returns:
  /// The calculated nice number.
  double getNiceNumber(double value, bool roundUp) {
    if (value == 0) {
      return 0; // If the value is 0, return 0 immediately
    }

    double exponent = log(value.abs()) / log(10); // Calculate the exponent of the absolute value of the input
    double fraction = (pow(10, exponent % 1)).toDouble(); // Calculate the fractional part of the exponent
    double niceFraction;

    if (roundUp) {
      // If roundUp is true, round the fraction up to the nearest nice fraction
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
      // If roundUp is false, round the fraction down to the nearest nice fraction
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

    double result = (niceFraction * pow(10, (exponent.floor())))
        .toDouble(); // Calculate the final result by multiplying the nice fraction with 10 raised to the floor of the exponent

    return value < 0 ? -result : result; // If the original value was negative, return the negated result, otherwise return the result as is
  }

  /// Determines the appropriate interval for a given range of values.
  ///
  /// The interval is calculated based on the difference between the minimum and maximum values.
  /// If the range is less than or equal to 1, a smaller interval of 0.2 is used.
  /// If the range is between 1 and 5, an interval of 0.5 is used.
  /// If the range is between 5 and 10, an interval of 1 is used.
  /// For ranges greater than 10, the interval is calculated as the range divided by 5, rounded down to the nearest double value.
  /// The calculated interval is then returned, ensuring that it is not smaller than 0.1.
  ///
  /// Parameters:
  /// - [min]: The minimum value of the range.
  /// - [max]: The maximum value of the range.
  ///
  /// Returns:
  /// The appropriate interval for the given range of values.
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

  /// Builds a fixed line chart with a horizontal line at zero.
  ///
  /// This widget returns a [LineChart] widget with a fixed horizontal line at zero.
  /// The line chart is customized with transparent background, invisible vertical lines,
  /// and a visible horizontal line at zero. The chart does not have any borders or titles.
  /// The minimum and maximum values for the x-axis are determined by the [maxDataPoints]
  /// parameter, while the minimum and maximum values for the y-axis are determined by the
  /// [minY] and [maxY] parameters respectively.
  ///
  /// Returns:
  ///   A [LineChart] widget with a fixed horizontal line at zero.
  Widget buildFixedLineChartAtZero() {
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(spots: [const FlSpot(0, 0)], color: Colors.transparent)
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          show: true,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return const FlLine(
                color: Color.fromARGB(255, 0, 12, 249),
                strokeWidth: 1,
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
  }

  /// Builds a fixed line chart at 850.
  ///
  /// This method returns a [LineChart] widget that displays a line chart with a fixed line at the value -0.850.
  /// The chart has a transparent background and no border.
  /// The grid lines are shown, except for the vertical lines.
  /// The horizontal line at -0.850 is displayed in red color with a strokeWidth of 1.
  /// For other values, the horizontal lines are invisible.
  /// The chart does not display any titles.
  /// The x-axis ranges from 0 to the value of [maxDataPoints] converted to a double.
  /// The y-axis ranges from [minY] to [maxY].
  ///
  /// Returns:
  ///   A [LineChart] widget representing the fixed line chart at 850.
  Widget buildFixedLineChartAt850() {
    return LineChart(
      LineChartData(
        backgroundColor: Colors.transparent,
        lineBarsData: [
          LineChartBarData(spots: [const FlSpot(0, 0)], color: Colors.transparent)
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          show: true,
          getDrawingHorizontalLine: (value) {
            if (value == -0.850) {
              return const FlLine(
                color: Color.fromARGB(255, 249, 0, 0),
                strokeWidth: 1,
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
  }

  /// Builds the main line chart widget.
  ///
  /// This method returns a [LineChart] widget that displays a line chart with the provided data points.
  /// The chart is customizable with various properties such as background color, grid lines, titles, borders, and more.
  /// If the [dataPoints] list is not empty, the chart will be displayed. Otherwise, an empty [SizedBox] is returned.
  ///
  Widget buildMainLineChart() {
    return dataPoints.isNotEmpty
        ? LineChart(
            LineChartData(
              backgroundColor: Colors.black,
              gridData: FlGridData(
                show: true,
                horizontalInterval: titleInterval,
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
                          color: Colors.white,
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
                    //color: Colors.yellow.withOpacity(0.5),
                    color: const Color.fromARGB(128, 255, 255, 84),
                  ),
                  dotData: const FlDotData(show: false), // Hide the dots
                ),
              ],
            ),
          )
        : const SizedBox();
  }

  /// Builds a widget that displays a stack of line charts.
  ///
  /// The [buildMainLineChart] method is used to build the main line chart.
  /// The [buildFixedLineChartAtZero] method is used to build a fixed line chart at zero.
  /// The [buildFixedLineChartAt850] method is used to build a fixed line chart at 850.
  ///
  /// Returns a [Stack] widget that contains the line charts.
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildMainLineChart(),
        buildFixedLineChartAtZero(),
        buildFixedLineChartAt850(),
      ],
    );
  }
}
