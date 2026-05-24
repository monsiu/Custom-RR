// Renders the XdaThreadsSection widget to a PNG so we can preview it
// without launching the full app. Uses fake threads (no network).
//
// Run with:  flutter test tool/snap_xda_section.dart
// Output:    /tmp/crr-shots/xda_section.png

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:custom_rr/services/xda_feed.dart';
import 'package:custom_rr/widgets/xda_threads_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('snapshot XdaThreadsSection', (WidgetTester tester) async {
    final DateTime now = DateTime.now().toUtc();
    final List<XdaThread> threads = <XdaThread>[
      XdaThread(
        title: '[ROM][14][UNOFFICIAL] LineageOS 21 for Pixel 6 (oriole)',
        url: 'https://xdaforums.com/t/example.1/',
        author: 'devmaintainer',
        published: now.subtract(const Duration(hours: 2)),
      ),
      XdaThread(
        title: '[KERNEL] Custom kernel build 5.10 with KernelSU',
        url: 'https://xdaforums.com/t/example.2/',
        author: 'kernelhacker',
        published: now.subtract(const Duration(hours: 9)),
      ),
      XdaThread(
        title: 'Tips & Tricks: getting the most out of your Pixel 6',
        url: 'https://xdaforums.com/t/example.3/',
        author: 'tipsguru',
        published: now.subtract(const Duration(days: 1)),
      ),
      XdaThread(
        title: '[GUIDE] Unlock bootloader and flash factory image',
        url: 'https://xdaforums.com/t/example.4/',
        author: 'rootuser',
        published: now.subtract(const Duration(days: 3)),
      ),
    ];

    const String forumUrl = 'https://xdaforums.com/f/google-pixel-6.12517/';
    final String? feedUrl = XdaFeedService.feedUrlFor(forumUrl);
    XdaFeedService.instance.primeCacheForTesting(feedUrl!, threads);

    await tester.binding.setSurfaceSize(const Size(900, 1100));

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7ED957),
      brightness: Brightness.light,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: scheme, useMaterial3: true),
        home: Scaffold(
          backgroundColor: scheme.surface,
          body: Center(
            child: RepaintBoundary(
              key: const ValueKey<String>('snap'),
              child: Container(
                width: 820,
                color: scheme.surface,
                padding: const EdgeInsets.all(24),
                child: const XdaThreadsSection(forumUrl: forumUrl),
              ),
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    debugPrint('threads rendered: '
        '${find.byIcon(Icons.chat_bubble_outline).evaluate().length}');

    final RenderRepaintBoundary boundary = tester
            .renderObject(find.byKey(const ValueKey<String>('snap')))
        as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? bytes =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Directory outDir = Directory('/tmp/crr-shots');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final File out = File('${outDir.path}/xda_section.png');
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${out.path}');
  });
}
