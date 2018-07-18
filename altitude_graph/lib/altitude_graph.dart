import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AltitudePoint {
  String name;

  int level;

  Offset point;

  Color color;

  TextPainter textPainter;

  AltitudePoint(this.name, this.level, this.point, this.color, {this.textPainter}) {
    if (name == null || name.isEmpty || textPainter != null) return;

    // 向String插入换行符使文字竖向绘制
    // TODO 这种写法应该是不正确的, 暂时不知道更好的方式
    var splitMapJoin = name.splitMapJoin('', onNonMatch: (m) {
      return m.isNotEmpty ? "$m\n" : "";
    });
    splitMapJoin = splitMapJoin.substring(0, splitMapJoin.length - 1);

    this.textPainter = TextPainter(
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
  }
}

class AltitudeGraphView extends StatefulWidget {
  final List<AltitudePoint> altitudePointList;
  final double maxScale;
  final Color axisLineColor;
  final Color axisTextColor;
  final Color pathColor;
  final List<Color> gradientColors;
  final bool slidingBarVisible;
  final Widget leftSlidingButton;
  final Widget rightSlidingButton;
  final Animation<double> animation;

  AltitudeGraphView(
    this.altitudePointList, {
    this.maxScale = 1.0,
    this.axisLineColor = Colors.amber,
    this.axisTextColor = Colors.black,
    this.pathColor = Colors.amber,
    this.gradientColors = const [Color(0x821E88E5), Color(0x0C1E88E5)],
    this.slidingBarVisible = true,
    this.leftSlidingButton = const Icon(Icons.chevron_left),
    this.rightSlidingButton = const Icon(Icons.chevron_right),
    this.animation,
  });

  @override
  AltitudeGraphViewState createState() => new AltitudeGraphViewState();
}

const double SLIDING_BTN_WIDTH = 30.0;

class AltitudeGraphViewState extends State<AltitudeGraphView> with SingleTickerProviderStateMixin {
  // 海拔图数据
  int _maxLevel = 0;
  int _minLevel = 0;
  double _maxElevation = 0.0;
  double _minElevation = 0.0;
  double _elevationInterval = 0.0;

  // 放大/和放大的基点的值. 在动画/手势中会实时变化
  double _scale = 1.0;
  Offset _position = Offset.zero;

  // ==== 辅助动画/手势的计算
  Offset _focusPoint;

  // ==== 上次放大的比例, 用于帮助下次放大操作时放大的速度保持一致.
  double _lastScaleValue = 1.0;
  Offset _lastUpdateFocalPoint = Offset.zero;

  // ==== 缩放滑钮
  double _leftSlidingBtnLeft = 0.0;
  double _lastLeftSlidingBtnLeft = 0.0;
  double _rightSlidingBtnRight = 0.0;
  double _lastRightSlidingBtnRight = 0.0;
  double _slidingBarLeft = SLIDING_BTN_WIDTH;
  double _slidingBarRight = SLIDING_BTN_WIDTH;
  double _lastSlidingBarPosition = 0.0;

  double _lastScale4ReverseAnimation = 1.0;
  AnimationStatus status;

  @override
  void initState() {
    super.initState();

    _initData();

    widget.animation?.addListener(_refresh);
    widget.animation?.addStatusListener((AnimationStatus s) {
      status = s;
      if (s == AnimationStatus.reverse) {
        _lastScale4ReverseAnimation = _scale;
      }
    });
  }

  @override
  void didUpdateWidget(AltitudeGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _initData();

    oldWidget.animation?.removeListener(_refresh);
    widget.animation?.addListener(_refresh);

    // todo 如果当前缩放大于新的最大缩放, 则调整缩放
    setState(() {
      _scale = 1.0;
      _position = Offset(0.0, 0.0);
      _leftSlidingBtnLeft = 0.0;
      _rightSlidingBtnRight = 0.0;
      _slidingBarLeft = SLIDING_BTN_WIDTH;
      _slidingBarRight = SLIDING_BTN_WIDTH;
    });
  }

  _refresh() {
    if (status != AnimationStatus.reverse) {
      setState(() {});
      return;
    }

    var widgetWidth = context.size.width;

    var value = widget.animation?.value?.clamp(0.0, 1.0) ?? 1.0;
    var newScale = (_lastScale4ReverseAnimation - 1.0) * value + 1.0;

    double left = _calculatePosition(newScale, widgetWidth / 2);

    // 将x范围限制图表宽度内
    double newPositionX = left.clamp((newScale - 1) * -widgetWidth, 0.0);
    var newPosition = Offset(newPositionX, 0.0);

    // 根据缩放,同步缩略滑钮的状态
    var maxViewportWidth = widgetWidth - SLIDING_BTN_WIDTH * 2;
    double lOffsetX = -newPositionX / newScale;
    double rOffsetX = ((newScale - 1) * widgetWidth + newPositionX) / newScale;

    double r = maxViewportWidth / widgetWidth;
    lOffsetX *= r;
    rOffsetX *= r;

    setState(() {
      _scale = newScale;
      _position = newPosition;
      _leftSlidingBtnLeft = lOffsetX;
      _rightSlidingBtnRight = rOffsetX;
      _slidingBarLeft = lOffsetX + SLIDING_BTN_WIDTH;
      _slidingBarRight = rOffsetX + SLIDING_BTN_WIDTH;
    });
  }

  /// 遍历数据, 取得 最高海拔值, 最低海拔值, 最高Level, 最低Level.
  /// 根据最高海拔值和最低海拔值计算出纵轴最大值和最小值.
  _initData() {
    if (widget.altitudePointList?.isEmpty ?? true) return;

    var firstPoint = widget.altitudePointList.first.point;
    _maxElevation = firstPoint.dy;
    _minElevation = firstPoint.dy;
    for (AltitudePoint p in widget.altitudePointList) {
      if (p.point.dy > _maxElevation) {
        _maxElevation = p.point.dy;
      } else if (p.point.dy < _minElevation) {
        _minElevation = p.point.dy;
      }
      if (p.level > _maxLevel) {
        _maxLevel = p.level;
      } else if (p.level < _minLevel) {
        _minLevel = p.level;
      }
    }

    var absMaxElevation = _maxElevation.abs();
    if (absMaxElevation > 1000) {
      _maxElevation = (_maxElevation / 1000.0).ceil() * 1000.0;
      _minElevation = (_minElevation / 1000.0).floor() * 1000.0;
    } else if (absMaxElevation > 100) {
      _maxElevation = (_maxElevation / 100.0).ceil() * 100.0;
      _minElevation = (_minElevation / 100.0).floor() * 100.0;
    } else if (absMaxElevation > 10) {
      _maxElevation = (_maxElevation / 10.0).ceil() * 10.0;
      _minElevation = (_minElevation / 10.0).floor() * 10.0;
    }

    _elevationInterval = (_maxElevation - _minElevation) / 5;
    var absElevationInterval = _elevationInterval.abs();
    if (absElevationInterval > 1000) {
      _elevationInterval = (_elevationInterval / 1000.0).floor() * 1000.0;
    } else if (absElevationInterval > 100) {
      _elevationInterval = (_elevationInterval / 100.0).floor() * 100.0;
    } else if (absElevationInterval > 10) {
      _elevationInterval = (_elevationInterval / 10.0).floor() * 10.0;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  painter: AltitudePainter(
                    widget.altitudePointList,
                    _maxElevation,
                    _minElevation,
                    _elevationInterval,
                    _scale,
                    widget.maxScale,
                    _position,
                    animatedValue: widget.animation?.value ?? 1.0,
                    maxLevel: _maxLevel,
                    minLevel: _minLevel,
                    axisLineColor: widget.axisLineColor,
                    axisTextColor: Colors.black,
                    gradientColors: const [Color(0x821E88E5), Color(0x0C1E88E5)],
                    pathColor: const Color(0xFF003c60),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 48.0,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.black26))),
            child: Stack(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.only(left: SLIDING_BTN_WIDTH, right: SLIDING_BTN_WIDTH),
                  child: CustomPaint(
                    painter: AltitudeThumbPainter(
                      widget.altitudePointList,
                      _maxElevation,
                      _minElevation,
                      animatedValue: widget.animation?.value ?? 1.0,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: EdgeInsets.only(left: _slidingBarLeft, right: _slidingBarRight),
                  child: GestureDetector(
                    onHorizontalDragStart: _onSlidingBarHorizontalDragStart,
                    onHorizontalDragUpdate: _onSlidingBarHorizontalDragUpdate,
                    onHorizontalDragEnd: _onSlidingBarHorizontalDragEnd,
                  ),
                ),
                Container(
                  width: SLIDING_BTN_WIDTH + _leftSlidingBtnLeft,
                  height: double.infinity,
                  padding: EdgeInsets.only(left: _leftSlidingBtnLeft),
                  color: Colors.black12,
                  child: GestureDetector(
                    onHorizontalDragStart: _onLBHorizontalDragDown,
                    onHorizontalDragUpdate: _onLBHorizontalDragUpdate,
                    onHorizontalDragEnd: _onLBHorizontalDragEnd,
                    child: Container(
                      height: double.infinity,
                      width: SLIDING_BTN_WIDTH,
                      color: Colors.black54.withAlpha(100),
                      child: Icon(Icons.chevron_left),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: SLIDING_BTN_WIDTH + _rightSlidingBtnRight,
                    padding: EdgeInsets.only(right: _rightSlidingBtnRight),
                    height: double.infinity,
                    color: Colors.black12,
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onHorizontalDragStart: _onRBHorizontalDragDown,
                      onHorizontalDragUpdate: _onRBHorizontalDragUpdate,
                      onHorizontalDragEnd: _onRBHorizontalDragEnd,
                      child: Container(
                        height: double.infinity,
                        width: SLIDING_BTN_WIDTH,
                        color: Colors.black54.withAlpha(100),
                        child: Icon(Icons.chevron_right),
                      ),
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
    var widgetWidth = context.size.width;
    double newScale = (_lastScaleValue * details.scale);

    if (newScale < 1.0) {
      newScale = 1.0;
    } else if (newScale > widget.maxScale) {
      newScale = widget.maxScale;
    }

    double left = _calculatePosition(newScale, _focusPoint.dx);

    // 加上水平拖动的偏移量
    var deltaPosition = (details.focalPoint - _lastUpdateFocalPoint);
    _lastUpdateFocalPoint = details.focalPoint;
    left += deltaPosition.dx;

    // 将x范围限制图表宽度内
    double newPositionX = left.clamp((newScale - 1) * -widgetWidth, 0.0);
    var newPosition = Offset(newPositionX, 0.0);

    // 根据缩放,同步缩略滑钮的状态
    var maxViewportWidth = widgetWidth - SLIDING_BTN_WIDTH * 2;
    double lOffsetX = -newPositionX / newScale;
    double rOffsetX = ((newScale - 1) * widgetWidth + newPositionX) / newScale;

    double r = maxViewportWidth / widgetWidth;
    lOffsetX *= r;
    rOffsetX *= r;

    setState(() {
      _scale = newScale;
      _position = newPosition;
      _leftSlidingBtnLeft = lOffsetX;
      _rightSlidingBtnRight = rOffsetX;
      _slidingBarLeft = lOffsetX + SLIDING_BTN_WIDTH;
      _slidingBarRight = rOffsetX + SLIDING_BTN_WIDTH;
    });
  }

  _onScaleEnd(ScaleEndDetails details) {}

  // =========== 左边按钮的滑动操作

  _onLBHorizontalDragDown(DragStartDetails details) {
    _lastLeftSlidingBtnLeft = details.globalPosition.dx;
  }

  _onLBHorizontalDragUpdate(DragUpdateDetails details) {
    var widgetWidth = context.size.width;
    var maxViewportWidth = widgetWidth - SLIDING_BTN_WIDTH * 2;

    var deltaX = details.globalPosition.dx - _lastLeftSlidingBtnLeft;
    _lastLeftSlidingBtnLeft = details.globalPosition.dx;
    double newLOffsetX = _leftSlidingBtnLeft + deltaX;

    // 根据最大缩放倍数, 限制滑动的最大距离.
    // Viewport: 窗口指的是两个滑块(不含滑块自身)中间的内容, 即左滑钮的右边到右滑钮的左边的距离.
    // 最大窗口宽 / 最大倍数 = 最小的窗口宽.
    double minViewportWidth = maxViewportWidth / widget.maxScale;
    // 最大窗口宽 - 最小窗口宽 - 当前右边的偏移量 = 当前左边的最大偏移量
    double maxLeft = maxViewportWidth - minViewportWidth - _rightSlidingBtnRight;
    newLOffsetX = newLOffsetX.clamp(0.0, maxLeft);

    // 得到当前的窗口大小
    double viewportWidth = maxViewportWidth - newLOffsetX - _rightSlidingBtnRight;
    // 最大窗口大小 / 当前窗口大小 = 应该缩放的倍数
    double newScale = maxViewportWidth / viewportWidth;
    // 计算缩放后的左偏移量
    double newPositionX = _calculatePosition(newScale, widgetWidth);

    var newPosition = Offset(newPositionX, 0.0);

    setState(() {
      _leftSlidingBtnLeft = newLOffsetX;
      _scale = newScale;
      _position = newPosition;
      _slidingBarLeft = newLOffsetX + SLIDING_BTN_WIDTH;
    });
  }

  _onLBHorizontalDragEnd(DragEndDetails details) {}

  // =========== 右边按钮的滑动操作

  _onRBHorizontalDragDown(DragStartDetails details) {
    _lastRightSlidingBtnRight = details.globalPosition.dx;
  }

  _onRBHorizontalDragUpdate(DragUpdateDetails details) {
    var widgetWidth = context.size.width;
    var maxViewportWidth = widgetWidth - SLIDING_BTN_WIDTH * 2;

    var deltaX = details.globalPosition.dx - _lastRightSlidingBtnRight;
    _lastRightSlidingBtnRight = details.globalPosition.dx;
    double newROffsetX = _rightSlidingBtnRight - deltaX;

    // 根据最大缩放倍数, 限制滑动的最大距离.
    // Viewport: 窗口指的是两个滑块(不含滑块自身)中间的内容, 即左滑钮的右边到右滑钮的左边的距离.
    // 最大窗口宽 / 最大倍数 = 最小的窗口宽.
    double minViewportWidth = maxViewportWidth / widget.maxScale;
    // 最大窗口宽 - 最小窗口宽 - 当前右边的偏移量 = 当前左边的最大偏移量
    double maxLeft = maxViewportWidth - minViewportWidth - _leftSlidingBtnLeft;
    newROffsetX = newROffsetX.clamp(0.0, maxLeft);

    // 得到当前的窗口大小
    double viewportWidth = maxViewportWidth - _leftSlidingBtnLeft - newROffsetX;
    // 最大窗口大小 / 当前窗口大小 = 应该缩放的倍数
    double newScale = maxViewportWidth / viewportWidth;
    // 计算缩放后的左偏移量
    double newPositionX = _calculatePosition(newScale, 0.0);

    var newPosition = Offset(newPositionX, 0.0);

    setState(() {
      _rightSlidingBtnRight = newROffsetX;
      _scale = newScale;
      _position = newPosition;
      _slidingBarRight = newROffsetX + SLIDING_BTN_WIDTH;
    });
  }

  _onRBHorizontalDragEnd(DragEndDetails details) {}

  // =========== 右边按钮的滑动操作

  _onSlidingBarHorizontalDragStart(DragStartDetails details) {
    _lastSlidingBarPosition = details.globalPosition.dx;
  }

  _onSlidingBarHorizontalDragUpdate(DragUpdateDetails details) {
    var widgetWidth = context.size.width;

    // 得到本次滑动的偏移量, 乘倍数后和之前的偏移量相减等于新的偏移量
    var deltaPositionX = (details.globalPosition.dx - _lastSlidingBarPosition);
    _lastSlidingBarPosition = details.globalPosition.dx;
    double left = _position.dx - deltaPositionX * _scale;

    // 将x范围限制图表宽度内
    double newPositionX = left.clamp((_scale - 1) * -widgetWidth, 0.0);
    var newPosition = Offset(newPositionX, 0.0);

    // 同步缩略滑钮的状态
    var maxViewportWidth = widgetWidth - SLIDING_BTN_WIDTH * 2;
    double lOffsetX = -newPositionX / _scale;
    double rOffsetX = ((_scale - 1) * widgetWidth + newPositionX) / _scale;

    double r = maxViewportWidth / widgetWidth;
    lOffsetX *= r;
    rOffsetX *= r;

    setState(() {
      _position = newPosition;
      _leftSlidingBtnLeft = lOffsetX;
      _rightSlidingBtnRight = rOffsetX;
      _slidingBarLeft = lOffsetX + SLIDING_BTN_WIDTH;
      _slidingBarRight = rOffsetX + SLIDING_BTN_WIDTH;
    });
  }

  _onSlidingBarHorizontalDragEnd(DragEndDetails details) {}
}

const int VERTICAL_TEXT_WIDTH = 25;
const double DOTTED_LINE_WIDTH = 2.0;
const double DOTTED_LINE_INTERVAL = 2.0;

class AltitudePainter extends CustomPainter {
  // ===== Data
  List<AltitudePoint> _altitudePointList;

  int maxLevel;
  int minLevel;

  double _maxVerticalAxisValue;
  double _minVerticalAxisValue;
  double _verticalAxisInterval;

  double _scale = 1.0;
  double _maxScale = 1.0;
  Offset _offset = Offset.zero;

  double animatedValue;

  // ===== Paint
  // 海拔线的画笔
  Paint _linePaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  // 海拔线填充的画笔
  Paint _gradualPaint = Paint()
    ..isAntiAlias = false
    ..style = PaintingStyle.fill;

  // 关键点的画笔
  Paint _signPointPaint = Paint();

  // 竖轴水平虚线的画笔
  Paint _levelLinePaint = Paint()
    ..strokeWidth = 1.0
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke;

  // 文字颜色
  Color axisTextColor;

  // 海拔线填充的梯度颜色
  List<Color> gradientColors;

  AltitudePainter(
    this._altitudePointList,
    this._maxVerticalAxisValue,
    this._minVerticalAxisValue,
    this._verticalAxisInterval,
    this._scale,
    this._maxScale,
    this._offset, {
    this.animatedValue = 1.0,
    this.maxLevel = 0,
    this.minLevel = 0,
    this.axisTextColor = Colors.black,
    this.gradientColors = const [Color(0x821E88E5), Color(0x0C1E88E5)],
    Color pathColor = const Color(0xFF003c60),
    Color axisLineColor = Colors.amber,
  }) {
    _linePaint.color = pathColor;
    _levelLinePaint.color = axisLineColor;
  }

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

    var levelCount = (_maxVerticalAxisValue - _minVerticalAxisValue) / _verticalAxisInterval;
    var labelCount = _maxVerticalAxisValue / _verticalAxisInterval;

    var interval = availableHeight / levelCount;

    canvas.save();
    for (int i = 0; i <= levelCount; i++) {
      var label = (_verticalAxisInterval * (labelCount - i)).toInt();
      drawVerticalAxisLine(canvas, size, label.toString(), i * interval);
    }
    canvas.restore();
  }

  /// 绘制数轴的一行
  void drawVerticalAxisLine(Canvas canvas, Size size, String text, double height) {
    var tp = newVerticalAxisTextPainter(text)..layout();

    // 绘制虚线
    // 虚线的宽度 = 可用宽度 - 文字宽度 - 文字宽度的左右边距
    var dottedLineWidth = size.width - VERTICAL_TEXT_WIDTH;
    _levelLinePaint.color = _levelLinePaint.color.withOpacity(animatedValue.clamp(0.0, 1.0));
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
          color: axisTextColor.withOpacity(animatedValue.clamp(0.0, 1.0)),
          fontSize: 8.0,
        ),
      ),
    );
  }

  void drawHorizontalAxis(Canvas canvas, Size size, double totalWidth) {
    Offset lastPoint = _altitudePointList?.last?.point;
    if (lastPoint == null) return;

    double ratio = size.width / totalWidth;
    double a = _altitudePointList.last.point.dx * ratio;
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
    var pointList = _altitudePointList;
    if (pointList == null || pointList.isEmpty) return;

    // 将原点挪到以纵坐标的0点所在的位置, 向下为负, 向上为正. 这样可以绘制出负海拔的区域
    double maxValue = _maxVerticalAxisValue - _minVerticalAxisValue;
    double h = size.height;

    double ratioX = size.width * 1.0 / pointList.last.point.dx; //  * scale
    double ratioY = h / maxValue;

    var firstPoint = pointList.first.point;
    var path = Path();

    var calculateDy = (double dy) {
      return h - (dy - _minVerticalAxisValue) * ratioY * animatedValue;
    };

    path.moveTo(firstPoint.dx * ratioX, calculateDy(firstPoint.dy));
    for (var p in pointList) {
      path.lineTo(p.point.dx * ratioX, calculateDy(p.point.dy));
    }

    // 绘制线条下面的渐变部分
    drawGradualShadow(path, size, canvas);

    // 先绘制渐变再绘制线,避免线被遮挡住
    canvas.save();
    canvas.drawPath(path, _linePaint);
    canvas.restore();

    drawLabel(canvas, h, pointList, ratioX, ratioY);
  }

  void drawGradualShadow(Path path, Size size, Canvas canvas) {
    var gradualPath = Path();
    gradualPath.addPath(path, Offset.zero);
    gradualPath.lineTo(gradualPath.getBounds().width, size.height);
    gradualPath.relativeLineTo(-gradualPath.getBounds().width, 0.0);

    _gradualPaint.shader =
        ui.Gradient.linear(Offset(0.0, 300.0), Offset(0.0, size.height), gradientColors);

    canvas.save();
    canvas.drawPath(gradualPath, _gradualPaint);
    canvas.restore();
  }

  void drawLabel(
      Canvas canvas, double h, List<AltitudePoint> pointList, double ratioX, double ratioY) {
    // 绘制关键点及文字
    canvas.save();
    canvas.translate(0.0, h);
    double ratioInScaling = _scale / _maxScale * 10.0;
    for (var p in pointList) {
      if (p.name == null || p.name.isEmpty) continue;

      // maxLevel
      double levelLimit = (maxLevel - minLevel) - ratioInScaling * (maxLevel - minLevel);
      if (p.level < levelLimit) continue;

      double labelScale = p.level - levelLimit;
      labelScale = (labelScale * 3.0).clamp(0.0, 1.0);
      // 让Label在跟随动画显示/隐藏, max() 避免为0导致1.0/0报错
      labelScale = max(labelScale * animatedValue, 0.01);

      // 由于我们不能直接缩放文字的字号, 所以我们采用缩放canvas的方式
      // canvas缩小后, 面积会增大, 绘制的位置就会变化.
      // 为了让绘制的点还是在原来的位置, 我们将 ratioX/Y 的值放大 n 倍(n取决于我们将canvas缩小了多少)
      // 举例: 默认canvas是300 * 500, labelScale=0.5时canvas=600*1000.
      // 因此我们将 ratioX/Y 放大2倍 (通过 1/0.5 得到), 这样计算偏移量时就能对应上海拔路径的点了.
      canvas.save();
      canvas.scale(labelScale);
      double scale4Offset = (1.0 / labelScale);
      double scaledRatioX = ratioX * scale4Offset;
      double scaledRatioY = ratioY * scale4Offset;

      // 将海拔的值换算成在屏幕上的值
      double yInScreen = (p.point.dy - _minVerticalAxisValue) * scaledRatioY * animatedValue;

      // ==== 绘制关键点
      _signPointPaint.color = p.color;
      canvas.drawCircle(Offset(p.point.dx * scaledRatioX, -yInScreen), 2.0, _signPointPaint);

      // ==== 绘制文字及背景

      var tp = p.textPainter;
      var left = p.point.dx * scaledRatioX - tp.width / 2;

      // 如果label接近顶端, 调换方向, 避免label看不见
      double bgTop = yInScreen + tp.height + 8;
      double bgBottom = yInScreen + 4;
      double textTop = yInScreen + tp.height + 6;
      if (h * scale4Offset - bgTop < 0) {
        bgTop = yInScreen - tp.height - 8;
        bgBottom = yInScreen - 4;
        textTop = yInScreen - 6;
      }
      // 绘制文字的背景框
      canvas.drawRRect(
          RRect.fromLTRBXY(
            left - 2,
            -bgTop,
            left + tp.width + 2,
            -bgBottom,
            tp.width / 2.0,
            tp.width / 2.0,
          ),
          _signPointPaint);

      // 绘制文字
      tp.paint(canvas, Offset(left, -textTop));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AltitudeThumbPainter extends CustomPainter {
  // ===== Data
  List<AltitudePoint> _altitudePointList;

  double _maxVerticalAxisValue;
  double _minVerticalAxisValue;

  // ===== Paint
  Paint _linePaint = Paint()
    ..color = Colors.grey
    ..isAntiAlias = false
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  Paint _gradualPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = false
    ..color = Colors.grey.shade300;

  double _maxGradualPaintColorOpacity = Colors.grey.shade300.opacity;

  double animatedValue;

  AltitudeThumbPainter(
    this._altitudePointList,
    this._maxVerticalAxisValue,
    this._minVerticalAxisValue, {
    this.animatedValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    drawLines(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  /// =========== 绘制海拔图连线部分

  /// 绘制海拔图连线部分
  void drawLines(Canvas canvas, Size size) {
    var pointList = _altitudePointList;
    if (pointList == null || pointList.isEmpty) return;

    // 将原点挪到以纵坐标的0点所在的位置, 向下为负, 向上为正. 这样可以绘制出负海拔的区域
    double ratioAtAll = _minVerticalAxisValue / (_maxVerticalAxisValue - _minVerticalAxisValue);
    double h = size.height + ratioAtAll * size.height;

    double ratioX = size.width * 1.0 / pointList.last.point.dx; //  * scale
    double ratioY = h / _maxVerticalAxisValue;

    var firstPoint = pointList.first.point;
    var path = Path();
    path.moveTo(firstPoint.dx * ratioX, h - firstPoint.dy * ratioY);
    for (var p in pointList) {
      path.lineTo(p.point.dx * ratioX, h - p.point.dy * ratioY);
    }

    // 绘制线条下面的渐变部分
    drawGradualShadow(path, size, canvas);

    // 先绘制渐变再绘制线,避免线被遮挡住
    canvas.save();
    _linePaint.color = _linePaint.color.withOpacity(animatedValue.clamp(0.0, 1.0));
    canvas.drawPath(path, _linePaint);
    canvas.restore();
  }

  void drawGradualShadow(Path path, Size size, Canvas canvas) {
    var gradualPath = Path();
    gradualPath.addPath(path, Offset.zero);
    gradualPath.lineTo(gradualPath.getBounds().width, size.height);
    gradualPath.relativeLineTo(-gradualPath.getBounds().width, 0.0);

    canvas.save();
    var opacity = (_maxGradualPaintColorOpacity * animatedValue).clamp(0.0, 1.0);
    _gradualPaint.color = _linePaint.color.withOpacity(opacity);
    canvas.drawPath(gradualPath, _gradualPaint);
    canvas.restore();
  }
}
