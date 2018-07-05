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

const double SLIDING_BTN_WIDTH = 30.0;

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

  // ==== 缩放滑钮
  bool _sizeInitialed = false;
  double _lOffsetX = 0.0;
  double _lastLOffsetX = 0.0;
  double _rOffsetX = 0.0;
  double _lastROffsetX = 0.0;

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
    if (!_sizeInitialed) {
      var bound = context?.findRenderObject()?.semanticBounds;
      if (bound != null) {
        _sizeInitialed = true;
        _rOffsetX = bound.width - SLIDING_BTN_WIDTH;
      }
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
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
            ),
          ),
          Container(
            width: double.infinity,
            color: Colors.deepOrange,
            child: Stack(
              children: <Widget>[
                Transform(
                  transform: Matrix4.translationValues(_lOffsetX, 0.0, 0.0),
                  child: Container(
                    width: SLIDING_BTN_WIDTH,
                    height: 48.0,
                    color: Colors.teal,
                    child: GestureDetector(
                      onHorizontalDragStart: _onLBHorizontalDragDown,
                      onHorizontalDragUpdate: _onLBHorizontalDragUpdate,
                      onHorizontalDragEnd: _onLBHorizontalDragEnd,
                      child: Icon(Icons.chevron_left),
                    ),
                  ),
                ),
                Transform(
                  transform: Matrix4.translationValues(_rOffsetX, 0.0, 0.0),
                  child: Container(
                    width: SLIDING_BTN_WIDTH,
                    height: 48.0,
                    color: Colors.teal,
                    child: GestureDetector(
                      onHorizontalDragStart: _onRBHorizontalDragDown,
                      onHorizontalDragUpdate: _onRBHorizontalDragUpdate,
                      onHorizontalDragEnd: _onRBHorizontalDragEnd,
                      child: Icon(Icons.chevron_right),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// 计算偏移量, 默认放大时都是向右偏移的, 因此想在放大时保持比例, 就需要将缩放点移至0点
  /// 算法: 左偏移量L = 当前焦点f在之前图宽上的位置p带入到新图宽中再减去焦点f在屏幕上的位置
  double _calculatePosition(double newScale, double focusOnScreen) {
    // ratioInGraph 就是当前的焦点实际对应在之前的图宽上的比例
    var widgetWidth = context.size.width;
    double ratioInGraph = (_position.dx.abs() + focusOnScreen) / (_scale * widgetWidth);
    // 现在新计算出的图宽
    double newTotalWidth = newScale * widgetWidth;
    // 将之前的比例带入当前的图宽即为焦点在新图上的位置
    double newLocationInGraph = ratioInGraph * newTotalWidth;
    // 最后用焦点在屏幕上的位置 - 在图上的位置就是图应该向左偏移的位置
    return focusOnScreen - newLocationInGraph;
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

    double left = _calculatePosition(newScale, _focusPoint.dx);

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

  // =========== 左边按钮的滑动操作

  _onLBHorizontalDragDown(DragStartDetails details) {
    _lastLOffsetX = details.globalPosition.dx;
  }

  _onLBHorizontalDragUpdate(DragUpdateDetails details) {
    var widgetWidth = context.size.width;

    var deltaX = details.globalPosition.dx - _lastLOffsetX;
    _lastLOffsetX = details.globalPosition.dx;
    double newLOffsetX = _lOffsetX + deltaX;
    newLOffsetX = newLOffsetX.clamp(0.0, _rOffsetX - SLIDING_BTN_WIDTH);

    double ratio = (newLOffsetX + (widgetWidth - _rOffsetX - SLIDING_BTN_WIDTH)) / (widgetWidth - 60.0);
    double newScale = ratio * _maxScale + 1;

    double left = _calculatePosition(newScale, widgetWidth);

    // 将x范围限制图表宽度内
    var lower = (newScale - 1) * -widgetWidth;
    double clampedX = left.clamp(min(0.0, lower), 0.0);
    var newPosition = Offset(clampedX, 0.0);

    setState(() {
      _lOffsetX = newLOffsetX;
      _scale = newScale;
      _position = newPosition;
    });
  }

  _onLBHorizontalDragEnd(DragEndDetails details) {}

  // =========== 右边按钮的滑动操作

  _onRBHorizontalDragDown(DragStartDetails details) {
    _lastROffsetX = details.globalPosition.dx;
  }

  _onRBHorizontalDragUpdate(DragUpdateDetails details) {
    var widgetWidth = context.size.width;

    var deltaX = details.globalPosition.dx - _lastROffsetX;
    _lastROffsetX = details.globalPosition.dx;
    double newROffsetX = _rOffsetX + deltaX;
    newROffsetX = newROffsetX.clamp(_lOffsetX + SLIDING_BTN_WIDTH, widgetWidth - SLIDING_BTN_WIDTH);

    double ratio = (_lOffsetX + (widgetWidth - newROffsetX - SLIDING_BTN_WIDTH)) / (widgetWidth - 60.0);
    double newScale = ratio * _maxScale + 1;

    double left = _calculatePosition(newScale, 0.0);

    // 将x范围限制图表宽度内
    var lower = (newScale - 1) * -widgetWidth;
    double clampedX = left.clamp(min(0.0, lower), 0.0);
    var newPosition = Offset(clampedX, 0.0);

    setState(() {
      _rOffsetX = newROffsetX;
      _scale = newScale;
      _position = newPosition;
    });
  }

  _onRBHorizontalDragEnd(DragEndDetails details) {}
}

const int VERTICAL_TEXT_WIDTH = 25;
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
    // 30是给上下留出的距离, 这样竖轴的最顶端的字就不会被截断, 下方可以用来显示横轴的字
    Size availableSize = Size(size.width, size.height - 30.0);
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(size.width, size.height)));
    // 向下滚动15的距离给顶部留出空间
    canvas.translate(0.0, 15.0);

    // 绘制竖轴
    drawVerticalAxis(canvas, availableSize);

    // 绘制线图
    // 50是给左右留出间距, 避免标签上的文字被截断, 同时避免线图覆盖竖轴的字
    Size lineSize = Size(availableSize.width * _scale - 50, availableSize.height);
    canvas.save();
    // 剪裁绘制的窗口, 避免覆盖竖轴 同时节省绘制的开销
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(availableSize.width - 24, size.height)));
    // _offset.dx通常都是些向左偏移的量 +15 是为了避免出关键点标签的文字被截断
    canvas.translate(_offset.dx + 15, 0.0);
    drawLines(canvas, lineSize);
    canvas.restore();

    // 绘制横轴
    canvas.save();
    Size horizontalAxisSize = Size(availableSize.width - 20, availableSize.height);
    // 不需要避免竖轴被遮挡问题, 这一步是为了减少绘制时的开销.
    canvas.clipRect(Rect.fromPoints(Offset.zero, Offset(availableSize.width, size.height)));
    // x偏移和线图对应上, y偏移将绘制点挪到底部
    canvas.translate(_offset.dx + 15, horizontalAxisSize.height + 2);
    drawHorizontalAxis(canvas, horizontalAxisSize, lineSize.width);
    canvas.restore();
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
    var textLeft = size.width - tp.width - 3;
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

  void drawHorizontalAxis(Canvas canvas, Size size, double totalWidth) {
    Offset lastPoint = _elevationPointList?.last?.point;
    if (lastPoint == null) return;

    double ratio = size.width / totalWidth;
    double a = _elevationPointList.last.point.dx * ratio;
    double interval = a / 6.0;
    double miters;
    if (interval >= 100.0) {
      miters = (interval / 100.0).ceilToDouble() * 100;
    } else if (interval >= 10) {
      miters = (interval / 10.0).ceilToDouble() * 10;
    } else {
      miters = (interval / 5.0).ceilToDouble() * 5;
    }
    double r = miters / interval;
    double hInterval = size.width / 6.0 * r;

    double count = totalWidth / hInterval;
    for (int i = 0; i <= count; i++) {
      drawHorizontalAxisLine(
        canvas,
        size,
        "${i * miters.toInt()}",
        i * hInterval,
      );
    }
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
  void drawLines(Canvas canvas, Size size) {
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
            fontSize: 8.0,
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
            tp.width / 2.0,
            tp.width / 2.0,
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
