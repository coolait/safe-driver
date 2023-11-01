import 'package:flutter/material.dart';
import 'ViolationChart.dart'; // Import your ViolationsChart widget

class FullChartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Violation Chart'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to the previous screen
          },
        ),
      ),
      body: ViolationsChart(), // Display your chart widget here
    );
  }
}
