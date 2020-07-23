import 'package:flutter/material.dart';
import '../models/wifi.dart';
import '../utils/database_helper.dart';
import 'package:intl/intl.dart';

class WifiDetail extends StatefulWidget {
  Wifi wifi;
  String appBarTitle;
  WifiDetail(this.wifi, this.appBarTitle);
  @override
  State<StatefulWidget> createState() {
    return _WifiDetailState(this.wifi, this.appBarTitle);
  }
}

class _WifiDetailState extends State<WifiDetail> {
  DatabaseHelper helper = DatabaseHelper();

  String appBarTitle;
  Wifi wifi;

  _WifiDetailState(this.wifi,this.appBarTitle);

  TextEditingController ssidcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();



  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = Theme.of(context).textTheme.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Write some code to control things, when user press back button in AppBar
              moveToLastScreen();
            }),
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
        child: ListView(
          children: <Widget>[
            // First element
            Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: TextField(
                controller: ssidcontroller,
                style: textStyle,
                onChanged: (value) {
                  debugPrint('Something changed in SSID Text Field');
                  updateSSID();
                },
                decoration: InputDecoration(
                    labelText: 'SSID',
                    labelStyle: textStyle,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
            ),

            // Third Element
            Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: TextField(
                controller: passwordcontroller,
                style: textStyle,
                onChanged: (value) {
                  debugPrint('Something changed in Password Text Field');
                  updatePassword();
                },
                decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: textStyle,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0))),
              ),
            ),

            // Fourth Element
            Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
              child: RaisedButton(
                color: Theme.of(context).primaryColorDark,
                textColor: Theme.of(context).primaryColorLight,
                child: Text(
                  'Save',
                  textScaleFactor: 1.5,
                ),
                onPressed: () {
                  setState(() {
                    debugPrint("Save button clicked");
                    _save();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void moveToLastScreen() {
    Navigator.pop(context, true);
  }

  // Update the title of Wifi object
  void updateSSID() {
    wifi.ssid = ssidcontroller.text;
  }

  // Update the Password of wifi object
  void updatePassword() {
    wifi.password = passwordcontroller.text;
  }

  // Save data to database
  void _save() async {
    moveToLastScreen();

    wifi.date = DateFormat.yMMMd().format(DateTime.now());
    int result = await helper.insertWifi(wifi);


    if (result != 0) {
      // Success
      String str=wifi.ssid;
      _showAlertDialog('Status', 'Wifi $str Saved Successfully');
    } else {
      // Failure
      _showAlertDialog('Status', 'Problem Saving Wifi');
    }
  }

  void _showAlertDialog(String title, String message) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(context: context, builder: (_) => alertDialog);
  }
}
