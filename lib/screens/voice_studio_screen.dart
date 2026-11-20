import 'package:flutter/material.dart';
import '../services/voice_pack_service.dart';
import '../widgets/pixel_text.dart';

// ── Data classes ──────────────────────────────────────────────────────────

class _ClipData {
  final String id;
  final String label;
  final String example;
  const _ClipData(this.id, this.label, this.example);
}

class _PersonaData {
  final String id;
  final String avatar;
  final String name;
  final String desc;
  final List<_ClipData> clips;
  const _PersonaData(this.id, this.avatar, this.name, this.desc, this.clips);
}

const _greet = _ClipData('greet', '🗣️ Pagbati', 'Pabili po!');
const _pay = _ClipData('pay', '💵 Bayad', 'Magkano po lahat?');
const _leave = _ClipData('leave', '😤 Umalis', 'Ang tagal, aalis na ako!');
const _gcash = _ClipData('gcash', '📱 GCash', 'GCash na po!');

const _allPersonas = [
  _PersonaData(
    'bongbong', '👦', 'Bongbong',
    'Batang lalaki — mataas na boses',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'tinay', '👧', 'Tinay',
    'Batang babae — mataas na boses',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'customerGirl', '👩', 'Dalaga',
    'Babae — malumanay na boses',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'mangBoy', '🧔', 'Mang Boy',
    'Tricycle driver — mababang boses',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'totoyTambay', '🧑', 'Totoy Tambay',
    'Tambay sa kanto',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'regularGuy', '👷', 'Kargador',
    'Normal na boses ng lalaki',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'scammer', '🕶️', 'Scammer',
    'Manloloko — mabilis magsalita',
    [_greet, _pay, _gcash, _leave],
  ),
  _PersonaData(
    'lolaConching', '👵', 'Lola Conching',
    'Matanda — mabagal magsalita',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'alingNena', '🧕', 'Aling Nena',
    'Nanay / Tita',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'earl', '💻', 'Earl (IT Student)',
    'IT Student (Light Blue Polo) — pampagising sa coding',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'andrie', '😎', 'Andrie (Tropa)',
    'Tropa (Dark Grey Crewneck) — masiglang boses',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'jake', '🧢', 'Jake (California)',
    'California Shirt — merienda noodles at tubig',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'david', '🎒', 'David (XXLFCH)',
    'Naka-grey sweater — pampagana kape at chichirya',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'nick', '🙌', 'Nick (T-Pose)',
    'Naka-salamin at T-pose — noodles at softdrinks',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'ken', '😁', 'Ken (Friendly)',
    'Naka-braces at ngiti — malamig na tubig at kape',
    [_greet, _pay, _leave],
  ),
  _PersonaData(
    'vhasty', '👓', 'Vhasty (NU Student)',
    'NU Student na naka-salamin — kendi at softdrinks',
    [_greet, _pay, _leave],
  ),
];

// ── Voice Studio Screen ──────────────────────────────────────────────────

class VoiceStudioScreen extends StatefulWidget {
  const VoiceStudioScreen({super.key});

  @override
  State<VoiceStudioScreen> createState() => _VoiceStudioScreenState();
}

