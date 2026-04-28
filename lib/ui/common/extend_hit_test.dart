import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ExpandHitTest extends StatelessWidget {
  const ExpandHitTest({
    super.key,
    required this.expandArea,
    required this.child,
  });

  final EdgeInsets expandArea;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: expandArea,
      child: _ExpandHitTestCore(expandArea: expandArea, child: child),
    );
  }
}

class _ExpandHitTestCore extends SingleChildRenderObjectWidget {
  const _ExpandHitTestCore({required this.expandArea, required super.child});

  final EdgeInsets expandArea;

  @override
  _ExpandHitTestRenderBox createRenderObject(BuildContext context) =>
      _ExpandHitTestRenderBox(expandArea: expandArea);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _ExpandHitTestRenderBox renderObject,
  ) {
    renderObject.expandArea = expandArea;
  }
}

class _ExpandHitTestRenderBox extends RenderProxyBox {
  _ExpandHitTestRenderBox({required this.expandArea});

  EdgeInsets expandArea;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final expandedRect = expandArea.inflateRect(Offset.zero & size);
    if (!expandedRect.contains(position)) {
      return false;
    }
    final clampedPosition = Offset(
      position.dx.clamp(0.0, size.width),
      position.dy.clamp(0.0, size.height),
    );
    return hitTestChildren(result, position: clampedPosition) ||
        hitTestSelf(clampedPosition);
  }
}
