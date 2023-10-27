import 'dart:async';
import 'dart:math';


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:getwidget/getwidget.dart';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
//import 'package:audioplayers/audio_cache.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  int adjSpeedLimit = 0;
  String roadName = 'N/A';
  Color buttonColor = Colors.blue; // Initial color
  //bool isPressedSound = false;
  //bool isPressedVo = false;
  //bool isPressedFo = false;
  //bool isPressedB5 = false;
  //bool isPressedA5 = false;
  //bool isPressedA10 = false;
  bool isPressedInfi = false;
  bool isPressedDoc = false;
  bool isPressedStng = false;
  int warnLevel=0;
  int speedLmtlevel = 0;
  List<bool> isSelected = [false,false,false]; // Represents the selected state of each button
  List<bool> isSelected2 = [false,false,false];
  final player  = AudioPlayer();
/////FIREBASE- FIRESTORE
  /*
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> readCollection() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('RAKI').get();
      List<QueryDocumentSnapshot> documents = querySnapshot.docs;

      for (var doc in documents) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic> ;
        print('Document ID: ${doc.id}, Data: $data');
      }
    } catch (error) {
      print('Error: $error');
    }
  }
*/
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

  void playSound(String Alarm) async {

    await player.setVolume(0.5);
    print('got the alamrm {$Alarm}');
    //int result = await player.play('assets/sound.mp3'); // Replace with your sound file path
    await player.play(AssetSource(Alarm));
    await Future.delayed(Duration(seconds:3));
    player.stop();

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
      print("Speed $speed");
      print("SpeedLmt $speedLimit");
      adjSpeedLimit = speedLimit;
      if (isSelected[0]) {
        adjSpeedLimit = speedLimit - 5;
      } else if (isSelected[1]) {
        adjSpeedLimit = speedLimit + 5;
      } else if (isSelected[2]) {
        adjSpeedLimit = speedLimit + 10;
      } else if (isPressedInfi) {
        adjSpeedLimit = speedLimit + 10000;
      }

      if (adjSpeedLimit == null) {
        print("Did not get Speed-lmit");
      } else if (speed > adjSpeedLimit!) {
        //print("voiced");
        //Alert based on the setting user has picked
      if (isSelected2[0]) {
        //Sound only
        playSound('sounds/streetalarm.wav');
      } else if (isSelected2[1]) {
        speakText("You are Over Speed Limit");
        //print("Speed-limit $speedLimit");
      }else if (isSelected2[2]) {
        speakText("You are in Flash");
        //print("Speed-limit $speedLimit");
      }
      }
    });

  } // end init location service

  void selectButton(int index) {
    for (int i = 0; i < isSelected.length; i++) {
      isSelected[i] = (i == index); // Select the button at the specified index and deselect others
    }
    isPressedInfi = false;
  }
  void selectButton2(int index) {
    for (int i = 0; i < isSelected2.length; i++) {
      isSelected2[i] = (i == index); // Select the button at the specified index and deselect others
    }
  }
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
           //height: 600,
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
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons evenly within the row
              children: <Widget>[
                ToggleButtons(
                  isSelected: isSelected2,
                children: [
                //SizedBox(width: 10.0),
                  Container(
                    margin: EdgeInsets.only(right: 20.0),
                    child:  SizedBox(
                  height: 80,
                  width: 100,
                    child:ElevatedButton(
                    child: Icon(
                      Icons.volume_up,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isSelected2[0] ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isSelected2[0] ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        //isPressedSound = !isPressedSound;
                        selectButton2(0);
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
                  ),
                //SizedBox(width: 8.0),
                  Container(
                    margin: EdgeInsets.only(right: 20.0),
                    child:  SizedBox(
                  height: 80,
                  width: 100,
                    child:ElevatedButton(
                      child: Icon(
                      Icons.record_voice_over_sharp,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isSelected2[1] ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isSelected2[1] ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        //isPressedVo = !isPressedVo;
                        selectButton2(1);
                      });
                    },

                  ),

                ),
                  ),
                //SizedBox(width: 8.0),
                  Container(
                    margin: EdgeInsets.only(right: 0),
                    child:  SizedBox(
                  height: 80,
                  width: 100,
                    child:ElevatedButton(
                    child: Icon(
                      Icons.flash_on,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: isSelected2[2] ? Colors.black : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      side:  BorderSide(
                        width: 5,
                        style: BorderStyle.solid,
                        color: isSelected2[2] ? Colors.black : Colors.blueAccent,),
                      )
                      ),
                    onPressed: () {// Add your action here
                      setState(() {
                        //isPressedFo = !isPressedFo;
                        selectButton2(2);
                      });
                    },

                  ),
                    )
                ),
                  ],
                )
                //SizedBox(width: 8.0),
              ],
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons evenly within the row
              children: <Widget>[
                ToggleButtons(
                  isSelected: isSelected,
                  children:[
                    //SizedBox(width: 10.0),
                    Container(
                      margin: EdgeInsets.only(right: 20.0),
                      child: SizedBox(
                        height: 80,
                        width: 100,
                        child:ElevatedButton(
                          child: Text('-5',
                            style: TextStyle(fontSize: 50),),
                          style: ElevatedButton.styleFrom(
                              elevation: 5,
                              //backgroundColor: isPressedB5 ? Colors.black : Colors.blue,
                              backgroundColor: isSelected[0] ? Colors.black : Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                                side:  BorderSide(
                                  width: 5,
                                  style: BorderStyle.solid,
                                  //color: isPressedB5 ? Colors.black : Colors.blueAccent,),
                                  color: isSelected[0]? Colors.black : Colors.blueAccent,),
                              )
                          ),
                          onPressed: () {// Add your action here
                            setState(() {
                              //isPressedB5 = !isPressedB5;
                              selectButton(0);
                              });
                          },

                        ),

                    ),
                    ),
                    //SizedBox(width: 8.0),
                    Container(
                      margin: EdgeInsets.only(right: 20.0),
                    child:  SizedBox(
                      height: 80,
                      width: 100,
                      child:ElevatedButton(
                        child: Text('+5',
                          style: TextStyle(fontSize: 50),),
                        style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: isSelected[1] ? Colors.black : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side:  BorderSide(
                                width: 5,
                                style: BorderStyle.solid,
                                color: isSelected[1] ? Colors.black : Colors.blueAccent,),
                            )
                        ),
                        onPressed: () {// Add your action here
                          setState(() {
                            //isPressedA5 = !isPressedA5;
                            selectButton(1);
                          });
                        },

                      ),

                    ),
                    ),
                    //const SizedBox(width: 2),
                    Container(
                      margin: EdgeInsets.only(right: 0),
                      child:  SizedBox(
                      height: 80,
                      width: 100,
                      child:ElevatedButton(
                        child: Text('+10',
                          style: TextStyle(fontSize: 40),),
                        style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: isSelected[2] ? Colors.black : Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                              side:  BorderSide(
                                width: 5,
                                style: BorderStyle.solid,
                                color: isSelected[2] ? Colors.black : Colors.blueAccent,),
                            )
                        ),
                        onPressed: () {// Add your action here
                          setState(() {
                            //isPressedA10 = !isPressedA10;
                            selectButton(2);
                          });
                        },

                      ),
                    ),
                    )
                    //SizedBox(width: 8.0),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Align buttons evenly within the row
              children: <Widget>[
                SizedBox(width: 10.0),
                SizedBox(
                  height: 80,
                  width: 100,
                  child:ElevatedButton(
                    child: Icon(
                      CupertinoIcons.infinite,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isPressedInfi ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isPressedInfi ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        isPressedInfi = !isPressedInfi;
                        for (int i = 0; i < isSelected.length; i++) {
                          isSelected[i] = false; //deselect
                        }
                      });
                    },




                  ),

                ),
                SizedBox(width: 8.0),
                SizedBox(
                  height: 80,
                  width: 100,
                  child:ElevatedButton(
                    child: Icon(
                      CupertinoIcons.doc_chart_fill,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isPressedDoc ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isPressedDoc ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        //playSound('sounds/streetalarm.wav');
                        //readCollection();
                        isPressedDoc = !isPressedDoc;
                      });
                    },




                  ),

                ),
                SizedBox(width: 8.0),
                SizedBox(
                  height: 80,
                  width: 100,
                  child:ElevatedButton(
                    child: Icon(
                      CupertinoIcons.settings_solid,
                      size: 55,
                    ),
                    style: ElevatedButton.styleFrom(
                        elevation: 5,
                        backgroundColor: isPressedStng ? Colors.black : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color: isPressedStng ? Colors.black : Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        playSound('sounds/policeOpSiren.mp3');
                        isPressedStng = !isPressedStng;
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
    final formattedTime = DateFormat('MMM dd yyyy, hh:mm:ss aaa').format(now); // Customize the time format as needed.
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