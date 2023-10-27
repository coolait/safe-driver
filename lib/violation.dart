import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
/*

class Violation {
  // 1
  String vaccination;
  DateTime date;
  bool done;
  // 2
  DocumentReference reference;
  // 3
  Violation(this.vaccination, {this.date, this.done, this.reference});
  // 4
  factory Violation.fromJson(Map<dynamic, dynamic> json) => _VaccinationFromJson(json);
  // 5
  Map<String, dynamic> toJson() => _VaccinationToJson(this);
  @override
  String toString() => "Violation<$vaccination>";
 }

*/