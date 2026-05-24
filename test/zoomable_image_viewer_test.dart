import 'package:custom_rr/widgets/zoomable_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // CachedNetworkImage tries to hit the network; in tests that fails
  // silently and the placeholder/error widget is shown. That's fine,
  // we're only smoke-testing the route + counter, not the images.
  Widget harness(Widget child) => MaterialApp(home: Scaffold(body: child));

  Future<void> openGallery(
    WidgetTester tester, {
    required List<String> images,
    required int initialIndex,
  }) async {
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (BuildContext ctx) {
            return Center(
              child: ElevatedButton(
                onPressed: () => showZoomableGallery(
                  ctx,
                  images: images,
                  initialIndex: initialIndex,
                ),
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    // Cannot use pumpAndSettle: CachedNetworkImage keeps the scheduler
    // busy trying to fetch URLs. A few discrete frames are enough to
    // settle the route transition + first paint.
    for (int i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('single-image gallery has no counter', (WidgetTester tester) async {
    await openGallery(
      tester,
      images: <String>['https://example.invalid/a.png'],
      initialIndex: 0,
    );
    expect(find.textContaining('/ 1'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('multi-image gallery shows position counter',
      (WidgetTester tester) async {
    await openGallery(
      tester,
      images: <String>[
        'https://example.invalid/a.png',
        'https://example.invalid/b.png',
        'https://example.invalid/c.png',
      ],
      initialIndex: 1,
    );
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
