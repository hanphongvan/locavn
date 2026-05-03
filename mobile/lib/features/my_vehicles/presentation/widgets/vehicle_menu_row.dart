import 'package:flutter/material.dart';

import '../my_vehicles_palette.dart';

class VehicleMenuRow extends StatelessWidget {
  const VehicleMenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? Colors.red : MyVehiclesPalette.navy;
    return Row(
      children: [
        Icon(icon, size: 20, color: c),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
