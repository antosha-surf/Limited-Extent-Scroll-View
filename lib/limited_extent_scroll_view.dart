import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

/// A scroll view that shrink wraps its children until [itemExtent],
/// after which point it starts to scroll.
///
/// No anchor and no center because the viewport is dynamically sized.
class LimitedExtentScrollView extends CustomScrollView {
  /// Creates an instance of [LimitedExtentScrollView].
  const LimitedExtentScrollView({
    required this.maxExtent,
    this.crossAxisDirection,
    this.cacheExtentStyle = CacheExtentStyle.pixel,
    super.controller,
    super.scrollDirection,
    super.reverse,
    super.primary,
    super.physics,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    super.hitTestBehavior,
    super.cacheExtent,
    super.semanticChildCount,
    super.scrollBehavior,
    super.slivers,
    super.key,
  }) : super(shrinkWrap: false, center: null, anchor: 0.0);

  /// The maximum extent of the scroll view.
  final double maxExtent;

  /// {@macro flutter.rendering.ShrinkWrappingViewport.crossAxisDirection}
  final AxisDirection? crossAxisDirection;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtentStyle}
  final CacheExtentStyle cacheExtentStyle;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    return LimitedExtentViewport(
      maxExtent: maxExtent,
      axisDirection: axisDirection,
      crossAxisDirection:
          crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
      clipBehavior: clipBehavior,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      slivers: slivers,
    );
  }
}

/// A viewport that grows until [itemExtent].
class LimitedExtentViewport extends MultiChildRenderObjectWidget {
  /// Creates an instance of [LimitedExtentViewport].
  const LimitedExtentViewport({
    required this.maxExtent,
    this.axisDirection = AxisDirection.down,
    this.crossAxisDirection,
    required this.offset,
    this.cacheExtent,
    this.cacheExtentStyle = CacheExtentStyle.pixel,
    this.clipBehavior = Clip.hardEdge,
    super.key,
    List<Widget> slivers = const <Widget>[],
  }) : assert(
         cacheExtentStyle != CacheExtentStyle.viewport || cacheExtent != null,
       ),
       super(children: slivers);

  /// The maximum extent of the scroll view.
  final double maxExtent;

  /// {@macro flutter.rendering.Viewport.axisDirection}
  final AxisDirection axisDirection;

  /// {@macro flutter.rendering.Viewport.crossAxisDirection}
  final AxisDirection? crossAxisDirection;

  /// {@macro flutter.rendering.Viewport.offset}
  final ViewportOffset offset;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  final double? cacheExtent;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtentStyle}
  final CacheExtentStyle cacheExtentStyle;

  /// {@macro flutter.material.Material.clipBehavior}
  final Clip clipBehavior;

  @override
  RenderLimitedExtentViewport createRenderObject(BuildContext context) {
    return RenderLimitedExtentViewport(
      maxExtent: maxExtent,
      axisDirection: axisDirection,
      crossAxisDirection:
          crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
      cacheExtent: cacheExtent,
      cacheExtentStyle: cacheExtentStyle,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderLimitedExtentViewport renderObject,
  ) {
    renderObject
      ..maxExtent = maxExtent
      ..axisDirection = axisDirection
      ..crossAxisDirection =
          crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior;
  }

  @override
  MultiChildRenderObjectElement createElement() =>
      _LimitedExtentViewportElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(
      EnumProperty<AxisDirection>(
        'crossAxisDirection',
        crossAxisDirection,
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
    properties.add(DiagnosticsProperty<double>('cacheExtent', cacheExtent));
    properties.add(
      DiagnosticsProperty<CacheExtentStyle>(
        'cacheExtentStyle',
        cacheExtentStyle,
      ),
    );
  }
}

class _LimitedExtentViewportElement extends MultiChildRenderObjectElement
    with NotifiableElementMixin, ViewportElementMixin {
  _LimitedExtentViewportElement(LimitedExtentViewport super.widget);

  @override
  RenderLimitedExtentViewport get renderObject =>
      super.renderObject as RenderLimitedExtentViewport;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children
        .where((Element e) {
          final RenderSliver renderSliver = e.renderObject! as RenderSliver;
          return renderSliver.geometry!.visible;
        })
        .forEach(visitor);
  }
}

