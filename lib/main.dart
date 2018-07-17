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

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  List<AltitudePoint> _altitudePointList;
  double _maxScale = 1.0;

  AnimationController controller;
  CurvedAnimation _elasticAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(vsync: this, duration: Duration(seconds: 3));

    _elasticAnimation = CurvedAnimation(parent: controller, curve: const ElasticOutCurve(1.0));

    getAltitudePointList().then((list) {
      setState(() {
        _altitudePointList = list;

        double miters = list.last?.point?.dx ?? 0.0;
        if (miters > 0) {
          _maxScale = max(miters / 50.0, 1.0);
        } else {
          _maxScale = 1.0;
        }

        controller.forward();
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  changeData() {
    controller.duration = Duration(seconds: 1);
    controller.reverse().then((_) {
      controller.duration = Duration(seconds: 3);
      controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Altitude Graph"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                changeData();
              });
            },
          ),
        ],
      ),
      body: AltitudeGraphView(
        _altitudePointList,
        maxScale: _maxScale,
        animation: _elasticAnimation,
      ),
    );
  }
}
