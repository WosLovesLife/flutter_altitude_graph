import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:altitude_graph/altitude_graph.dart';

const Color START_AND_END = Colors.red;
const Color CITY = Colors.deepOrange;
const Color COUNTY = Colors.blueGrey;
const Color TOWN = Colors.blue;
const Color VILLAGE = Colors.green;
const Color MOUNTAIN = Colors.brown;
const Color TUNNEL = Colors.red;
const Color CAMP_SPOT = Colors.blue;
const Color SCENIC_SPOT = Colors.blueGrey;
const Color CHECK_POINT = Colors.orange;
const Color BRIDGE = Colors.green;
const Color GAS_STATION = Colors.lightGreen;
const Color OTHERS = Colors.deepPurpleAccent;

Future<List<AltitudePoint>> parseGeographyData(String assetsPath) {
  return rootBundle
      .loadString(assetsPath, cache: false)
      .then((fileContents) => json.decode(fileContents))
      .then((jsonData) {
    List<AltitudePoint> list = List();

    var arrays = jsonData["RECORDS"];

    double mileage = 0.0;

    for (var geo in arrays) {
      var name = geo["NAME"];
      if (name.contains('_')) name = null; // 低级别地名不显示

      int level;
      Color color;
      var altitude = double.parse(geo["ELEVATION"]);

      /// 根据不同的type定义各个点的级别和label的颜色, 这将影响到在不同的缩放级别下, 显示哪些label
      /// level值越大, 优先级越高
      switch (geo["TYPES"]) {
        case 'CITY':
          level = 4;
          color = CITY;
          break;
        case 'MOUNTAIN':
          level = 3;
          color = MOUNTAIN;
          break;
        case 'COUNTY':
          level = 3;
          color = COUNTY;
          break;
        case 'TOWN':
          level = 2;
          color = TOWN;
          break;
        case 'VILLAGE':
          level = 2;
          color = VILLAGE;
          break;
        case 'TUNNEL':
          level = 2;
          color = TUNNEL;
          break;
        case 'BRIDGE':
          level = 2;
          color = BRIDGE;
          break;
        case 'CHECK_POINT':
          level = 1;
          color = CHECK_POINT;
          break;
        case 'CAMP_SPOT':
          level = 1;
          color = CAMP_SPOT;
          break;
        case 'SCENIC_SPOT':
          level = 1;
          color = SCENIC_SPOT;
          break;
        default:
          level = 0;
          color = OTHERS;
          break;
      }

      var altitudePoint = new AltitudePoint(
        name,
        level,
        Offset(mileage, altitude),
        color,
      );

      list.add(altitudePoint);

      /// 累加里程
      /// 原始Json中的distance表示的是当前点距离下一个点的距离, 但是我们这里需要计算的是[当前点距离起点的距离]
      /// 例如: 第一个点就是起点因此距离起点是0公里, 第一个点距离第二个点2公里, 因此第二个点距离起点2公里
      /// 第二个点距离第三个点3公里, 因此第三个点距离起点是5公里, 以此类推...
      double distance = double.parse(geo["F_DISTANCE"]);
      mileage = mileage + distance;
    }

    list.first.level = 5;
    list.first.color = START_AND_END;
    list.last.level = 5;
    list.last.color = START_AND_END;

    return list;
  });
}
