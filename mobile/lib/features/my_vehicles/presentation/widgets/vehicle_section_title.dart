import 'package:flutter/material.dart';

import '../my_vehicles_palette.dart';

class VehicleSectionTitle extends StatelessWidget {
  const VehicleSectionTitle({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: MyVehiclesPalette.primary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
