import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Hidden easter egg: a faux bootloader / fastboot terminal that walks the
/// user through a tongue-in-cheek custom-ROM flash sequence. Reached by
/// tapping the app version five times in the About screen. Not registered
/// with go_router on purpose, it stays a true hidden surprise.
class EasterEggPage extends StatefulWidget {
  const EasterEggPage({super.key});

  @override
  State<EasterEggPage> createState() => _EasterEggPageState();
}

enum _Phase { terminal, boot, welcome }

enum _Achievement {
  bootloaderUnlocked(
    'bootloader_unlocked',
    'Bootloader Unlocked',
    'Finished a flash without interrupting it',
  ),
  speedFlasher(
    'speed_flasher',
    'Speed Flasher',
    'Fast-forwarded the entire sequence',
  ),
  patientFlasher(
    'patient_flasher',
    'Patient Flasher',
    'Watched the whole flash without tapping',
  );

  const _Achievement(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;
}

/// A single line of fastboot output. [delay] is how long to wait before
/// printing the next line during the natural playback.
class _Line {
  const _Line(this.text, {this.delay = const Duration(milliseconds: 220), this.color});
  final String text;
  final Duration delay;
  final Color? color;
}

class _EasterEggPageState extends State<EasterEggPage>
    with TickerProviderStateMixin {
  static const Color _phosphor = Color(0xFF7CFFB2);
  static const Color _phosphorDim = Color(0xFF3D8A5F);
  static const Color _amber = Color(0xFFFFC857);
  static const Color _crtBg = Color(0xFF050A07);

  static final List<_Line> _script = <_Line>[
    _Line('> fastboot devices', delay: Duration(milliseconds: 380)),
    _Line('CUSTOM-RR-DEVICE   fastboot', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot oem unlock', delay: Duration(milliseconds: 420)),
    _Line('...', delay: Duration(milliseconds: 600), color: _phosphorDim),
    _Line('(bootloader) Unlock requested. Hold Vol+ to confirm.', color: _amber),
    _Line('OKAY [  3.141s]', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot flash boot     boot.img'),
    _Line('Sending boot.img (32768 KB)...', delay: Duration(milliseconds: 280)),
    _Line('Writing boot.img...', delay: Duration(milliseconds: 320)),
    _Line('OKAY [  1.337s]', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot flash system   custom-rr-v26.0.img'),
    _Line('Sending sparse system.img (2048 MB)...', delay: Duration(milliseconds: 260)),
    _Line('Writing sparse system...', delay: Duration(milliseconds: 320)),
    _Line('OKAY [ 42.000s]', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot flash vendor   vendor.img'),
    _Line('OKAY [  4.200s]', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot -w', delay: Duration(milliseconds: 280)),
    _Line('Erasing userdata...', delay: Duration(milliseconds: 320)),
    _Line('OKAY [  0.815s]', color: _phosphorDim),
    _Line(''),
    _Line('> fastboot reboot', delay: Duration(milliseconds: 420)),
    _Line('finished. total time: 0.001s', color: _phosphorDim),
    _Line(''),
    _Line('-- BOOTING --', color: _amber, delay: Duration(milliseconds: 700)),
    _Line('[  0.000000] Linux version 6.6.0-custom-rr', delay: Duration(milliseconds: 180)),
    _Line('[  0.041337] CPU: ARMv9 quad-core, cool to the touch'),
    _Line('[  0.082000] Memory: too much, in a good way'),
    _Line('[  0.314159] init: starting service zygote...'),
    _Line('[  0.420000] init: starting service surfaceflinger...'),
    _Line('[  0.999999] BOOT COMPLETE', color: _phosphor, delay: Duration(milliseconds: 600)),
  ];

  static const List<String> _bootStages = <String>[
    'Starting init...',
    'Mounting /system, /vendor, /data...',
    'Loading kernel modules...',
    'Starting Zygote...',
    'Starting SurfaceFlinger...',
    'Optimizing apps...',
    'Almost there...',
  ];

  static const List<String> _welcomeTaglines = <String>[
    'Stay rooted, stay rad.',
    'Custom ROMs forever.',
    'fastboot oem unlock your imagination.',
    'Hello, fellow flasher.',
    'Have you backed up today?',
    'Reboot to bootloader, reboot your day.',
  ];

  static const Duration _fastForwardInterval = Duration(milliseconds: 30);

  final List<_Line> _printed = <_Line>[];
  Timer? _ticker;
  Timer? _bootTimer;
  int _index = 0;
  int _userTaps = 0;
  bool _completed = false;
  bool _fastForwarding = false;
  _Phase _phase = _Phase.terminal;
  int _bootStep = 0;
  late final String _tagline;

  late final AnimationController _flicker;
  late final AnimationController _caret;
  late final AnimationController _bootSpinner;

  final ScrollController _scroll = ScrollController();
  final Set<String> _achievements = <String>{};
  _Achievement? _newAchievement;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _flicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _caret = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _bootSpinner = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _tagline = _welcomeTaglines[math.Random().nextInt(_welcomeTaglines.length)];
    _loadAchievements();
    _scheduleNext();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bootTimer?.cancel();
    _toastTimer?.cancel();
    _flicker.dispose();
    _caret.dispose();
    _bootSpinner.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadAchievements() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList('easter_achievements');
      if (stored == null || !mounted) return;
      setState(() => _achievements.addAll(stored));
    } catch (_) {/* ignore */}
  }

  Future<void> _persistAchievements() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'easter_achievements',
        _achievements.toList(growable: false),
      );
    } catch (_) {/* ignore */}
  }

  void _unlock(_Achievement a) {
    if (_achievements.contains(a.id)) return;
    setState(() {
      _achievements.add(a.id);
      _newAchievement = a;
    });
    _persistAchievements();
    HapticFeedback.heavyImpact();
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _newAchievement = null);
    });
  }

  void _scheduleNext() {
    if (_index >= _script.length) {
      if (!_completed) {
        _completed = true;
        _unlock(_Achievement.bootloaderUnlocked);
        if (_userTaps == 0) _unlock(_Achievement.patientFlasher);
        if (_fastForwarding) _unlock(_Achievement.speedFlasher);
        _startBoot();
      }
      return;
    }
    final _Line next = _script[_index];
    final Duration d = _fastForwarding ? _fastForwardInterval : next.delay;
    _ticker?.cancel();
    _ticker = Timer(d, _printNext);
  }

  void _startBoot() {
    setState(() {
      _phase = _Phase.boot;
      _bootStep = 0;
    });
    HapticFeedback.mediumImpact();
    _scheduleBootStep();
  }

  void _scheduleBootStep() {
    _bootTimer?.cancel();
    _bootTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (_bootStep + 1 >= _bootStages.length) {
        _finishBoot();
        return;
      }
      setState(() => _bootStep++);
      HapticFeedback.selectionClick().catchError((_) {});
      _scheduleBootStep();
    });
  }

  void _finishBoot() {
    _bootTimer?.cancel();
    setState(() => _phase = _Phase.welcome);
    HapticFeedback.heavyImpact();
  }

  void _printNext() {
    if (!mounted) return;
    if (_index >= _script.length) return;
    setState(() {
      _printed.add(_script[_index]);
      _index++;
    });
    // Auto-scroll to bottom after frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    });
    if (_index % 4 == 0) {
      // Light tactile tick every few lines to feel "alive".
      HapticFeedback.selectionClick().catchError((_) {});
    }
    _scheduleNext();
  }

  void _onTap() {
    if (_phase == _Phase.boot) {
      // Skip the boot animation.
      _finishBoot();
      return;
    }
    if (_phase == _Phase.welcome) {
      _restart();
      return;
    }
    if (_completed) {
      _restart();
      return;
    }
    _userTaps++;
    if (!_fastForwarding) {
      setState(() => _fastForwarding = true);
      HapticFeedback.mediumImpact();
    }
    _ticker?.cancel();
    _printNext();
  }

  void _onLongPress() {
    HapticFeedback.heavyImpact();
    _restart();
  }

  void _restart() {
    _ticker?.cancel();
    _bootTimer?.cancel();
    setState(() {
      _printed.clear();
      _index = 0;
      _userTaps = 0;
      _completed = false;
      _fastForwarding = false;
      _phase = _Phase.terminal;
      _bootStep = 0;
    });
    _scheduleNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crtBg,
      appBar: AppBar(
        backgroundColor: _crtBg,
        elevation: 0,
        foregroundColor: _phosphor,
        title: const Text(
          'fastboot',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Restart flash',
            icon: const Icon(Icons.restart_alt),
            color: _phosphor,
            onPressed: _restart,
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: switch (_phase) {
                _Phase.terminal => KeyedSubtree(
                    key: const ValueKey<String>('terminal'),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: _buildTerminal()),
                        Positioned.fill(
                          child: IgnorePointer(child: _buildScanlines()),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(child: _buildVignette()),
                        ),
                      ],
                    ),
                  ),
                _Phase.boot => KeyedSubtree(
                    key: const ValueKey<String>('boot'),
                    child: _buildBootSplash(),
                  ),
                _Phase.welcome => KeyedSubtree(
                    key: const ValueKey<String>('welcome'),
                    child: _buildWelcome(),
                  ),
              },
            ),
          ),
          if (_achievements.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildAchievementsRow(),
            ),
          if (_newAchievement != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Center(
                child: _AchievementToast(achievement: _newAchievement!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTerminal() {
    return Semantics(
      label: 'Fake fastboot terminal easter egg. '
          'Tap to skip ahead, long-press to restart.',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onLongPress: _onLongPress,
        child: AnimatedBuilder(
          animation: _flicker,
          builder: (BuildContext context, Widget? child) {
            // Tiny brightness flicker, mostly imperceptible.
            final double f = 0.97 +
                0.03 * math.sin(_flicker.value * 2 * math.pi * 3.2);
            return Opacity(opacity: f, child: child);
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              child: SingleChildScrollView(
                controller: _scroll,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final _Line l in _printed)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          l.text,
                          style: TextStyle(
                            color: l.color ?? _phosphor,
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            height: 1.35,
                            shadows: <Shadow>[
                              Shadow(
                                color: (l.color ?? _phosphor)
                                    .withValues(alpha: 0.55),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_completed) _buildCaretLine(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaretLine() {
    return AnimatedBuilder(
      animation: _caret,
      builder: (BuildContext context, _) {
        final bool on = _caret.value < 0.5;
        return Text(
          on ? '_' : ' ',
          style: const TextStyle(
            color: _phosphor,
            fontFamily: 'monospace',
            fontSize: 13.5,
            height: 1.35,
            shadows: <Shadow>[
              Shadow(color: _phosphor, blurRadius: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanlines() {
    return CustomPaint(painter: const _ScanlinePainter());
  }

  Widget _buildVignette() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: <Color>[
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55),
          ],
          stops: const <double>[0.65, 1.0],
        ),
      ),
    );
  }

  Widget _buildBootSplash() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Spacer(),
              Image.asset(
                'images/launcher.png',
                width: 96,
                height: 96,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(height: 20),
              const Text(
                'CUSTOM RR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 36),
              AnimatedBuilder(
                animation: _bootSpinner,
                builder: (BuildContext context, _) {
                  return Transform.rotate(
                    angle: _bootSpinner.value * 2 * math.pi,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(_phosphor),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _bootStages[_bootStep.clamp(0, _bootStages.length - 1)],
                  key: ValueKey<int>(_bootStep),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'tap to skip',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    // Always render the brand palette here so the easter-egg payoff lands
    // on Custom RR's signature green regardless of the user's dynamic
    // (Material You / GTK accent) theme.
    final BrandColors brand = context.brand;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      onLongPress: _onLongPress,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              brand.seed,
              brand.dark,
              brand.deep,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'images/launcher.png',
                  width: 112,
                  height: 112,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'tap to flash again',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _Achievement.values
          .where((_Achievement a) => _achievements.contains(a.id))
          .map<Widget>((_Achievement a) => _AchievementBadge(achievement: a))
          .toList(growable: false),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  const _ScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = Colors.black.withValues(alpha: 0.10);
    const double gap = 3;
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinePainter oldDelegate) => false;
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.description,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          border: Border.all(
            color: _EasterEggPageState._phosphorDim,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bolt,
              size: 12,
              color: _EasterEggPageState._amber,
            ),
            const SizedBox(width: 6),
            Text(
              achievement.label,
              style: const TextStyle(
                color: _EasterEggPageState._phosphor,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementToast extends StatelessWidget {
  const _AchievementToast({required this.achievement});
  final _Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey<String>(achievement.id),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          border: Border.all(
            color: _EasterEggPageState._phosphor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bolt,
              color: _EasterEggPageState._amber,
              size: 18,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '> achievement unlocked',
                  style: TextStyle(
                    color: _EasterEggPageState._phosphorDim,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  achievement.label,
                  style: const TextStyle(
                    color: _EasterEggPageState._phosphor,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
