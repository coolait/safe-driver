import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String email = '';
  String parentPhoneNumber = '';
  String selectedSoundType = 'policeOpSiren.mp3';
  String speedThreshold = '15';

  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final speedThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPreferences();
  }
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '';
      parentPhoneNumber = prefs.getString('parentPhoneNumber') ?? '';
      selectedSoundType = prefs.getString('selectedSoundType') ?? 'policeOpSiren.mp3';
      speedThreshold = prefs.getString('speedThreshold') ?? '15';

      // Set the initial values for the controllers
      emailController.text = email;
      phoneNumberController.text = parentPhoneNumber;
      speedThresholdController.text = speedThreshold;

    });
  }
  // List of available sound types
  List<String> soundTypes = [ 'policeOpSiren.mp3', 'policeSiren.mp3', 'streetalarm.wav'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: 'Parent Phone Number'),
              keyboardType: TextInputType.phone, // Use phone keyboard
              onChanged: (value) {
                setState(() {
                  parentPhoneNumber = value;
                });
              },
            ),
            TextField(
              controller: speedThresholdController,
              decoration: InputDecoration(labelText: 'Speed Threshold over speed lmit'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  speedThreshold = value;
                });
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Sound Type:'), // Add a label for the dropdown
            ),
              Align(
                alignment: Alignment.centerLeft,
                child:DropdownButton<String>(
                      value: selectedSoundType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSoundType = value;
                          });
                        }
                      },
                      items: soundTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                    ),
              ),
              ElevatedButton(
              onPressed: () async {
                // Save the settings to your preferred storage method (e.g., SharedPreferences, Firebase)
                // You can access the values of 'email', 'phoneNumber', and 'selectedSoundType' here.
                // For example, print them to the console.
                //print('Email: $email');
                //print('Phone Number: $parentPhoneNumber');
                //print('Selected Sound Type: $selectedSoundType');
                // Save the settings to shared preferences
                final prefs = await SharedPreferences.getInstance();
                prefs.setString('email', email);
                prefs.setString('parentPhoneNumber', parentPhoneNumber);
                prefs.setString('selectedSoundType', selectedSoundType);
                prefs.setString('speedThreshold', speedThreshold);
                // You can also update your app's settings using the values.
                // Return to the previous screen (MainScreen)
                Navigator.pop(context);

              },
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
