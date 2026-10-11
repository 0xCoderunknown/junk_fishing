import 'package:flutter/material.dart';
import '../../services/game_data_service.dart';

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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.tealAccent),
              SizedBox(width: 10),
              Text(
                'Settings & About',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.vibration, color: Colors.white70),
            title: const Text('Haptic Feedback', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Vibrate upon timing strike', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Switch(
              value: true,
              activeThumbColor: Colors.tealAccent,
              onChanged: (val) {},
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.volume_up, color: Colors.white70),
            title: const Text('Sound FX', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Water splash and rod tension audio', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Switch(
              value: true,
              activeThumbColor: Colors.tealAccent,
              onChanged: (val) {},
            ),
          ),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
            title: const Text('Reset Save Data', style: TextStyle(color: Colors.redAccent)),
            subtitle: const Text('Restore default 100 coins and 15 bait', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2430),
                  title: const Text('Reset All Progress?', style: TextStyle(color: Colors.white)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Reset', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await gameService.resetPlayerState();
                onReset();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Junk Fishing v1.0.0 • Deterministic Gacha Engine',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
