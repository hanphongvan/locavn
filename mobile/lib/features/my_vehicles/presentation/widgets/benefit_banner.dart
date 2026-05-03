import 'package:flutter/material.dart';

import '../my_vehicles_palette.dart';

class BenefitBanner extends StatelessWidget {
  const BenefitBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MyVehiclesPalette.accentBlue.withValues(alpha: 0.08),
              MyVehiclesPalette.cardTint,
            ],
          ),
          borderRadius: BorderRadius.circular(MyVehiclesPalette.radiusLg),
          border: Border.all(color: MyVehiclesPalette.borderSoft.withValues(alpha: 0.85)),
          boxShadow: MyVehiclesPalette.cardShadow(context, blur: 16, y: 6),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: MyVehiclesPalette.cardShadow(context, blur: 8, y: 2),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: MyVehiclesPalette.accentGreen,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lợi ích khi thêm xe',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MyVehiclesPalette.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _benefitBullet('Tìm cây xăng phù hợp với loại nhiên liệu'),
                  const SizedBox(height: 6),
                  _benefitBullet('Theo dõi chi phí và lịch sử đổ xăng chính xác hơn'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: MyVehiclesPalette.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_gas_station_rounded,
                color: MyVehiclesPalette.accentBlue,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

Widget _benefitBullet(String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Icon(Icons.check_circle_rounded, size: 16, color: MyVehiclesPalette.accentGreen),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: MyVehiclesPalette.muted,
          ),
        ),
      ),
    ],
  );
}
