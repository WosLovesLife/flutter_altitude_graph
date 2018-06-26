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
    ..strokeWidth = 3.0
    ..style = PaintingStyle.stroke;

  ElevationPoint lastPoint;

  ElevationPainter(this.elevationPointList) : lastPoint = elevationPointList.last;

  @override
  void paint(Canvas canvas, Size size) {
//    canvas.drawLine(Offset(0.0, 500.0), Offset(350.0, 500.0), mLevelLinePaint);
//    canvas.drawLine(Offset(0.0, 400.0), Offset(350.0, 400.0), mLevelLinePaint);
//    canvas.drawLine(Offset(0.0, 300.0), Offset(350.0, 300.0), mLevelLinePaint);
//    canvas.drawLine(Offset(0.0, 200.0), Offset(350.0, 200.0), mLevelLinePaint);
//    canvas.drawLine(Offset(0.0, 100.0), Offset(350.0, 100.0), mLevelLinePaint);
    canvas.save();
    canvas.drawPath(dottedLine(350, 500.0, 3.0, 3.0), mLevelLinePaint);
    canvas.restore();
//    canvas.drawPath(dottedLine(350, 400.0, 3.0, 3.0), mLevelLinePaint);
//    canvas.drawPath(dottedLine(350, 300.0, 3.0, 3.0), mLevelLinePaint);
//    canvas.drawPath(dottedLine(350, 200.0, 3.0, 3.0), mLevelLinePaint);
//    canvas.drawPath(dottedLine(350, 100.0, 3.0, 3.0), mLevelLinePaint);

    double ratioX = size.width * 1.0 / elevationPointList.last.point.dx;
    double ratioY = size.height / 1000.0;

    print("ratioX = $ratioX; ratioY = $ratioY");

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

  Path dottedLine(int width, double y, double cutWidth, double interval) {
    var path = Path();
    var d = (cutWidth + interval) / width;
    path.moveTo(0.0, y);
    for (int i = 0; i < d; i++) {
      path.lineTo(i * cutWidth, y);
//      path.relativeMoveTo(interval, y);
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
