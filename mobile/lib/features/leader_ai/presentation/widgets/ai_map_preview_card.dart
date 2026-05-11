import 'package:flutter/material.dart';

import 'leader_ai_palette.dart';

/// Placeholder card cho map data Phase 2B — bản đồ thật sẽ render Phase 3
/// (Section 7 yêu cầu placeholder height 140 + nút "Xem bản đồ đầy đủ").
class AiMapPreviewCard extends StatelessWidget {
  const AiMapPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        side: const BorderSide(color: LeaderAiPalette.borderLight),
      ),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: LeaderAiPalette.softBlue,
          borderRadius: BorderRadius.circular(LeaderAiPalette.cardRadius),
        ),
        child: Stack(
          children: [
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 36,
                    color: LeaderAiPalette.primaryNavy,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dữ liệu bản đồ',
                    style: TextStyle(
                      color: LeaderAiPalette.primaryNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng bản đồ sẽ có trong Phase 3.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: LeaderAiPalette.primaryNavy,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Xem bản đồ đầy đủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
