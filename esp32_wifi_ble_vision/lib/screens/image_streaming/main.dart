import 'dart:async';

import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:gesture_zoom_box/gesture_zoom_box.dart';
import 'package:loading_animations/loading_animations.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebsocketCheck extends StatefulWidget {
  @override
  _WebsocketCheckState createState() => _WebsocketCheckState();
}

class _WebsocketCheckState extends State<WebsocketCheck> {
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    initConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    _ConnectWebSocket();
    return Scaffold(
      body: Stack(
        children: <Widget>[
          LoadingFlipping.square(
            borderColor: Colors.cyan,
            size: 100,
          ),
        ],
      ),
    );
  }

  _ConnectWebSocket() {
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Camera(
                    channel:
                        IOWebSocketChannel.connect('ws://192.168.43.184:8888'),
                  )));
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }
    return result;
  }
}

class Camera extends StatefulWidget {
  final WebSocketChannel channel;

  Camera({Key key, @required this.channel}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  bool isLandscape;

  @override
  void initState() {
    super.initState();
    isLandscape = false;

  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    debugPrint(screen.height.toString());
    debugPrint(screen.width.toString());
    debugPrint(screen.aspectRatio.toString());
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Video Streaming'),
      ),
      body: StreamBuilder(
            stream: widget.channel.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                Future.delayed(Duration(milliseconds: 100)).then((_) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) =>
                              WebsocketCheck()));
                });
              }

              if (!snapshot.hasData) {

                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else {
                return Stack(
                    children: <Widget>[
                      Image.memory(
                        snapshot.data,
                        gaplessPlayback: true,
                        height: screen.height,
                        width: screen.width,
                        scale: 0.49,
                      ),
                    ],
                );
    }),
              }
      );
  }
}
