import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:elevation_graph/elevation_point.dart';

class ElevationGraphView extends StatefulWidget {
  @override
  ElevationGraphViewState createState() {
    return new ElevationGraphViewState();
  }
}

class ElevationGraphViewState extends State<ElevationGraphView> {
  List<ElevationPoint> elevationPointList;

  @override
  void initState() {
    super.initState();

    getElevationPointList().then((list) {
      setState(() {
        elevationPointList = list;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print("elevationPointList = $elevationPointList");
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(bottom: 100.0),
      child: CustomPaint(
        painter: ElevationPainter(elevationPointList, 7000.0, 2000.0),
      ),
    );
  }
}

const int AXIS_TEXT_MARGIN = 8;
const double DOTTED_LINE_WIDTH = 2.0;
const double DOTTED_LINE_INTERVAL = 2.0;

const List<Color> signPointColors = [
  Colors.pink,
  Colors.teal,
  Colors.blueGrey,
  Colors.amber,
  Colors.deepOrange
];

class ElevationPainter extends CustomPainter {
  // ===== Data
  List<ElevationPoint> elevationPointList;
  ElevationPoint lastPoint;

  double maxVerticalAxisValue;
  double verticalAxisInterval;

  // ===== Paint
  Paint mLinePaint = Paint()
    ..color = Color(0xFF003c60)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  Paint mSignPointPaint = Paint()..color = Colors.pink;

  Paint mGradualPaint = Paint()..style = PaintingStyle.fill;

  Paint mLevelLinePaint = Paint()
    ..color = Colors.amber
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  ElevationPainter(
    this.elevationPointList,
    this.maxVerticalAxisValue,
    this.verticalAxisInterval,
  ) : lastPoint = elevationPointList?.last;

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(size, canvas);

    drawVerticalAxis(canvas, size);
  }

  /// =========== 绘制纵轴部分

  /// 绘制背景数轴
  /// 根据最大高度和间隔值计算出需要把纵轴分成几段
  void drawVerticalAxis(Canvas canvas, Size size) {
    var availableHeight = size.height;

    var levelCount = maxVerticalAxisValue / verticalAxisInterval;

    var interval = availableHeight / levelCount;

    canvas.save();
    for (int i = 0; i < levelCount; i++) {
      var level = (verticalAxisInterval * (levelCount - i)).toInt();
      drawVerticalAxisLine(canvas, size, "$level", i * interval);
    }
    canvas.restore();
  }

  /// 绘制数轴的一行
  void drawVerticalAxisLine(Canvas canvas, Size size, String text, double height) {
    var tp = newVerticalAxisTextPainter(text)..layout();

    // 绘制虚线
    // 虚线的宽度 = 可用宽度 - 文字宽度 - 文字宽度的左右边距
    var dottedLineWidth = size.width - tp.width - AXIS_TEXT_MARGIN * 2;
    canvas.drawPath(newDottedLine(dottedLineWidth, height, DOTTED_LINE_WIDTH, DOTTED_LINE_INTERVAL),
        mLevelLinePaint);

    // 绘制虚线右边的Text
    // Text的绘制起始点 = 可用宽度 - 文字宽度 - 左边距
    var textLeft = size.width - tp.width - AXIS_TEXT_MARGIN;
    tp.paint(canvas, Offset(textLeft, height - tp.height / 2));
  }

  // 生成虚线的Path
  Path newDottedLine(double width, double y, double cutWidth, double interval) {
    var path = Path();
    var d = width / (cutWidth + interval);
    path.moveTo(0.0, y);
    for (int i = 0; i < d; i++) {
      path.relativeLineTo(cutWidth, 0.0);
      path.relativeMoveTo(interval, 0.0);
    }
    return path;
  }

  // 生成纵轴文字的TextPainter
  TextPainter newVerticalAxisTextPainter(String text) {
    return TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.blueGrey,
          fontSize: 10.0,
        ),
      ),
    );
  }

  /// =========== 绘制海拔图连线部分

  /// 绘制海拔图连线部分
  void drawLines(Size size, Canvas canvas) {
    size = Size(size.width - 40, size.height - 15);
    canvas.translate(0.0, 15.0);

    var pointList = elevationPointList;
    if (pointList == null || pointList.isEmpty) return;

    double ratioX = size.width * 1.0 / pointList.last.point.dx;
    double ratioY = size.height / maxVerticalAxisValue;

    var firstPoint = pointList.first.point;
    var path = Path();
    path.moveTo(firstPoint.dx * ratioX, firstPoint.dy * ratioY);
    for (var p in pointList) {
      path.lineTo(p.point.dx * ratioX, size.height - p.point.dy * ratioY);
    }

    // 绘制线条下面的渐变部分
    drawGradualShadow(path, size, canvas);

    // 先绘制渐变再绘制线,避免线被遮挡住
    canvas.save();
    canvas.drawPath(path, mLinePaint);
    canvas.restore();

    // 绘制关键点及文字
    canvas.save();
    int i = Random().nextInt(signPointColors.length);
    for (var p in pointList) {
      if (p.name == null || p.name.isEmpty) continue;
      if (p.name.contains('_')) continue;

      // 向String插入换行符使文字竖向绘制
      // TODO 这种写法应该是不正确的, 暂时不知道更好的作
      var splitMapJoin = p.name.splitMapJoin('', onNonMatch: (m) {
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
            fontSize: 11.0,
          ),
        ),
      )..layout();

      // 绘制关键点
      mSignPointPaint.color = signPointColors[i++ % signPointColors.length];
      canvas.drawCircle(
          Offset(p.point.dx * ratioX, size.height - p.point.dy * ratioY), 2.0, mSignPointPaint);

      // 默认将文字绘制的起始点设为文字的宽度的中部, 但是如果文字超出了边界, 将其限制在边界内
      var left = p.point.dx * ratioX - tp.width / 2;
      if (left < 0) {
        left = 0.0;
      } else if (left + tp.width > size.width) {
        left = size.width - tp.width;
      }

      // 绘制文字的背景框
      canvas.drawRRect(
          RRect.fromLTRBXY(
            left - 2,
            size.height - p.point.dy * ratioY - tp.height - 8,
            left + tp.width + 2,
            size.height - p.point.dy * ratioY - 4,
            6.0,
            6.0,
          ),
          mSignPointPaint);

      // 绘制文字
      tp.paint(canvas, Offset(left, size.height - p.point.dy * ratioY - tp.height - 6));
    }

    canvas.restore();
  }

  void drawGradualShadow(Path path, Size size, Canvas canvas) {
    var gradualPath = Path();
    gradualPath.addPath(path, Offset.zero);
    gradualPath.lineTo(size.width, size.height);
    gradualPath.lineTo(0.0, size.height);

    mGradualPaint.shader = ui.Gradient.linear(
        Offset(0.0, 300.0), Offset(0.0, size.height), [Color(0x821E88E5), Color(0x0C1E88E5)]);

    canvas.save();
    canvas.drawPath(gradualPath, mGradualPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
