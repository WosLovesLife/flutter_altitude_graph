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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.only(bottom: 100.0),
      child: CustomPaint(
        painter: ElevationPainter(getElevationPointList()),
      ),
    );
  }
}

const int AXIS_TEXT_MARGIN = 8;
const double DOTTED_LINE_WIDTH = 2.0;
const double DOTTED_LINE_INTERVAL = 2.0;

class ElevationPainter extends CustomPainter {
  List<ElevationPoint> elevationPointList;

  Paint mLinePaint = Paint()
    ..color = Colors.blueAccent
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  Paint mGradualPaint = Paint()..style = PaintingStyle.fill;

  Paint mLevelLinePaint = Paint()
    ..color = Colors.amber
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  ElevationPoint lastPoint;

  ElevationPainter(this.elevationPointList) : lastPoint = elevationPointList.last;

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(size, canvas);

    drawVerticalAxis(canvas, size);
  }

  /// =========== 绘制纵轴部分

  /// 绘制背景数轴
  void drawVerticalAxis(Canvas canvas, Size size) {
    var availableHeight = size.height;
    var interval = availableHeight / 9.0;

    canvas.save();
    for (int i = 1; i < 10; i++) {
      var textPre = 10 - i;
      drawVerticalAxisLine(canvas, size, "${textPre}000", i * interval);
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
    double ratioX = size.width * 1.0 / elevationPointList.last.point.dx;
    double ratioY = size.height / 1000.0;

    var firstPoint = elevationPointList.first.point;
    var path = Path();
    path.moveTo(firstPoint.dx * ratioX, firstPoint.dy * ratioY);
    for (var p in elevationPointList) {
      path.lineTo(p.point.dx * ratioX, p.point.dy * ratioY);
    }

    canvas.save();
    canvas.drawPath(path, mLinePaint);
    canvas.restore();

    // 绘制线条下面的渐变部分
    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);

    mGradualPaint.shader = ui.Gradient.linear(
        Offset(0.0, 300.0), Offset(0.0, size.height), [Colors.lightBlue, Colors.greenAccent]);

    canvas.save();
    canvas.drawPath(path, mGradualPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
