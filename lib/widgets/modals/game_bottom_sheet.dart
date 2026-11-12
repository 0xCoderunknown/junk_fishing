import 'package:material_ui/material_ui.dart';

/// Standard dark modal shell for all bottom sheets in Junk Fishing.
///
/// Provides consistent geometry, drag handle, header row, and theme styling:
/// - Rounded top border (Radius 24)
/// - Background #131720
/// - Centered 40x4 drag handle
/// - Standard header row with accent icon, bold title, and optional trailing widget
class GameBottomSheet extends StatelessWidget {
  final double heightFactor;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  const GameBottomSheet({
    super.key,
    this.heightFactor = 0.85,
    this.titleIcon,
    this.titleIconColor,
    this.title,
    this.trailing,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 16),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      decoration: const BoxDecoration(
        color: Color(0xFF131720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header (if title or icon is supplied)
          if (title != null || titleIcon != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(
                      titleIcon,
                      color: titleIconColor ?? Colors.tealAccent,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ?trailing,
                ],
              ),
            ),

          // Modal Body
          Expanded(child: child),
        ],
      ),
    );
  }
}
