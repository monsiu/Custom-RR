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
  return _push(
    context,
    images: <String>[imageUrl],
    heroTags: heroTag == null ? null : <Object>[heroTag],
    initialIndex: 0,
  );
}

/// Opens a full-screen swipeable gallery starting at [initialIndex].
Future<void> showZoomableGallery(
  BuildContext context, {
  required List<String> images,
  required int initialIndex,
  List<Object>? heroTags,
}) {
  return _push(
    context,
    images: images,
    heroTags: heroTags,
    initialIndex: initialIndex,
  );
}

Future<void> _push(
  BuildContext context, {
  required List<String> images,
  required int initialIndex,
  List<Object>? heroTags,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (BuildContext _, __, ___) => _ZoomableImagePage(
        images: images,
        heroTags: heroTags,
        initialIndex: initialIndex,
      ),
      transitionsBuilder: (_, Animation<double> a, __, Widget child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _ZoomableImagePage extends StatefulWidget {
  const _ZoomableImagePage({
    required this.images,
    required this.initialIndex,
    this.heroTags,
  });

  final List<String> images;
  final List<Object>? heroTags;
  final int initialIndex;

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  double _dragOffset = 0;
  // Disable swipe-to-dismiss / page-swipe while pinch-zoomed in so pans
  // inside InteractiveViewer don't accidentally close or page.
  bool _zoomed = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _buildPage(int i) {
    final String url = widget.images[i];
    final Object? tag =
        (widget.heroTags != null && i < widget.heroTags!.length)
            ? widget.heroTags![i]
            : null;
    final Widget image = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.white70, size: 64),
      ),
    );
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      onInteractionUpdate: (ScaleUpdateDetails d) {
        final bool zoomed = d.scale > 1.01;
        if (zoomed != _zoomed) {
          setState(() => _zoomed = zoomed);
        }
      },
      onInteractionEnd: (_) {
        if (_zoomed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _zoomed = false);
            }
          });
        }
      },
      child: Center(
        child: tag == null ? image : Hero(tag: tag, child: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool gallery = widget.images.length > 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _zoomed
            ? null
            : (DragUpdateDetails d) =>
                setState(() => _dragOffset += d.delta.dy),
        onVerticalDragEnd: _zoomed
            ? null
            : (_) {
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
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.images.length,
                physics: _zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                onPageChanged: (int i) {
                  setState(() => _index = i);
                  // Warm the cache for the immediate neighbours so the
                  // next swipe doesn't show a spinner.
                  for (final int n in <int>[i - 1, i + 1]) {
                    if (n >= 0 && n < widget.images.length) {
                      precacheImage(
                        CachedNetworkImageProvider(widget.images[n]),
                        context,
                      );
                    }
                  }
                },
                itemBuilder: (BuildContext _, int i) => _buildPage(i),
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
            if (gallery)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
