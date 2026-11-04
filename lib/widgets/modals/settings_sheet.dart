import 'package:flutter/material.dart';

import '../../services/game_data_service.dart';
import 'game_bottom_sheet.dart';

class SettingsSheet extends StatelessWidget {
  final GameDataService gameService;
  final VoidCallback onReset;

  const SettingsSheet({
    super.key,
    required this.gameService,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return GameBottomSheet(
      heightFactor: 0.55,
      titleIcon: Icons.tune,
      titleIconColor: Colors.tealAccent,
      title: 'Settings & About',
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vibration, color: Colors.white70),
            title: const Text(
              'Haptic Feedback',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Vibrate upon timing strike',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Switch(
              value: true,
              activeThumbColor: Colors.tealAccent,
              onChanged: null, // Always enabled
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volume_up, color: Colors.white70),
            title: const Text(
              'Sound FX',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Audio effects (upcoming)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Switch(
              value: false,
              activeThumbColor: Colors.tealAccent,
              onChanged: null, // Audio stubbed
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
            title: const Text(
              'Reset Save Data',
              style: TextStyle(color: Colors.redAccent),
            ),
            subtitle: const Text(
              'Restore default 150 coins and 20 bait',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2430),
                  title: const Text(
                    'Reset All Progress?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'This will erase your inventory and reset your scrap coins.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await gameService.resetPlayerState();
                onReset();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'JUNK FISHING v0.1.3 • AI Built & Maintained',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