class _VoiceStudioScreenState extends State<VoiceStudioScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _has = {};
  String? _recKey; // "personaId_clipType" if currently recording
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _loadAll();
  }

  @override
  void dispose() {
    if (_recKey != null) VoicePackService.stopRecording();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    for (final p in _allPersonas) {
      for (final c in p.clips) {
        final has = await VoicePackService.hasRecording(p.id, c.id);
        if (mounted) setState(() => _has['${p.id}_${c.id}'] = has);
      }
    }
  }

  Future<void> _toggle(String pid, String cid) async {
    final key = '${pid}_$cid';
    if (_recKey == key) {
      // ── Stop recording ──
      final data = await VoicePackService.stopRecording();
      if (mounted) setState(() => _recKey = null);
      if (data != null && data.isNotEmpty) {
        await VoicePackService.saveRecording(pid, cid, data);
        if (mounted) setState(() => _has[key] = true);
        // Auto-preview playback
        await VoicePackService.playRecording(pid, cid);
      }
    } else if (_recKey == null) {
      // ── Start recording ──
      await VoicePackService.startRecording();
      if (mounted) setState(() => _recKey = key);
    }
  }

  Future<void> _play(String pid, String cid) async {
    await VoicePackService.playRecording(pid, cid);
  }

  Future<void> _delete(String pid, String cid) async {
    await VoicePackService.deleteRecording(pid, cid);
    if (mounted) setState(() => _has['${pid}_$cid'] = false);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0E0A),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _instructions(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: _allPersonas.length,
                itemBuilder: (_, i) => _card(_allPersonas[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2C1810),
        border: Border(bottom: BorderSide(color: Color(0xFF5C3A1E), width: 2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513),
                border: Border.all(color: const Color(0xFFD2691E), width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const PixelText('← BALIK', size: 10, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const PixelText(
            '🎙️ VOICE STUDIO',
            size: 15,
            color: Color(0xFFF1C40F),
          ),
        ],
      ),
    );
  }

  Widget _instructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      color: const Color(0xFF1A0E0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          PixelText(
            'I-record ang sarili mong boses para sa bawat customer!',
            size: 10,
            color: Color(0xFFECF0F1),
          ),
          SizedBox(height: 4),
          PixelText(
            '🎤 Pindutin para mag-record\n'
            '⏹ Pindutin ulit para i-save\n'
            '▶️ I-play ang na-record · 🗑️ I-delete',
            size: 8.5,
            color: Color(0xFF95A5A6),
          ),
        ],
      ),
    );
  }

  Widget _card(_PersonaData p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1810),
        border: Border.all(color: const Color(0xFF5C3A1E), width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.avatar, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText(
                      p.name,
                      size: 12,
                      color: const Color(0xFFF1C40F),
                    ),
                    PixelText(
                      p.desc,
                      size: 8.5,
                      color: const Color(0xFF95A5A6),
                    ),
                  ],
                ),
              ),
              // Recording count badge
              _countBadge(p),
            ],
          ),
          const SizedBox(height: 6),
          ...p.clips.map((c) => _clipRow(p.id, c)),
        ],
      ),
    );
  }

  Widget _countBadge(_PersonaData p) {
    int recorded = 0;
    for (final c in p.clips) {
      if (_has['${p.id}_${c.id}'] ?? false) recorded++;
    }
    final color =
        recorded == p.clips.length
            ? const Color(0xFF27AE60)
            : recorded > 0
                ? const Color(0xFFF39C12)
                : const Color(0xFF7F8C8D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: PixelText(
        '$recorded/${p.clips.length}',
        size: 9,
        color: color,
      ),
    );
  }

  Widget _clipRow(String pid, _ClipData clip) {
    final key = '${pid}_${clip.id}';
    final has = _has[key] ?? false;
    final isRec = _recKey == key;
    final blocked = _recKey != null && !isRec;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: PixelText(clip.label, size: 9, color: Colors.white70),
          ),
          Expanded(
            child: PixelText(
              '"${clip.example}"',
              size: 7.5,
              color: const Color(0xFF7F8C8D),
            ),
          ),
          const SizedBox(width: 4),

          // Record / Stop button
          _recBtn(pid, clip.id, isRec, blocked),

          // Play button
          if (has) ...[
            const SizedBox(width: 5),
            _tinyBtn('▶️', const Color(0xFF27AE60), () => _play(pid, clip.id)),
          ],

          // Delete button
          if (has) ...[
            const SizedBox(width: 3),
            _tinyBtn('🗑️', const Color(0xFFC0392B), () => _delete(pid, clip.id)),
          ],

          // ✅ indicator if recorded
          if (has && !isRec) ...[
            const SizedBox(width: 4),
            const Text('✅', style: TextStyle(fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _recBtn(String pid, String cid, bool isRec, bool blocked) {
    if (isRec) {
      return GestureDetector(
        onTap: () => _toggle(pid, cid),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 34,
            height: 26,
            decoration: BoxDecoration(
              color: Color.lerp(
                const Color(0xFFE74C3C),
                const Color(0xFFFF6B6B),
                _pulse.value,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFF0000), width: 2),
            ),
            alignment: Alignment.center,
            child: const Text('⏹', style: TextStyle(fontSize: 13)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: blocked ? null : () => _toggle(pid, cid),
      child: Opacity(
        opacity: blocked ? 0.3 : 1.0,
        child: Container(
          width: 34,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF8B4513),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFD2691E)),
          ),
          alignment: Alignment.center,
          child: const Text('🎤', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }

  Widget _tinyBtn(String icon, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(icon, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
