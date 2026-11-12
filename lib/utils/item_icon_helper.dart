import 'package:material_ui/material_ui.dart';

IconData getItemIconData(String iconName) {
  switch (iconName) {
    case 'memory':
      return Icons.memory;
    case 'description':
      return Icons.description;
    case 'hiking':
      return Icons.hiking;
    case 'headphones':
      return Icons.headphones;
    case 'save':
      return Icons.save;
    case 'radio_button_checked':
      return Icons.radio_button_checked;
    case 'change_history':
      return Icons.change_history;
    case 'cleaning_services':
      return Icons.cleaning_services;
    case 'kitchen':
      return Icons.kitchen;
    case 'pest_control':
      return Icons.pest_control;
    case 'sports_baseball':
      return Icons.sports_baseball;
    case 'phone_android':
      return Icons.phone_android;
    case 'smart_toy':
      return Icons.smart_toy;
    case 'bolt':
      return Icons.bolt;
    case 'key':
      return Icons.vpn_key;
    case 'router':
      return Icons.router;
    case 'cassette_tape':
      return Icons.album;
    default:
      return Icons.category;
  }
}

Color getRarityColor(int rarity) {
  switch (rarity) {
    case 1:
      return const Color(0xFF9E9E9E); // Common Grey
    case 2:
      return const Color(0xFF4CAF50); // Uncommon Emerald
    case 3:
      return const Color(0xFF29B6F6); // Rare Cyan
    case 4:
      return const Color(0xFFAB47BC); // Epic Purple
    case 5:
      return const Color(0xFFFFB300); // Legendary Amber/Gold
    default:
      return const Color(0xFF9E9E9E);
  }
}
