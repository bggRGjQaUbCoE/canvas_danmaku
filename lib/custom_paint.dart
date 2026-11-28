// ignore_for_file: unused_element_parameter

part of 'danmaku_screen.dart';

typedef _LayoutCallback = void Function(Size size);

class _CustomPaint extends CustomPaint {
  const _CustomPaint({
    super.key,
    super.painter,
    super.foregroundPainter,
    super.size,
    super.isComplex,
    super.willChange,
    super.child,
    required this.layoutCallback,
  });

  final _LayoutCallback layoutCallback;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return _RenderCustomPaint(
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
      layoutCallback: layoutCallback,
    );
  }
}

class _RenderCustomPaint extends RenderCustomPaint {
  _RenderCustomPaint({
    super.painter,
    super.foregroundPainter,
    super.preferredSize,
    super.isComplex,
    super.willChange,
    super.child,
    required this._layoutCallback,
  });

  final _LayoutCallback _layoutCallback;

  @override
  void performLayout() {
    final constraints = this.constraints;
    final biggest = constraints.biggest;
    if (constraints is VideoBoxConstraints) {
      final videoSize = Size(
        constraints.maxWidth,
        constraints.videoHeight,
      );
      _layoutCallback(videoSize);
    } else {
      _layoutCallback(biggest);
    }
    size = biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + const Offset(0.0, 4.0));
  }

  @override
  bool hitTestChildren(_, {required Offset position}) => false;

  @override
  bool hitTestSelf(Offset position) => false;
}
