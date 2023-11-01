import 'dart:async';
import 'dart:math';
// import 'package:speedometer/speedometer.dart';

import 'package:car_speed/settings_page.dart';
import 'package:car_speed/violationReport.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_rich_text/simple_rich_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
//import 'package:audioplayers/audio_cache.dart';
import 'package:torch_light/torch_light.dart';
import 'package:flutter_sms/flutter_sms.dart';


import 'OSMSpeedLimit.dart';
import 'firestore_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100.0,
          title: Text('Safe-Driver',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat', // Use a custom font
            color: Colors.white, // Set a custom text color
          ),
        ),
          elevation: 0,
          flexibleSpace: const Image(
            image: NetworkImage(
                'https://wallpaperaccess.com/full/1816185.jpg'),
            fit: BoxFit.fill,
          ),
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
  int speed = 0;
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
  List<bool> isSelected2 = [true,false,false];
  final player  = AudioPlayer();
  DateTime? _lastWriteTextstamp;

  final FirestoreService _firestoreService = FirestoreService();

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

  Future<void> flickerTorch(Duration flickerDuration) async {
    bool isFlickering = true;
    Timer flickerTimer;

    flickerTimer = Timer.periodic(Duration(milliseconds: 200), (Timer timer) async {
      if (!isFlickering) {
        timer.cancel();
        return;
      }

      await TorchLight.enableTorch(); // Turn on the flashlight
      await Future.delayed(Duration(milliseconds: 100)); // Keep it on for 100 milliseconds
      await TorchLight.disableTorch(); // Turn off the flashlight
      await Future.delayed(Duration(milliseconds: 100)); // Keep it off for 100 milliseconds
    });

    // Run the flicker for the specified duration
    await Future.delayed(flickerDuration);

    // Stop the flicker
    isFlickering = false;
    flickerTimer.cancel();
  }


  void playSound(String Alarm) async {

    await player.setVolume(0.5);
    print('got the alamrm {$Alarm}');
    //int result = await player.play('assets/sound.mp3'); // Replace with your sound file path
    await player.play(AssetSource(Alarm));
    await Future.delayed(Duration(seconds:3));
    player.stop();

      }

  void _sendSMS(String message, List<String> recipents) async {
    String _result = await sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      print(onError);
    });
    print(_result);
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

    Geolocator.getPositionStream(locationSettings: locationOptions,
      )
        .listen((Position position) {

      setState(() {
        //print('updating speed ${DateTime.now()}');
        // Update the speed whenever a new location is received
        double locSpeed = (position.speed * 2.23694);
        if(locSpeed>2) locSpeed= locSpeed.ceilToDouble();
        speed = (locSpeed ).toInt(); //converting to mph
        latit = position.latitude;
        longi = position.longitude;
        //print ('location is: ');
        //print(position);
      });
    });

    Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      var position = await Geolocator.getCurrentPosition();
      double locSpeed = (position.speed * 2.23694);
      if(locSpeed>2) locSpeed= locSpeed.ceilToDouble();
      //setPosition(position);
      setState(() {
        speed = (locSpeed ).toInt(); //converting to mph
      });
    });

    Timer.periodic(const Duration(seconds: 2), (timer) async {
      var position = await Geolocator.getCurrentPosition();

      OverpassRepository myOSM = OverpassRepository();
      speedLimit = (await myOSM.getCarSpeedAt(position))!;
      roadName = (await myOSM.getRoadName())!;

      //speed = 30.0;
      //print("Speed $speed  ${DateTime.now()}");
      //print("SpeedLmt $speedLimit");
      //if the speed is > Speedlimit lets log violation
      if(speed > speedLimit && speed > 10 && speedLimit != 0 ){
        //write to Firebase build the map
        // Call the method to write the document and pass the data map
        Map<String, dynamic> userData = {
          'Date': DateTime.now(),
          'Road': roadName,
          'Speed': speed,
          'SpeedLimit': speedLimit,
        };
        _firestoreService.writeUserData(userData);
        //wreckless driving
        int calculatedThreshold = speedLimit;
        final prefs = await SharedPreferences.getInstance();
        // Retrieve the 'speedThreshold' from shared preferences.
        String? speedThreshold = prefs.getString('speedThreshold');
        if (speedThreshold != null) {
          try {
            int parsedSpeedThreshold = int.parse(speedThreshold);
            calculatedThreshold += parsedSpeedThreshold;
          } catch (e) {
            // Handle the case where 'speedThreshold' is not a valid integer.
            print('Error parsing speedThreshold: $e');
          }
        }
        final currentTime = DateTime.now();
        if(speed > calculatedThreshold && (_lastWriteTextstamp == null ||
            currentTime.difference(_lastWriteTextstamp!).inMinutes >= 1)){
          _lastWriteTextstamp = currentTime;
          String message = "Kid is driving at reckless Speed:$speed in $speedLimit";
          String? parentPhone = prefs.getString('parentPhoneNumber');
          List<String> recipents = [parentPhone ?? ''];

          //_sendSMS(message, recipents);
          String _result = await sendSMS(message: message, recipients: recipents, sendDirect: true)
              .catchError((onError) {
            print(onError);
          });
        }
      }


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

      if (adjSpeedLimit < 11) {
        //print("Did not get Speed-lmit");
      } else if (speed > adjSpeedLimit!) {
        //print("voiced");
        //Alert based on the setting user has picked
      if (isSelected2[0]) {
        //Sound only
        final prefs = await SharedPreferences.getInstance();
        // Retrieve the 'speedThreshold' from shared preferences.
        String? selectedSoundType = prefs.getString('selectedSoundType');
        String defaultSoundType = 'sounds/streetalarm.wav';
        String combinedSoundType = 'sounds/' + (selectedSoundType ?? defaultSoundType);
        playSound(combinedSoundType);
      } else if (isSelected2[1]) {
        speakText("You are Over Speed Limit");
        //print("Speed-limit $speedLimit");
      }else if (isSelected2[2]) {
        flickerTorch(Duration(seconds: 3));
        //speakText("You are in Flash");

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
                        for (int i = 0; i < isSelected.length; i++) {
                          isSelected2[i] = false; //deselect
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
                        backgroundColor: /*isPressedDoc ? Colors.black :*/ Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:  BorderSide(
                            width: 5,
                            style: BorderStyle.solid,
                            color:/* isPressedDoc ? Colors.black :*/ Colors.blueAccent,),
                        )
                    ),
                    onPressed: () {// Add your action here
                      setState(() {
                        //playSound('sounds/streetalarm.wav');
                        //readCollection();
                        isPressedDoc = !isPressedDoc;
                        // Navigate to the new screen (TableScreen) when the button is clicked
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => ViolationReport()));

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
                    onPressed: () async {// Add your action here

                        //playSound('sounds/policeOpSiren.mp3');
                        //flashTorch();
                        //flickerTorch(Duration(seconds: 3));

                      // Navigate to the SettingsPage when the button is pressed
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                      );


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