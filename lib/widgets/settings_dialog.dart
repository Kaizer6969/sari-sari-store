import 'package:flutter/material.dart';
import '../services/save_manager.dart';
import 'pixel_text.dart';
import 'pixel_button.dart';
import 'pixel_card.dart';

class SettingsDialog extends StatefulWidget {
  final VoidCallback onResetProgress;

  const SettingsDialog({super.key, required this.onResetProgress});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _sfxEnabled = true;
  bool _musicEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: PixelCard(
        backgroundColor: const Color(0xFF1E272C),
        borderColor: const Color(0xFF9E58C4),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text('⚙️', style: TextStyle(fontSize: 22)),
                SizedBox(width: 8),
                PixelText('SETTINGS NG LARO', size: 14, color: Color(0xFFD7BDE2)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),

            // Sound Effects Toggle
            _settingToggle(
              'Tunog (Sound Effects)',
              _sfxEnabled,
              (v) => setState(() => _sfxEnabled = v),
            ),
            const SizedBox(height: 10),

            // Background Music Toggle
            _settingToggle(
              'Musika (Background Music)',
              _musicEnabled,
              (v) => setState(() => _musicEnabled = v),
            ),
            const SizedBox(height: 16),

            // Reset Game Progress Button
            PixelButton(
              label: '🗑️ BURAHIN ANG SAVE DATA',
              fontSize: 10,
              height: 40,
              color: const Color(0xFFC0392B),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1E272C),
                    shape: const BeveledRectangleBorder(
                      side: BorderSide(color: Color(0xFFC0392B), width: 3),
                    ),
                    title: const PixelText('Burahin Lahat?', size: 14, color: Colors.redAccent),
                    content: const PixelText(
                      'Mababura ang buong tindahan mo sa phone at magsisimula ka sa Day 1.',
                      size: 11,
                      color: Colors.white,
                    ),
                    actions: [
                      PixelButton(
                        label: 'Huwag',
                        fontSize: 10,
                        height: 36,
                        color: Colors.grey,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      PixelButton(
                        label: 'Oo, Burahin',
                        fontSize: 10,
                        height: 36,
                        color: const Color(0xFFC0392B),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await SaveManager.deleteSave();
                          widget.onResetProgress();
                          if (mounted) Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 14),
            PixelButton(
              label: 'BUMALIK',
              fontSize: 11,
              height: 38,
              color: const Color(0xFF34495E),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingToggle(String title, bool val, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: const Color(0xFF151D22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PixelText(title, size: 11, color: Colors.white),
          GestureDetector(
            onTap: () => onChanged(!val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: val ? const Color(0xFF27AE60) : Colors.grey.shade700,
              child: PixelText(
                val ? 'BUKAS' : 'PATAY',
                size: 9,
                color: Colors.white,
                hasShadow: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
