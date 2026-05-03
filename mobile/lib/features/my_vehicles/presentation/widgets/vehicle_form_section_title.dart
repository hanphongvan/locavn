import 'package:flutter/material.dart';

import '../../../../shared/widgets/form/app_form_theme.dart';

class VehicleFormSectionTitle extends StatelessWidget {
  const VehicleFormSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppFormTheme.focusBorder,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
