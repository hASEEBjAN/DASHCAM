import 'dart:async';
import 'package:flutter/material.dart';
import '../models/wifi.dart';
import '../utils/database_helper.dart';
import '../screens/wifi_detail.dart';
import 'package:sqflite/sqflite.dart';
import 'ble_wifisetter/main.dart';
import 'image_streaming/main.dart';

class WifiList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _WifiListState();
  }
}

class _WifiListState extends State<WifiList> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Wifi> wifiList;
  int count = 0;

  @override
  void initState() {
    super.initState();
    updateListView();
  }

  @override
  Widget build(BuildContext context) {
    if (WifiList == null) {
      wifiList = List<Wifi>();
      updateListView();
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('ESP32 CAM IoT'),
      ),
      body: getWifiListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB clicked');
          navigateToDetail(Wifi('','',''),'Add Wifi Node');
        },
        tooltip: 'Add Wifi',
        child: Icon(Icons.add),
      ),
      persistentFooterButtons: <Widget>[
        Container(
          width: MediaQuery.of(context).copyWith().size.width,
          child: Row(
            children: [
              Expanded(
                child: RaisedButton(
                  onPressed: (){
                    navigateToStream();
                  },
                  child: Text('Stream'),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  ListView getWifiListView() {
    TextStyle titleStyle = Theme.of(context).textTheme.subhead;

    return ListView.builder(
      itemCount: count,
      itemBuilder: (BuildContext context, int position) {
        return Card(
          elevation: 2.0,
          child: ListTile(
            leading: CircleAvatar(
              child: Text((position+1).toString()),
            ),
            title: Text(
              this.wifiList[position].ssid,
              style: titleStyle,
            ),
            subtitle: Text(this.wifiList[position].date),
            trailing: GestureDetector(
              child: Icon(
                Icons.delete,
                color: Colors.grey,
              ),
              onTap: () {
                _delete(context, wifiList[position]);
              },
            ),
            onTap: () {
              debugPrint("ListTile Tapped");
              navigateTowifisetter(this.wifiList[position], 'Setting Wifi cred via BLE');
            },
          ),
        );
      },
    );
  }

  void _delete(BuildContext context, Wifi wifi) async {
    int result = await databaseHelper.deleteWifi(wifi.id);
    if (result != 0) {
      _showSnackBar(context, 'Wifi Deleted Successfully');
      updateListView();
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  void navigateToDetail(wifi,title) async {
    bool result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WifiDetail(wifi,title);
    }));

    if (result == true) {
      updateListView();
    }
  }

  void navigateTowifisetter(Wifi wifi, String title) async {
    bool result =
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WifiSetter(wifi,title);
    }));

    if (result == true) {
      updateListView();
    }
  }

  void navigateToStream() async {
    bool result =
    await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WebsocketCheck();
    }));

    if (result == true) {
      updateListView();
    }
  }

  void updateListView() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<Wifi>> wifiListFuture = databaseHelper.getWifiList();
      wifiListFuture.then((wifiList) {
        setState(() {
          this.wifiList = wifiList;
          this.count = wifiList.length;
        });
      });
    });
  }
}
