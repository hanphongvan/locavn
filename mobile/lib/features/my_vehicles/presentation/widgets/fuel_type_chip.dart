import 'package:flutter/material.dart';

import '../my_vehicles_palette.dart';

class FuelTypeChip extends StatelessWidget {
  const FuelTypeChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MyVehiclesPalette.borderSoft),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: MyVehiclesPalette.primary,
        ),
      ),
    );
  }
}
