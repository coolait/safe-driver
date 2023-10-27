import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

OverpassRepository? _instance;

class OverpassRepository {
  OverpassRepository._internal();
  String _roadName = 'N/A';
  factory OverpassRepository() {
    _instance ??= OverpassRepository._internal();
    return _instance!;
  }
  Future<String> getRoadName() async {
    return _roadName;
  }
  Future<int?> getCarSpeedAt(Position position) async {
    var body = """
[out:json][timeout:25];
(
  way(around:10,${position.latitude},${position.longitude}) ["maxspeed"];
);
out body;
>;
out skel qt;
    
    """;

    var result = await http
        .post(Uri.parse('https://overpass-api.de/api/interpreter'), body: body);
    if (result.statusCode == 200) {
      var data = jsonDecode(result.body);
      for (Map<String, dynamic> way in data['elements']) {
        if (way['tags']?['name'] != null) {
          _roadName = (way['tags']['name']);
        }
        if (way['tags']?['maxspeed'] != null) {
          //return int.parse(way['tags']['maxspeed']);
          String speedText = (way['tags']['maxspeed']);
          String numericSpeed = speedText.replaceAll(RegExp(r'[^0-9]'), '');
          if (numericSpeed.isNotEmpty) {
            int? speed = int.tryParse(numericSpeed);
            return speed;
          }
        }
      }
    }

    return null;
  }
}
