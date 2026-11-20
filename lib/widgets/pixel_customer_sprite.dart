import 'package:flutter/material.dart';
import '../utils/customer_image_data.dart';
import 'pixel_text.dart';

enum CustomerType {
  customerGirl,
  mangBoy,
  bongbong,
  tinay,
  totoyTambay,
  regularGuy,
  scammer,
  lolaConching,
  alingNena,
  itStudent,
  tropaMark,
  californiaGuy,
}

class CustomerPersona {
  final String id;
  final String name;
  final CustomerType type;
  final String greeting;
  final String defaultItem;
  final String assetPath;

  const CustomerPersona({
    required this.id,
    required this.name,
    required this.type,
    required this.greeting,
    required this.defaultItem,
    required this.assetPath,
  });

  static const List<CustomerPersona> allPersonas = [
    CustomerPersona(
      id: 'bongbong',
      name: 'Bongbong (Bata)',
      type: CustomerType.bongbong,
      greeting: 'Ate, pabili pong Kendi at Chichirya! 🍬',
      defaultItem: 'candy',
      assetPath: 'assets/images/bongbong.png',
    ),
    CustomerPersona(
      id: 'customer_girl',
      name: 'Ate Girl (Suki)',
      type: CustomerType.customerGirl,
      greeting: 'Pabili po! 🍬',
      defaultItem: 'candy',
      assetPath: 'assets/images/customer_girl.png',
    ),
    CustomerPersona(
      id: 'mang_boy',
      name: 'Mang Boy (Driver)',
      type: CustomerType.mangBoy,
      greeting: 'Pabili ngang Kape at Yosi, boss! ☕',
      defaultItem: 'kape',
      assetPath: 'assets/images/mang_boy.png',
    ),
    CustomerPersona(
      id: 'tinay',
      name: 'Tinay (Estudyante)',
      type: CustomerType.tinay,
      greeting: 'Ate, pabili pong Noodles at Softdrinks! 🍜',
      defaultItem: 'noodles',
      assetPath: 'assets/images/tinay.png',
    ),
    CustomerPersona(
      id: 'totoy',
      name: 'Totoy Tambay',
      type: CustomerType.totoyTambay,
      greeting: 'Kuya, pabili ng malamig na Tubig at Tsitsirya! 💧',
      defaultItem: 'tubig',
      assetPath: 'assets/images/totoy.png',
    ),
    CustomerPersona(
      id: 'kuya_green',
      name: 'Kuya Jojo (Kargador)',
      type: CustomerType.regularGuy,
      greeting: 'Boss, pabili ng isang kilong Bigas at Sardinas! 🍚',
      defaultItem: 'bigas',
      assetPath: 'assets/images/kuya_green.png',
    ),
    CustomerPersona(
      id: 'scammer',
      name: 'Kuya Shady',
      type: CustomerType.scammer,
      greeting: 'Nag-GCash na po ako ate, patingin! 📱',
      defaultItem: 'de_lata',
      assetPath: 'assets/images/scammer.png',
    ),
    CustomerPersona(
      id: 'it_student',
      name: 'Earl (IT Student)',
      type: CustomerType.itStudent,
      greeting: 'Ate, pabili pong Kape pampagising sa coding! ☕',
      defaultItem: 'kape',
      assetPath: 'assets/images/customer_it_student.png',
    ),
    CustomerPersona(
      id: 'tropa_mark',
      name: 'Mark (Tropa)',
      type: CustomerType.tropaMark,
      greeting: 'Boss, pabili ngang malamig na Softdrinks at Chichirya! 🥤',
      defaultItem: 'softdrinks',
      assetPath: 'assets/images/customer_tropa_mark.png',
    ),
    CustomerPersona(
      id: 'california_karl',
      name: 'Karl (Gamer)',
      type: CustomerType.californiaGuy,
      greeting: 'Ate, pabili pong Noodles at Tubig pang-merienda! 🍜',
      defaultItem: 'noodles',
      assetPath: 'assets/images/customer_california_karl.png',
    ),
  ];
}

class PixelCustomerSprite extends StatelessWidget {
  final CustomerPersona persona;
  final bool isSpeaking;
  final String speechText;
  final double width;
  final double height;
  final VoidCallback onTap;

  const PixelCustomerSprite({
    super.key,
    required this.persona,
    this.isSpeaking = true,
    required this.speechText,
    this.width = 200,
    this.height = 200,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageKey = persona.assetPath.split('/').last.replaceAll('.png', '');
    final bytes = CustomerImageData.getBytes(imageKey) ?? CustomerImageData.getBytes(persona.id);

    Widget spriteWidget;
    if (bytes != null) {
      spriteWidget = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter, // Anchor flush to window sill
        filterQuality: FilterQuality.none, // 100% crisp 16-bit pixel clusters
      );
    } else {
      spriteWidget = Image.asset(
        persona.assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Genuine 16-Bit Pixel Art Customer Character Sprite
          spriteWidget,

          // 2. Retro Pixel Speech Bubble (Optional inline mode)
          if (isSpeaking)
            Positioned(
              bottom: height + 4,
              child: PixelSpeechBubble(
                text: speechText,
                onTap: onTap,
              ),
            ),
        ],
      ),
    );
  }
}

class PixelSpeechBubble extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const PixelSpeechBubble({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 210),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
              ],
            ),
            child: PixelText(
              text,
              size: 10.5,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              hasShadow: false,
              textAlign: TextAlign.center,
            ),
          ),
          // Small pixel pointer triangle pointing down toward customer
          CustomPaint(
            size: const Size(12, 7),
            painter: _SpeechTailPainter(),
          ),
        ],
      ),
    );
  }
}

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
