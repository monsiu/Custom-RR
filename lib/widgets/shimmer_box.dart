import 'package:flutter/material.dart';

/// A lightweight, dependency-free loading skeleton for network images
/// (catalog logos and screenshots). It fills its parent's bounds with a
/// neutral surface tone and sweeps a soft highlight across it, so an image
/// that is still downloading reads as "loading" rather than empty or broken.
///
/// The parent must impose bounded constraints (the placeholders that use this
/// sit inside an [AspectRatio], a fixed-height tile, or a hero header). Any
/// parent clip (e.g. [ClipRRect] or [ClipOval]) still applies on top, so the
/// skeleton matches rounded or circular logo frames.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.borderRadius});

  /// Optional rounding for the skeleton itself. Leave null when the parent
  /// already clips the shape.
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the platform "reduce motion" accessibility setting: when it is on
    // we leave the controller parked at 0, which paints a flat, un-animated
    // skeleton (the highlight sits off the left edge at value 0).
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = scheme.surfaceContainerHighest;
    // Blend a little of the foreground tone into the base for the moving
    // highlight so the effect reads in both light and dark themes without
    // hardcoding colours.
    final Color highlight =
        Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.16), base);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                colors: <Color>[base, highlight, base],
                stops: const <double>[0.20, 0.50, 0.80],
                transform: _SlideTransform(_controller.value),
              ),
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

/// Slides the shimmer gradient horizontally from fully off the left edge to
/// fully off the right edge as the animation runs from 0 to 1. At both
/// extremes the box shows the flat base colour, so the repeat wraps seamlessly.
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.value);

  /// Controller position in the range 0..1.
  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}
