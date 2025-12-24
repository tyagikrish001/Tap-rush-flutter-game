import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GamePage(),
    );
  }
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  // ================= AUDIO =================
  final AudioPlayer _player = AudioPlayer();
  bool _canPlaySound = true;

  static const double _boomVolume = 0.8;
  static const int _soundDurationMs = 120;

  // ================= GAME ==================
  final double radius = 40;
  Offset circleOffset = Offset.zero;

  Size? safeSize;
  EdgeInsets safePadding = EdgeInsets.zero;

  int score = 0;
  bool gameOver = false;
  bool initialized = false;

  // ============== INIT =====================
  @override
  void initState() {
    super.initState();

    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(_boomVolume);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (safeSize != null && !initialized) {
        initGame(safeSize!);
      }
    });
  }

  // ============== GAME INIT ================
  void initGame(Size fullSize) {
    final r = Random();

    final width = fullSize.width - safePadding.horizontal;
    final height = fullSize.height - safePadding.vertical;

    setState(() {
      initialized = true;
      gameOver = false;
      score = 0;

      circleOffset = Offset(
        safePadding.left + r.nextDouble() * (width - radius * 2) + radius,
        safePadding.top + r.nextDouble() * (height - radius * 2) + radius,
      );
    });
  }

  // ============== MOVE CIRCLE ==============
  void moveCircle() {
    final r = Random();
    final width = safeSize!.width - safePadding.horizontal;
    final height = safeSize!.height - safePadding.vertical;

    setState(() {
      circleOffset = Offset(
        safePadding.left + r.nextDouble() * (width - radius * 2) + radius,
        safePadding.top + r.nextDouble() * (height - radius * 2) + radius,
      );
    });
  }

  // ============== SOUND ====================
  void playBoom() async {
    if (!_canPlaySound) return;

    _canPlaySound = false;

    await _player.stop();
    await _player.play(AssetSource('boom.mp3'));

    Future.delayed(const Duration(milliseconds: _soundDurationMs), () {
      _player.stop();
      _canPlaySound = true;
    });
  }

  // ============== TAP ======================
  void handleTap(TapDownDetails details) {
    if (!initialized || gameOver) return;

    final tap = details.localPosition;
    final distance = (tap - circleOffset).distance;

    if (distance <= radius) {
      playBoom();
      setState(() => score++);
      moveCircle();
    } else {
      setState(() => gameOver = true);
    }
  }

  // ============== UI =======================
  @override
  Widget build(BuildContext context) {
    safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            safeSize = Size(constraints.maxWidth, constraints.maxHeight);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: handleTap,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: CirclePainter(circleOffset, radius),
                  ),

                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Score: $score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (gameOver)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GAME OVER\nScore: $score',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => initGame(safeSize!),
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== CLEAN ====================
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// ================= PAINTER =================
class CirclePainter extends CustomPainter {
  final Offset offset;
  final double radius;

  CirclePainter(this.offset, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    canvas.drawCircle(offset, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}