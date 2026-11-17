import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/upgrades_dialog.dart';
import '../widgets/settings_dialog.dart';
import 'store_screen.dart';

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> with SingleTickerProviderStateMixin {
  bool _hasSavedGame = false;
  bool _isFullscreen = false;
  GameState? _cachedGameState;
  late AnimationController _animController;
  final List<_Firefly> _fireflies = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _checkSavedGame();

    // Ambient floating fireflies / light embers (normalized 0.0 to 1.0 coords)
    for (int i = 0; i < 28; i++) {
      _fireflies.add(_Firefly(
        normX: _rng.nextDouble(),
        normY: _rng.nextDouble(),
        speed: 0.15 + _rng.nextDouble() * 0.35,
        size: 2.0 + _rng.nextDouble() * 3.5,
        opacity: 0.3 + _rng.nextDouble() * 0.7,
      ));
    }

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _animController.addListener(() {
      for (final f in _fireflies) {
        f.normY -= f.speed * 0.003;
        f.normX += sin(f.normY * 12) * 0.001;
        if (f.normY < -0.05) {
          f.normY = 1.05;
          f.normX = _rng.nextDouble();
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final exists = await SaveManager.hasSave();
    GameState? state;
    if (exists) {
      state = await SaveManager.loadGame();
    }
    if (mounted) {
      setState(() {
        _hasSavedGame = exists && state != null;
        _cachedGameState = state ?? GameState.newGame();
      });
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _startShift() {
    if (_hasSavedGame) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E272C),
          shape: const BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFFE84141), width: 3),
          ),
          title: const PixelText(
            'MAGSIMULA NG SHIFT?',
            size: 15,
            color: Color(0xFFE84141),
          ),
          content: const PixelText(
            'May existing save game ka.\n\nGusto mo bang magsimula ng Bagong Shift (Day 1) o Ituloy ang dati sa "LOAD GAME"?',
            size: 11,
            color: Colors.white,
          ),
          actions: [
            PixelButton(
              label: 'Bumalik',
              fontSize: 10,
              height: 36,
              color: Colors.grey,
              onPressed: () => Navigator.pop(ctx),
            ),
            PixelButton(
              label: 'Load Game Na Lang',
              fontSize: 10,
              height: 36,
              color: const Color(0xFFF37A20),
              onPressed: () {
                Navigator.pop(ctx);
                _loadGame();
              },
            ),
            PixelButton(
              label: 'Simulan Bagong Shift',
              fontSize: 10,
              height: 36,
              color: const Color(0xFFE84141),
              onPressed: () async {
                Navigator.pop(ctx);
                final newGame = GameState.newGame();
                await SaveManager.saveGame(newGame);
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoreScreen(gameState: newGame),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } else {
      final newGame = GameState.newGame();
      SaveManager.saveGame(newGame);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoreScreen(gameState: newGame),
        ),
      );
    }
  }

  Future<void> _loadGame() async {
    if (!_hasSavedGame) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFE67E22),
          content: PixelText(
            'Wala pang naka-save na laro! Pindutin ang START SHIFT.',
            size: 11,
            color: Colors.white,
          ),
        ),
      );
      return;
    }

    final loadedState = await SaveManager.loadGame();
    if (loadedState != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => StoreScreen(gameState: loadedState),
        ),
      );
    }
  }

  void _openUpgrades() {
    final state = _cachedGameState ?? GameState.newGame();
    showDialog(
      context: context,
      builder: (_) => UpgradesDialog(gameState: state),
    ).then((_) => _checkSavedGame());
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (_) => SettingsDialog(
        onResetProgress: () {
          setState(() {
            _hasSavedGame = false;
            _cachedGameState = GameState.newGame();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. FULL SCREEN Background Image (Edge-to-Edge with ZERO black margins!)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/menu_background.jpg',
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none, // Retains sharp pixel art edges
                ),
              ),

              // 2. Ambient Fireflies across full screen
              Positioned.fill(
                child: CustomPaint(
                  painter: _FireflyPainter(fireflies: _fireflies),
                ),
              ),

              // 3. Exactly Aligned Fullscreen Touch Targets:

              // (A) Red "START SHIFT" Button Area
              Positioned(
                left: w * (788.0 / 1024.0),
                top: h * (92.0 / 571.0),
                width: w * (220.0 / 1024.0),
                height: h * (106.0 / 571.0),
                child: _MenuTapTarget(
                  label: 'START SHIFT',
                  borderRadius: BorderRadius.circular(max(6, w * 0.01)),
                  highlightColor: Colors.white.withAlpha(55),
                  onTap: _startShift,
                ),
              ),

              // (B) Orange "LOAD GAME" Button Area
              Positioned(
                left: w * (788.0 / 1024.0),
                top: h * (226.0 / 571.0),
                width: w * (220.0 / 1024.0),
                height: h * (64.0 / 571.0),
                child: _MenuTapTarget(
                  label: 'LOAD GAME',
                  borderRadius: BorderRadius.circular(max(5, w * 0.008)),
                  highlightColor: Colors.white.withAlpha(55),
                  onTap: _loadGame,
                ),
              ),

              // (C) Green "UPGRADES" Button Area
              Positioned(
                left: w * (788.0 / 1024.0),
                top: h * (318.0 / 571.0),
                width: w * (220.0 / 1024.0),
                height: h * (64.0 / 571.0),
                child: _MenuTapTarget(
                  label: 'UPGRADES',
                  borderRadius: BorderRadius.circular(max(5, w * 0.008)),
                  highlightColor: Colors.white.withAlpha(55),
                  onTap: _openUpgrades,
                ),
              ),

              // (D) Purple "SETTINGS" Button Area
              Positioned(
                left: w * (788.0 / 1024.0),
                top: h * (410.0 / 571.0),
                width: w * (220.0 / 1024.0),
                height: h * (62.0 / 571.0),
                child: _MenuTapTarget(
                  label: 'SETTINGS',
                  borderRadius: BorderRadius.circular(max(5, w * 0.008)),
                  highlightColor: Colors.white.withAlpha(55),
                  onTap: _openSettings,
                ),
              ),

              // 4. Subtle Fullscreen Toggle Icon at top-left
              Positioned(
                top: 12,
                left: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleFullscreen,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(120),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white30, width: 1.5),
                      ),
                      child: Icon(
                        _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuTapTarget extends StatefulWidget {
  final String label;
  final BorderRadius borderRadius;
  final Color highlightColor;
  final VoidCallback onTap;

  const _MenuTapTarget({
    required this.label,
    required this.borderRadius,
    required this.highlightColor,
    required this.onTap,
  });

  @override
  State<_MenuTapTarget> createState() => _MenuTapTargetState();
}

class _MenuTapTargetState extends State<_MenuTapTarget> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isDown = true),
      onTapUp: (_) {
        setState(() => _isDown = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isDown = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: _isDown ? widget.highlightColor : Colors.transparent,
          border: _isDown
              ? Border.all(color: Colors.white.withAlpha(200), width: 2.5)
              : null,
        ),
      ),
    );
  }
}

class _Firefly {
  double normX;
  double normY;
  double speed;
  double size;
  double opacity;

  _Firefly({
    required this.normX,
    required this.normY,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class _FireflyPainter extends CustomPainter {
  final List<_Firefly> fireflies;
  _FireflyPainter({required this.fireflies});

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in fireflies) {
      final paint = Paint()
        ..color = Color.fromRGBO(255, 230, 130, f.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawRect(
        Rect.fromLTWH(
          f.normX * size.width,
          f.normY * size.height,
          f.size,
          f.size,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
