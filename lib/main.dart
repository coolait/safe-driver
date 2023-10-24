import 'dart:async';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:getwidget/getwidget.dart';
import 'package:simple_rich_text/simple_rich_text.dart';

import 'OSMSpeedLimit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Drive Safe'),
        ),
        body: Column(
            //mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: DigitalClock(),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SpeedometerApp(),
              ),

            ],
          ),
      )

    );
  }
}

class SpeedometerApp extends StatefulWidget {
  @override
  _SpeedometerAppState createState() => _SpeedometerAppState();

}


class DigitalClock extends StatefulWidget {
  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _SpeedometerAppState extends State<SpeedometerApp> {
  double speed = 0.0;
  double latit = 0.0;
  double longi = 0.0;
  int speedLimit = 0;
  String roadName = 'N/A';
  Color buttonColor = Colors.blue; // Initial color
  bool isPressedSound = false;
  bool isPressedVo = false;
  bool isPressedFo = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
   // onPressed();
  }

  FlutterTts flutterTts = FlutterTts();

  Future<void> speakText(String text) async {
    await flutterTts.setLanguage("en-US"); // Set the language
    await flutterTts.setPitch(1.0); // Set the pitch (1.0 is the default)
    await flutterTts.setSpeechRate(
        0.5); // Set the speech rate (0.5 is slower, 1.0 is the default)

    await flutterTts.speak(text);
  }

/*  void onPressed() {

    setState(() {
      isPressed = !isPressed;
      buttonColor = isPressed ? Colors.red : Colors.blue;
      print("button color {$buttonColor}");
    });
  }*/

  Future<void> _initLocationService() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    //final Geolocator geolocator = Geolocator();
    const LocationSettings locationOptions =
        LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0);

    Geolocator.getPositionStream(locationSettings: locationOptions)
        .listen((Position position) {

      setState(() {
        // Update the speed whenever a new location is received
        speed = position.speed;
        speed = speed * 2.23694; //converting to mph
        latit = position.latitude;
        longi = position.longitude;
        //print ('location is: ');
        //print(position);
      });
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      var position = await Geolocator.getCurrentPosition();
      //setPosition(position);
      OverpassRepository myOSM = OverpassRepository();
      speedLimit = (await myOSM.getCarSpeedAt(position))!;
      roadName = (await myOSM.getRoadName())!;
      //speed = 30.0;
      //print("Speed $speed");
      //print("SpeedLmt $speedLimit");
      //speedLimit = 0;
      if (speedLimit == null) {
        print("Did not get Speed-lmit");
      } else if (speed > speedLimit!) {
        //print("voiced");
        speakText("You are Over Speed Limit");
        //print("Speed-limit $speedLimit");
      }
    });


  } // end init location service

  @override
  Widget build(BuildContext context) {
  //  return Scaffold(
     // appBar: AppBar(
     //   title: const Text('Safe Drive'),
      // ),
     // body: Center(
     //   child: Column(
       return Container(
           //color: Colors.yellowAccent,
           height: 400,
           //width: 200,
           // Expanded
           child: Column(
          children: <Widget>[
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,

                children:<Widget>[
                Text(
                  ' ${(speed).toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 120),
                  ),
                  const Text(
                    ' mph',
                    style: TextStyle(fontSize: 30),

                  ),
            ]),

            const Text(
              '',
              style: TextStyle(fontSize: 30),

            ),
             SimpleRichText(
              'Speed Limit *{color:red}${speedLimit}* mph',
              style: TextStyle(fontSize: 30,
              color: Colors.black),

            ),
            Text('Road: ${roadName}',
              style: TextStyle(fontSize: 30),),
            Text(
              'Location  ${longi.toStringAsFixed(2)},${latit.toStringAsFixed(2)}  ',
              style: TextStyle(fontSize: 30),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons evenly within the row
              children: <Widget>[
                SizedBox(width: 8.0),
                Expanded(
                  child:ElevatedButton(
                    child: Icon(
                      Icons.volume_up,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isPressedSound ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isPressedSound ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        isPressedSound = !isPressedSound;
                      });
                    },




                  ),
/*                  child:GFIconButton(
                    onPressed: onPressed,
                    //text:"primary",
                    icon: Icon(Icons.volume_up),
                    type: GFButtonType.solid,
                    iconSize: 50,
                    color: buttonColor,
                    shape: GFIconButtonShape.pills,
                    padding: const EdgeInsets.all(5),

                  ),*/
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child:ElevatedButton(
                    child: Icon(
                      Icons.record_voice_over_sharp,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isPressedVo ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isPressedVo ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        isPressedVo = !isPressedVo;
                      });
                    },




                  ),
/*                  child:GFIconButton(
                    onPressed: () {// Add your action here
                      setState(() {
                        isPressed = !isPressed;
                      });
                    },
                    //text:"primary",
                    icon: Icon(Icons.record_voice_over_sharp),
                    type: GFButtonType.solid,
                    iconSize: 50,
                    color: isPressed ? Colors.black : Colors.blue,
                    shape: GFIconButtonShape.pills,
                    padding: const EdgeInsets.all(5),

                  ),*/
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child:ElevatedButton(
                    child: Icon(
                      Icons.flash_on,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: isPressedFo ? Colors.black : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      side:  BorderSide(
                        width: 5,
                        style: BorderStyle.solid,
                        color: isPressedFo ? Colors.black : Colors.blueAccent,),
                      )
                      ),
                    onPressed: () {// Add your action here
                      setState(() {
                        isPressedFo = !isPressedFo;
                      });
                    },




                  ),
                ),
                SizedBox(width: 8.0),
              ],
            ),
          ],
           )

       );
  } // end build
} // end speedometer app

class _DigitalClockState extends State<DigitalClock> {
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    final formattedTime = DateFormat('MMM dd yyyy,hh:mm:ss aaa').format(now); // Customize the time format as needed.
    setState(() {
      _currentTime = formattedTime;
    });
    Future.delayed(Duration(seconds: 1), _updateTime); // Update the time every second.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        //color: Colors.redAccent,
      child: Column(
        children: <Widget>[
       Text(
      _currentTime,
      style: TextStyle(fontSize: 24),
      ),

    ])
    );
  }
}