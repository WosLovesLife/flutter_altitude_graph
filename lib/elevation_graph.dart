import 'package:flutter/material.dart';
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
      child: CustomPaint(
        painter: ElevationPainter(getElevationPointList()),
      ),
    );
  }
}

class ElevationPainter extends CustomPainter {
  List<ElevationPoint> elevationPointList;

  Paint mLinePaint = Paint()
    ..color = Colors.blueAccent
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  Paint mLevelLinePaint = Paint()
    ..color = Colors.amber
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  ElevationPoint lastPoint;

  ElevationPainter(this.elevationPointList) : lastPoint = elevationPointList.last;

  @override
  void paint(Canvas canvas, Size size) {
    drawAxis(canvas, size);

    drawLines(size, canvas);
  }

  /// 绘制背景数轴
  void drawAxis(Canvas canvas, Size size) {
    canvas.save();
    canvas.drawPath(dottedLine(330.0, 100.0, 2.0, 2.0), mLevelLinePaint);
    generateLevelText("7000")
      ..layout()
      ..paint(canvas, Offset(330.0, 95.0));
    canvas.drawPath(dottedLine(330.0, 200.0, 2.0, 2.0), mLevelLinePaint);
    generateLevelText("6000")
      ..layout()
      ..paint(canvas, Offset(330.0, 195.0));
    canvas.drawPath(dottedLine(330.0, 300.0, 2.0, 2.0), mLevelLinePaint);
    generateLevelText("5000")
      ..layout()
      ..paint(canvas, Offset(330.0, 295.0));
    canvas.drawPath(dottedLine(330.0, 400.0, 2.0, 2.0), mLevelLinePaint);
    generateLevelText("4000")
      ..layout()
      ..paint(canvas, Offset(330.0, 395.0));
    canvas.drawPath(dottedLine(330.0, 500.0, 2.0, 2.0), mLevelLinePaint);
    generateLevelText("3000")
      ..layout()
      ..paint(canvas, Offset(330.0, 495.0));
    canvas.restore();
  }

  Path dottedLine(double width, double y, double cutWidth, double interval) {
    var path = Path();
    var d = width / (cutWidth + interval);
    path.moveTo(0.0, y);
    for (int i = 0; i < d; i++) {
      path.relativeLineTo(cutWidth, 0.0);
      path.relativeMoveTo(interval, 0.0);
    }
    return path;
  }

  TextPainter generateLevelText(String text) {
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
