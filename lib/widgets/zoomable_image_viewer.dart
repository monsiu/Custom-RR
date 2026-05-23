import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens a full-screen, pinch-to-zoom viewer for [imageUrl].
///
/// Lightweight wrapper around [InteractiveViewer] so we don't need to pull
/// in `photo_view`. Falls back to a centered close button and supports
/// swipe-down dismiss via vertical drag.
Future<void> showZoomableImage(
  BuildContext context, {
  required String imageUrl,
  Object? heroTag,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (BuildContext _, __, ___) => _ZoomableImagePage(
        imageUrl: imageUrl,
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, Animation<double> a, __, Widget child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _ZoomableImagePage extends StatefulWidget {
  const _ZoomableImagePage({required this.imageUrl, this.heroTag});

  final String imageUrl;
  final Object? heroTag;

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    final Widget image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.white70, size: 64),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: (DragUpdateDetails d) =>
            setState(() => _dragOffset += d.delta.dy),
        onVerticalDragEnd: (_) {
          if (_dragOffset.abs() > 120) {
            Navigator.of(context).maybePop();
          } else {
            setState(() => _dragOffset = 0);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: widget.heroTag == null
                      ? image
                      : Hero(tag: widget.heroTag!, child: image),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