/// A render object for a viewport that grows until [itemExtent].
class RenderLimitedExtentViewport
    extends RenderViewportBase<SliverLogicalContainerParentData> {
  RenderLimitedExtentViewport({
    required this.maxExtent,
    required super.crossAxisDirection,
    required super.offset,
    super.axisDirection,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior,
    List<RenderSliver>? children,
  }) {
    addAll(children);
  }

  /// The maximum extent of this viewport.
  double maxExtent;

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  // Out-of-band data computed during layout.
  late double _totalExtent;
  late double _contentMainAxisExtent;
  late bool _hasVisualOverflow;
  late double _calculatedCacheExtent;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverLogicalContainerParentData) {
      child.parentData = SliverLogicalContainerParentData();
    }
  }

  @override
  void performLayout() {
    assert(_debugCheckHasBoundedCrossAxis());

    final constraints = this.constraints;
    final crossAxisExtent = switch (axis) {
      Axis.vertical => constraints.maxWidth,
      Axis.horizontal => constraints.maxHeight,
    };

    double correction;
    double effectiveExtent;

    while (true) {
      correction = _attemptLayout(crossAxisExtent, offset.pixels);
      if (correction != 0.0) {
        offset.correctBy(correction);
        continue;
      }

      effectiveExtent = switch (axis) {
        Axis.vertical => constraints.constrainHeight(_totalExtent),
        Axis.horizontal => constraints.constrainWidth(_totalExtent),
      };

      final didAcceptViewportDimension = offset.applyViewportDimension(
        effectiveExtent,
      );
      final didAcceptContentDimension = offset.applyContentDimensions(
        0.0,
        math.max(0.0, _contentMainAxisExtent - _totalExtent),
      );

      if (didAcceptViewportDimension && didAcceptContentDimension) {
        break;
      }
    }

    size = switch (axis) {
      Axis.vertical => constraints.constrainDimensions(
        crossAxisExtent,
        effectiveExtent,
      ),
      Axis.horizontal => constraints.constrainDimensions(
        effectiveExtent,
        crossAxisExtent,
      ),
    };
  }

  double _attemptLayout(double crossAxisExtent, double correctedOffset) {
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);

    _totalExtent = 0.0;
    _contentMainAxisExtent = 0.0;
    _hasVisualOverflow = correctedOffset < 0.0;
    _calculatedCacheExtent = switch (cacheExtentStyle) {
      CacheExtentStyle.pixel => cacheExtent!,
      CacheExtentStyle.viewport => maxExtent * cacheExtent!,
    };

    return layoutChildSequence(
      child: firstChild,
      scrollOffset: math.max(0.0, correctedOffset),
      overlap: math.min(0.0, correctedOffset),
      layoutOffset: math.max(0.0, -correctedOffset),
      remainingPaintExtent: maxExtent + math.min(0.0, correctedOffset),
      mainAxisExtent: maxExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: maxExtent + 2 * _calculatedCacheExtent,
      cacheOrigin: -_calculatedCacheExtent,
    );
  }

  @override
  void updateOutOfBandData(
    GrowthDirection growthDirection,
    SliverGeometry childLayoutGeometry,
  ) {
    assert(growthDirection == GrowthDirection.forward);
    _contentMainAxisExtent += childLayoutGeometry.scrollExtent;
    _totalExtent = math.min(maxExtent, _contentMainAxisExtent);
    if (childLayoutGeometry.hasVisualOverflow) {
      _hasVisualOverflow = true;
    }
  }

  @override
  void updateChildLayoutOffset(
    RenderSliver child,
    double layoutOffset,
    GrowthDirection growthDirection,
  ) {
    assert(growthDirection == GrowthDirection.forward);
    final SliverLogicalParentData childParentData =
        child.parentData! as SliverLogicalParentData;
    childParentData.layoutOffset = layoutOffset;
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverLogicalParentData childParentData =
        child.parentData! as SliverLogicalParentData;
    return computeAbsolutePaintOffset(
      child,
      childParentData.layoutOffset!,
      GrowthDirection.forward,
    );
  }

  @override
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double scrollOffsetToChild = 0.0;
    RenderSliver? current = firstChild;
    while (current != child) {
      scrollOffsetToChild += current!.geometry!.scrollExtent;
      current = childAfter(current);
    }
    return scrollOffsetToChild + scrollOffsetWithinChild;
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double pinnedExtent = 0.0;
    RenderSliver? current = firstChild;
    while (current != child) {
      pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
      current = childAfter(current);
    }
    return pinnedExtent;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    // Hit test logic relies on this always providing an invertible matrix.
    final Offset offset = paintOffsetOf(child as RenderSliver);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  double computeChildMainAxisPosition(
    RenderSliver child,
    double parentMainAxisPosition,
  ) {
    assert(hasSize);
    final double layoutOffset =
        (child.parentData! as SliverLogicalParentData).layoutOffset!;
    return switch (applyGrowthDirectionToAxisDirection(
      child.constraints.axisDirection,
      child.constraints.growthDirection,
    )) {
      AxisDirection.down ||
      AxisDirection.right => parentMainAxisPosition - layoutOffset,
      AxisDirection.up => size.height - parentMainAxisPosition - layoutOffset,
      AxisDirection.left => size.width - parentMainAxisPosition - layoutOffset,
    };
  }

  @override
  String labelForChild(int index) => 'child $index';

  @override
  int get indexOfFirstChild => 0;

  @override
  Iterable<RenderSliver> get childrenInPaintOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = lastChild;
    while (child != null) {
      children.add(child);
      child = childBefore(child);
    }
    return children;
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder {
    final List<RenderSliver> children = <RenderSliver>[];
    RenderSliver? child = firstChild;
    while (child != null) {
      children.add(child);
      child = childAfter(child);
    }
    return children;
  }

  bool _debugCheckHasBoundedCrossAxis() {
    assert(() {
      switch (axis) {
        case Axis.vertical:
          if (!constraints.hasBoundedWidth) {
            throw FlutterError(
              'Vertical viewport was given unbounded width.\n'
              'Viewports expand in the cross axis to fill their container and '
              'constrain their children to match their extent in the cross axis. '
              'In this case, a vertical shrinkwrapping viewport was given an '
              'unlimited amount of horizontal space in which to expand.',
            );
          }
        case Axis.horizontal:
          if (!constraints.hasBoundedHeight) {
            throw FlutterError(
              'Horizontal viewport was given unbounded height.\n'
              'Viewports expand in the cross axis to fill their container and '
              'constrain their children to match their extent in the cross axis. '
              'In this case, a horizontal shrinkwrapping viewport was given an '
              'unlimited amount of vertical space in which to expand.',
            );
          }
      }
      return true;
    }());
    return true;
  }
}
