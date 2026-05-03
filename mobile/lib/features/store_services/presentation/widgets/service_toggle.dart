import 'package:flutter/material.dart';

/// On/off control: active services are shown to end users; inactive are hidden.
class ServiceToggle extends StatelessWidget {
  const ServiceToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.92,
      child: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF16A34A).withValues(alpha: 0.45),
        activeThumbColor: Colors.white,
      ),
    );
  }
}
