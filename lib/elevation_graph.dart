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

  // 放大/和放大的基点的值. 在动画/手势中会实时变化
  double _scale = 1.0;
  double _maxScale = 1.0;
  Offset _position = Offset.zero;

  // ==== 辅助动画/手势的计算
  Offset _focusPoint;

  // ==== 上次放大的比例, 用于帮助下次放大操作时放大的速度保持一致.
  double _lastScaleValue = 1.0;
  Offset _lastUpdateFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();

    getElevationPointList().then((list) {
      setState(() {
        elevationPointList = list;
        double miters = list?.last?.point?.dx ?? 0.0;
        if (miters > 0) {
          _maxScale = max(miters / 30.0, 1.0);
        } else {
          _maxScale = 1.0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
//      onPanDown: _onPanDown,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.only(bottom: 100.0),
        child: CustomPaint(
          painter: ElevationPainter(
            elevationPointList,
            7000.0,
            2000.0,
            _scale,
            _position,
          ),
        ),
      ),
    );
  }

  // ===========

  _onScaleStart(ScaleStartDetails details) {
    _focusPoint = details.focalPoint;
    _lastScaleValue = _scale;
    _lastUpdateFocalPoint = details.focalPoint;
  }

  _onScaleUpdate(ScaleUpdateDetails details) {
    double newScale = (_lastScaleValue * details.scale);

    if (newScale < 1.0) {
      newScale = 1.0;
    } else if (newScale > _maxScale) {
      newScale = _maxScale;
    }

    // 算法: 左偏移量L = 当前焦点f在之前图宽上的位置p带入到新图宽中再减去焦点f在屏幕上的位置
    // ratioInGraph 就是当前的焦点实际对应在之前的图宽上的比例
    double ratioInGraph = (_position.dx.abs() + _focusPoint.dx) / (_scale * context.size.width);
    // 现在新计算出的图宽
    double newTotalWidth = newScale * context.size.width;
    // 将之前的比例带入当前的图宽即为焦点在新图上的位置
    double newLocationInGraph = ratioInGraph * newTotalWidth;
    // 最后用焦点在屏幕上的位置 - 在图上的位置就是图应该向左偏移的位置
    double left = _focusPoint.dx - newLocationInGraph;

    // 加上水平拖动的偏移量
    var deltaPosition = (details.focalPoint - _lastUpdateFocalPoint);
    _lastUpdateFocalPoint = details.focalPoint;
    left += deltaPosition.dx;

    // 将x范围限制图表宽度内
    var newPosition = Offset(left, 0.0);
    double clampedX = newPosition.dx.clamp((newScale - 1) * -context.size.width, 0.0);
    newPosition = Offset(clampedX, newPosition.dy);

    setState(() {
      _scale = newScale;
      _position = newPosition;
    });
  }

  _onScaleEnd(ScaleEndDetails details) {}
}

const int VERTICAL_TEXT_WIDTH = 30;
const double DOTTED_LINE_WIDTH = 2.0;
const double DOTTED_LINE_INTERVAL = 2.0;

class ElevationPainter extends CustomPainter {
  // ===== Data
  List<ElevationPoint> _elevationPointList;

  double maxVerticalAxisValue;
  double verticalAxisInterval;

  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // ===== Paint
  Paint _linePaint = Paint()
    ..color = Color(0xFF003c60)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  Paint _signPointPaint = Paint()..color = Colors.pink;

  Paint _gradualPaint = Paint()..style = PaintingStyle.fill;

  Paint _levelLinePaint = Paint()
    ..color = Colors.amber
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  ElevationPainter(
    this._elevationPointList,
    this.maxVerticalAxisValue,
    this.verticalAxisInterval,
    this._scale,
    this._offset,
  );

  @override
  void paint(Canvas canvas, Size size) {
    Size availableSize = Size(size.width, size.height - 30.0);
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    canvas.translate(0.0, 15.0);

    Size lineSize = Size(availableSize.width * _scale, availableSize.height);
    canvas.save();
    canvas.translate(_offset.dx, 0.0);
    drawLines(lineSize, canvas);
    canvas.restore();

    drawVerticalAxis(canvas, availableSize);

    drawHorizontalAxis(canvas, availableSize, availableSize.width * _scale,0.0);
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
    var dottedLineWidth = size.width - VERTICAL_TEXT_WIDTH;
    canvas.drawPath(newDottedLine(dottedLineWidth, height, DOTTED_LINE_WIDTH, DOTTED_LINE_INTERVAL),
        _levelLinePaint);

    // 绘制虚线右边的Text
    // Text的绘制起始点 = 可用宽度 - 文字宽度 - 左边距
    var textLeft = size.width - tp.width - 4;
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
          color: Colors.black87,
          fontSize: 8.0,
        ),
      ),
    );
  }

  void drawHorizontalAxis(Canvas canvas, Size size, double totalWidth, double left) {
    Offset lastPoint = _elevationPointList?.last?.point;
    if (lastPoint == null) return;

    double totalMiter = lastPoint.dx;
    double ratio = size.width / totalWidth;
    double miterToShow = ratio * totalMiter;

    double interval = (miterToShow / 6.0).floorToDouble();
    print('miterToShow = $miterToShow; interval = $interval');
    if(interval >= 100.0){
      interval = (interval / 100.0).floorToDouble() * 100.0;
    }else if(interval > 10.0){
      interval = (interval / 10.0).floorToDouble() * 10.0;
    }

    double miterInterval = lastPoint.dx / interval;
    double hInterval = size.width / miterInterval;

//    if(interval >= 100.0){
//      if(size.width - hInterval * 6.0 > hInterval){
//        interval +=100.0;
//      }
//    }else if(interval > 10.0){
//      if(size.width - hInterval * 6.0 > hInterval){
//        interval +=10.0;
//      }
//    }
//
//    miterInterval = lastPoint.dx / interval;
//    hInterval = size.width / miterInterval;
//    print('miterInterval = $miterInterval; hInterval = $hInterval');

    canvas.save();
    canvas.translate(0.0, size.height + 2);
    for (int i = 0; i <= 6; i++) {
      drawHorizontalAxisLine(
        canvas,
        size,
        "${(i * interval).floor()}",
        i * hInterval * _scale,
      );
      canvas.drawCircle(Offset(i * hInterval* _scale, 0.0), 2.0, _signPointPaint);
    }
    canvas.restore();
  }

  /// 绘制数轴的一行
  void drawHorizontalAxisLine(Canvas canvas, Size size, String text, double width) {
    var tp = newVerticalAxisTextPainter(text)..layout();

    // 绘制虚线右边的Text
    // Text的绘制起始点 = 可用宽度 - 文字宽度 - 左边距
    var textLeft = width + tp.width / -2;
    tp.paint(canvas, Offset(textLeft, 0.0));
  }

  /// =========== 绘制海拔图连线部分

  /// 绘制海拔图连线部分
  void drawLines(Size size, Canvas canvas) {
    var pointList = _elevationPointList;
    if (pointList == null || pointList.isEmpty) return;

    double ratioX = size.width * 1.0 / pointList.last.point.dx; //  * scale
    double ratioY = size.height / maxVerticalAxisValue;

    var firstPoint = pointList.first.point;
    var path = Path();
    path.moveTo(firstPoint.dx * ratioX, size.height - firstPoint.dy * ratioY);
    for (var p in pointList) {
      path.lineTo(p.point.dx * ratioX, size.height - p.point.dy * ratioY);
    }

    // 绘制线条下面的渐变部分
    drawGradualShadow(path, size, canvas);

    // 先绘制渐变再绘制线,避免线被遮挡住
    canvas.save();
    canvas.drawPath(path, _linePaint);
    canvas.restore();

    // 绘制关键点及文字
    canvas.save();
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
      _signPointPaint.color = p.color;
      canvas.drawCircle(
          Offset(p.point.dx * ratioX, size.height - p.point.dy * ratioY), 2.0, _signPointPaint);

      var left = p.point.dx * ratioX - tp.width / 2;

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
          _signPointPaint);

      // 绘制文字
      tp.paint(canvas, Offset(left, size.height - p.point.dy * ratioY - tp.height - 6));
    }

    canvas.restore();
  }

  void drawGradualShadow(Path path, Size size, Canvas canvas) {
    var gradualPath = Path();
    gradualPath.addPath(path, Offset.zero);
    gradualPath.lineTo(gradualPath.getBounds().width, size.height);
    gradualPath.relativeLineTo(-gradualPath.getBounds().width, 0.0);

    _gradualPaint.shader = ui.Gradient.linear(
        Offset(0.0, 300.0), Offset(0.0, size.height), [Color(0x821E88E5), Color(0x0C1E88E5)]);

    canvas.save();
    canvas.drawPath(gradualPath, _gradualPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
