import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';

class ElevationPoint {
  String name;

  String category;

  Offset point;

  Color color;

  TextPainter textPainter;
}

String pointJson =
    "[{\"x\":0.0,\"y\":485.0,\"name\":\"成都\",\"cat\":\"START_END\"},{\"x\":1.90494736842105,\"y\":485.0,\"name\":\"成都_新津县_0\",\"cat\":\"PATH\"},{\"x\":3.8098947368421,\"y\":483.146453857422,\"name\":\"成都_新津县_1\",\"cat\":\"PATH\"},{\"x\":5.71484210526315,\"y\":481.860504150391,\"name\":\"成都_新津县_2\",\"cat\":\"PATH\"},{\"x\":7.6197894736842,\"y\":481.290100097656,\"name\":\"成都_新津县_3\",\"cat\":\"PATH\"},{\"x\":9.52473684210525,\"y\":480.875396728516,\"name\":\"成都_新津县_4\",\"cat\":\"PATH\"},{\"x\":11.4296842105263,\"y\":488.583923339844,\"name\":\"成都_新津县_5\",\"cat\":\"PATH\"},{\"x\":13.33463157894735,\"y\":491.760528564453,\"name\":\"成都_新津县_6\",\"cat\":\"PATH\"},{\"x\":15.2395789473684,\"y\":488.287567138672,\"name\":\"成都_新津县_7\",\"cat\":\"PATH\"},{\"x\":17.14452631578945,\"y\":485.122741699219,\"name\":\"成都_新津县_8\",\"cat\":\"PATH\"},{\"x\":19.049473684210497,\"y\":482.653381347656,\"name\":\"成都_新津县_9\",\"cat\":\"PATH\"},{\"x\":20.954421052631545,\"y\":475.952239990234,\"name\":\"成都_新津县_10\",\"cat\":\"PATH\"},{\"x\":22.859368421052594,\"y\":473.387084960938,\"name\":\"成都_新津县_11\",\"cat\":\"PATH\"},{\"x\":24.764315789473642,\"y\":469.426452636719,\"name\":\"成都_新津县_12\",\"cat\":\"PATH\"},{\"x\":26.66926315789469,\"y\":467.214965820313,\"name\":\"成都_新津县_13\",\"cat\":\"PATH\"},{\"x\":28.57421052631574,\"y\":463.935668945313,\"name\":\"成都_新津县_14\",\"cat\":\"PATH\"},{\"x\":30.479157894736787,\"y\":459.696228027344,\"name\":\"成都_新津县_15\",\"cat\":\"PATH\"},{\"x\":32.384105263157835,\"y\":456.293975830078,\"name\":\"成都_新津县_16\",\"cat\":\"PATH\"},{\"x\":34.28905263157888,\"y\":453.923553466797,\"name\":\"成都_新津县_17\",\"cat\":\"PATH\"},{\"x\":36.19399999999993,\"y\":454.883728027344,\"name\":\"新津县\",\"cat\":\"CITY\"},{\"x\":38.09784210526309,\"y\":453.923553466797,\"name\":\"新津县_邛崃市_0\",\"cat\":\"PATH\"},{\"x\":40.00168421052625,\"y\":457.986419677734,\"name\":\"新津县_邛崃市_1\",\"cat\":\"PATH\"},{\"x\":41.90552631578941,\"y\":462.252044677734,\"name\":\"新津县_邛崃市_2\",\"cat\":\"PATH\"},{\"x\":43.80936842105257,\"y\":463.615661621094,\"name\":\"新津县_邛崃市_3\",\"cat\":\"PATH\"},{\"x\":45.71321052631573,\"y\":469.051025390625,\"name\":\"新津县_邛崃市_4\",\"cat\":\"PATH\"},{\"x\":47.617052631578886,\"y\":470.006896972656,\"name\":\"新津县_邛崃市_5\",\"cat\":\"PATH\"},{\"x\":49.520894736842045,\"y\":474.797393798828,\"name\":\"新津县_邛崃市_6\",\"cat\":\"PATH\"},{\"x\":51.424736842105204,\"y\":474.590515136719,\"name\":\"新津县_邛崃市_7\",\"cat\":\"PATH\"},{\"x\":53.328578947368364,\"y\":475.499389648438,\"name\":\"新津县_邛崃市_8\",\"cat\":\"PATH\"},{\"x\":55.23242105263152,\"y\":475.000183105469,\"name\":\"新津县_邛崃市_9\",\"cat\":\"PATH\"},{\"x\":57.13626315789468,\"y\":478.392303466797,\"name\":\"新津县_邛崃市_10\",\"cat\":\"PATH\"},{\"x\":59.04010526315784,\"y\":480.94189453125,\"name\":\"新津县_邛崃市_11\",\"cat\":\"PATH\"},{\"x\":60.943947368421,\"y\":483.241943359375,\"name\":\"新津县_邛崃市_12\",\"cat\":\"PATH\"},{\"x\":62.84778947368416,\"y\":489.0,\"name\":\"新津县_邛崃市_13\",\"cat\":\"PATH\"},{\"x\":64.75163157894733,\"y\":490.147644042969,\"name\":\"新津县_邛崃市_14\",\"cat\":\"PATH\"},{\"x\":66.65547368421049,\"y\":491.791351318359,\"name\":\"新津县_邛崃市_15\",\"cat\":\"PATH\"},{\"x\":68.55931578947366,\"y\":498.0,\"name\":\"新津县_邛崃市_16\",\"cat\":\"PATH\"},{\"x\":70.46315789473682,\"y\":505.640075683594,\"name\":\"新津县_邛崃市_17\",\"cat\":\"PATH\"},{\"x\":72.36699999999999,\"y\":505.505096435547,\"name\":\"邛崃市\",\"cat\":\"CITY\"},{\"x\":74.31299999999999,\"y\":505.640075683594,\"name\":\"邛崃市_名山区_0\",\"cat\":\"PATH\"},{\"x\":76.25899999999999,\"y\":497.943878173828,\"name\":\"邛崃市_名山区_1\",\"cat\":\"PATH\"},{\"x\":78.20499999999998,\"y\":505.088073730469,\"name\":\"邛崃市_名山区_2\",\"cat\":\"PATH\"},{\"x\":80.15099999999998,\"y\":546.064575195313,\"name\":\"邛崃市_名山区_3\",\"cat\":\"PATH\"},{\"x\":82.09699999999998,\"y\":550.9033203125,\"name\":\"邛崃市_名山区_4\",\"cat\":\"PATH\"},{\"x\":84.04299999999998,\"y\":557.635009765625,\"name\":\"邛崃市_名山区_5\",\"cat\":\"PATH\"},{\"x\":85.98899999999998,\"y\":571.937927246094,\"name\":\"邛崃市_名山区_6\",\"cat\":\"PATH\"},{\"x\":87.93499999999997,\"y\":579.419738769531,\"name\":\"邛崃市_名山区_7\",\"cat\":\"PATH\"}]";

