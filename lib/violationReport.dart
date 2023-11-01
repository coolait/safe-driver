import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FullChartScreen.dart';
import 'ViolationChart.dart'; // Import the ViolationsChart widget

class ViolationReport extends StatefulWidget {
  @override
  _ViolationReportState createState() => _ViolationReportState();
}

class _ViolationReportState extends State<ViolationReport> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> violationData = [];

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Violation Report'),
      ),
      body: SingleChildScrollView( // Wrap the content with a SingleChildScrollView
      child:  Column(
        children: [
          DataTable(
            border: TableBorder.all(
              color: Colors.black,
              width: 1.0,
            ),
            columnSpacing: 40.0,
            horizontalMargin: 2, // Adjust the horizontal margin
            columns: [
              DataColumn(label: Text('DateTime')),
              DataColumn(label: Text('Road')),
              DataColumn(label: Text('Speed')),
              DataColumn(label: Text('Limit')),
            ],
            rows: violationData.map((data) {
              final dateTime = (data['Date'] as Timestamp).toDate();
              final formattedDateTime = dateTime != null
                  ? "${dateTime.toLocal()}" // Format the DateTime as needed
                  : '';
              final road = data['Road'] ?? '';

              // Function to limit "Road" text to 20 characters
              String limitRoadText(String text) {
                if (text.length > 20) {
                  return text.substring(0, 10) + '...'; // Truncate text if it's longer than 20 characters
                }
                return text;
              }

              // Customized DataCell with padding and alignment adjustments
              DataCell customDataCell(String text) {
                return DataCell(
                  Padding(
                    padding: EdgeInsets.all(1), // Adjust padding here as needed
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // Adjust alignment as needed
                      child: Text(text),
                    ),
                  ),
                );
              }

              return DataRow(cells: [
                DataCell(Text(formattedDateTime)),
                customDataCell(limitRoadText(road)), // Apply character limit to the "Road" cell
                DataCell(Text(data['Speed'].toString())),
                DataCell(Text(data['SpeedLimit'].toString())),
              ]);
            }).toList(),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FullChartScreen(), // Navigate to the FullChartScreen
                ),
              );
              // Open the ViolationsChart when the button is clicked
              /*
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Violations Chart'),
                    content: ViolationsChart(), // Include the ViolationsChart widget
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Close Chart'),
                      ),
                    ],
                  );
                },
              );
              */
            },
            child: Text('Show Violations Chart'),
          ),
        ],
      ),
      ),
      // Don't forget to close the 'body' property
      // and add any other widgets or properties you need here
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }

  Future<void> _fetchDataFromFirestore() async {
    QuerySnapshot querySnapshot = await _firestore.collection('ishaan.sid@gmail.com').get();
    List<QueryDocumentSnapshot> documents = querySnapshot.docs;

    List<Map<String, dynamic>> data = [];

    for (var doc in documents) {
      Map<String, dynamic> documentData = doc.data() as Map<String, dynamic>;
      data.add(documentData);
    }
    // Sort the data by 'Date' field in chronological order
    data.sort((a, b) => (b['Date'] as Timestamp).compareTo(a['Date'] as Timestamp));

    setState(() {
      violationData = data;
    });
  }
}


//end