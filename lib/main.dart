import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const TapRushApp());
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

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

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  final AudioPlayer _player = AudioPlayer();

  double circleX = 0;
  double circleY = 0;
  final double circleSize = 90;

  int score = 0;
  bool isGameOver = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _player.setReleaseMode(ReleaseMode.stop);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnim = Tween(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // ✅ SAFE PLACE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      moveCircle();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> playBoom() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/boom.mp3'));
    } catch (_) {}
  }

  void moveCircle() {
    final size = MediaQuery.of(context).size;

    setState(() {
      circleX = _random.nextDouble() * (size.width - circleSize);
      circleY = _random.nextDouble() *
              (size.height - circleSize - 120) +
          80;
    });
  }

  void gameOver() {
    setState(() {
      isGameOver = true;
    });
  }

  void onTapDown(TapDownDetails details) {
    if (isGameOver) return;

    final tap = details.localPosition;
    final center = Offset(
      circleX + circleSize / 2,
      circleY + circleSize / 2,
    );

    if ((tap - center).distance <= circleSize / 2) {
      playBoom();
      _controller.forward().then((_) => _controller.reverse());

      setState(() => score++);
      moveCircle();
    } else {
      gameOver();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTapDown,
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Score: $score',
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (!isGameOver)
              AnimatedBuilder(
                animation: _scaleAnim,
                builder: (_, __) {
                  return Positioned(
                    left: circleX,
                    top: circleY,
                    child: Transform.scale(
                      scale: _scaleAnim.value,
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.orange,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: Colors.black54,
                              offset: Offset(2, 4),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            if (isGameOver)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Score: $score',
                      style:
                          const TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          score = 0;
                          isGameOver = false;
                        });
                        moveCircle();
                      },
                      child: const Text('Restart'),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}