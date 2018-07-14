import 'dart:math';

import 'package:flutter/material.dart';
import 'package:altitude_graph/altitude_graph.dart';
import 'package:elevation_graph/altitude_point_data.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AltitudePoint> _altitudePointList;
  double _maxScale = 1.0;

  @override
  void initState() {
    super.initState();
    getAltitudePointList().then((list) {
      setState(() {
        _altitudePointList = list;

        double miters = list.last?.point?.dx ?? 0.0;
        if (miters > 0) {
          _maxScale = max(miters / 50.0, 1.0);
        } else {
          _maxScale = 1.0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Altitude Graph"),
      ),
      body: AltitudeGraphView(_altitudePointList, maxScale: _maxScale,),
    );
  }
}
