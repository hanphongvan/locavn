import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../auth/presentation/citizen_login_prompt.dart';
import '../../../auth/presentation/widgets/gradient_button.dart';
import '../../../bad_reports/presentation/private_bad_report_compose_sheet.dart';
import '../../../more/presentation/account/account_activity_providers.dart';
import '../../../my_reviews/presentation/my_station_reviews_providers.dart';
import '../../../stations/presentation/station_review/station_review_compose_theme.dart';
import '../../../stations/presentation/station_review_compose_sheet.dart';
import '../station_detail_providers.dart';
import '../station_detail_strings.dart';

/// Bottom bar: rate (gradient) + report (outlined red).
class StationDetailActionButtons extends ConsumerWidget {
  const StationDetailActionButtons({
    super.key,
    required this.stationId,
    required this.displayName,
    this.stationAddress,
  });

  final int stationId;
  final String displayName;
  final String? stationAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: StationReviewComposeTheme.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottom),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GradientButton(
                    label: StationDetailStrings.actionRate,
                    trailingIcon: Icons.star_rounded,
                    gradientColors: const [
                      StationReviewComposeTheme.primary,
                      StationReviewComposeTheme.accent,
                    ],
                    onPressed: () {
                      if (!ref.read(authSessionControllerProvider).isAuthenticated) {
                        showCitizenLoginRequiredPrompt(context);
                        return;
                      }
                      showStationReviewComposeSheet(
                        context: context,
                        stationId: stationId,
                        stationName: displayName,
                        stationAddress: stationAddress,
                        onSubmitted: () {
                          ref.invalidate(stationRatingSummaryProvider(stationId));
                          ref.invalidate(accountActivitySummaryProvider);
                          ref.invalidate(myStationReviewsFirstPageProvider);
                          ref.read(stationReviewListBumpProvider(stationId).notifier).state++;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        if (!ref.read(authSessionControllerProvider).isAuthenticated) {
                          showCitizenLoginRequiredPrompt(context);
                          return;
                        }
                        showPrivateBadReportComposeSheet(
                          context: context,
                          stationId: stationId,
                          stationName: displayName,
                          stationAddress: stationAddress,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                        side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        backgroundColor: const Color(0xFFFFF1F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        StationDetailStrings.actionReport,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