//List<ElevationPoint> getElevationPointList() {
//  var decode = json.decode(pointJson);
//  List<ElevationPoint> list = List();
//  for (var value in decode) {
//    var elevationPoint = ElevationPoint();
//    elevationPoint.point = Offset(value["x"], value["y"]);
//    elevationPoint.name = value["name"];
//    elevationPoint.category = value["cat"];
//    list.add(elevationPoint);
//  }
//  return list;
//}

const List<Color> _signPointColors = [
  Colors.pink,
  Colors.teal,
  Colors.blueGrey,
  Colors.amber,
  Colors.deepOrange
];

Future<List<ElevationPoint>> getElevationPointList() {
  return rootBundle
      .loadString("assets/raw/CHUANZANGNAN.json", cache: false)
      .then((fileContents) => json.decode(fileContents))
      .then((jsonData) {
    List<ElevationPoint> list = List();

    var arrays = jsonData["RECORDS"];

    double mileage = 0.0;
    int i = 0;
    int colorIndex = Random().nextInt(_signPointColors.length);
    bool isForward = true;

    for (var geo in arrays) {
      var name = geo["NAME"];
      var elevation = double.parse(geo["ELEVATION"]);
      var fDistance = double.parse(geo["F_DISTANCE"]);
      var rDistance = double.parse(geo["R_DISTANCE"]);

      // 向String插入换行符使文字竖向绘制
      // TODO 这种写法应该是不正确的, 暂时不知道更好的作
      var splitMapJoin = name.splitMapJoin('', onNonMatch: (m) {
        if (m.isNotEmpty)
          return '$m\n';
        else
          return '';
      });
      splitMapJoin = splitMapJoin.substring(0, splitMapJoin.length - 1);

      var tp = TextPainter(
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: splitMapJoin,
          style: TextStyle(
            color: Colors.white,
            fontSize: 8.0,
          ),
        ),
      )..layout();

      var elevationPoint = new ElevationPoint()
        ..name = name
        ..color = _signPointColors[colorIndex++ % _signPointColors.length]
        ..point = Offset(mileage, elevation)
        ..textPainter = tp;

      list.add(elevationPoint);

      // 累加里程, 最后一个位置不需要进行计算
      if (i++ < arrays.length - 2) {
        double distance = isForward ? fDistance : rDistance;
        mileage = mileage + distance;
      }
    }

    return list;
  });
}
