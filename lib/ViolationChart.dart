import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class ViolationsChart extends StatefulWidget {
  @override
  _ViolationsChartState createState() => _ViolationsChartState();
}

class _ViolationsChartState extends State<ViolationsChart> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<charts.Series<OrdinalSales, String>> seriesList = [];

  @override
  void initState() {
    super.initState();
    retrieveViolationData();
  }

  void retrieveViolationData() async {
    QuerySnapshot querySnapshot = await _firestore.collection('ishaan.sid@gmail.com').get();
    List<QueryDocumentSnapshot> documents = querySnapshot.docs;

    Map<DateTime, int> violationsByDay = {};

    for (var doc in documents) {
      Timestamp timestamp = doc['Date'] as Timestamp;
      DateTime violationDate = timestamp.toDate();
      violationDate = DateTime(violationDate.year, violationDate.month, violationDate.day);

      if (violationsByDay.containsKey(violationDate)) {
        violationsByDay[violationDate] = (violationsByDay[violationDate] ?? 0) + 1;
      } else {
        violationsByDay[violationDate] = 1;
      }
    }

    List<OrdinalSales> data = [];

    violationsByDay.forEach((date, count) {
      data.add(OrdinalSales(date.day.toString(), count));
    });
    // Sort the data by date before creating the chart series
    data.sort((a, b) => a.day.compareTo(b.day));
    seriesList = [
      charts.Series<OrdinalSales, String>(
        id: 'Violations',
        domainFn: (OrdinalSales sales, _) => sales.day,
        measureFn: (OrdinalSales sales, _) => sales.count,
        data: data,
      ),
    ];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*
      appBar: AppBar(
        title: Text('Violations Chart'),
      ),*/
      body: seriesList == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(2.0),
        child: charts.BarChart(
          seriesList,
          animate: true,
        ),
      ),
    );
  }
}
class OrdinalSales {
  final String day;
  final int count;

  OrdinalSales(this.day, this.count);
}
