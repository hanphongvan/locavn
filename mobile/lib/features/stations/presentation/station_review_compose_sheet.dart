import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import 'station_review/station_review_compose_theme.dart';
import 'station_review_submit_controller.dart';
import 'station_review/widgets/comment_box.dart';
import 'station_review/widgets/rating_compose_background.dart';
import 'station_review/widgets/rating_compose_header.dart';
import 'station_review/widgets/rating_overview_card.dart';
import 'station_review/widgets/station_card.dart';
import 'station_review/widgets/submit_button.dart';

/// UI cap (server allows longer comment / more URLs).
const int kStationReviewComposeMaxComment = 500;

/// Public review API upper bounds (see `StationReviewRequestValidator` on server).
const int kStationReviewMaxCommentLength = 2000;
const int kStationReviewMaxImageUrls = 10;
const int kStationReviewMaxImageUrlLength = 2048;

/// Whether [raw] is allowed as `imageUrls[]` on `POST /api/stations/{id}/reviews`.
bool isStationReviewImageUrlAllowed(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t.length > kStationReviewMaxImageUrlLength) return false;
  final uri = Uri.tryParse(t);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  return uri.isScheme('https') || uri.isScheme('http');
}

/// Compose public review → `POST /api/stations/{id}/reviews` (real API).
///
/// Images from gallery/camera are shown in-app; the server currently accepts
/// **https/http URLs only** (no multipart upload). Local files are omitted from
/// the request with an explanatory snackbar after a successful submit.
Future<void> showStationReviewComposeSheet({
  required BuildContext context,
  required int stationId,
  required String stationName,
  String? stationAddress,
  VoidCallback? onSubmitted,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => StationReviewComposePage(
        stationId: stationId,
        stationName: stationName,
        stationAddress: stationAddress,
        onSubmitted: onSubmitted,
      ),
    ),
  );
}

class StationReviewComposePage extends ConsumerStatefulWidget {
  const StationReviewComposePage({
    super.key,
    required this.stationId,
    required this.stationName,
    this.stationAddress,
    this.onSubmitted,
  });

  final int stationId;
  final String stationName;
  final String? stationAddress;
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<StationReviewComposePage> createState() => _StationReviewComposePageState();
}

class _StationReviewComposePageState extends ConsumerState<StationReviewComposePage> {
  final _comment = TextEditingController();
  int? _rating;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final r = _rating;
    if (r == null || r < 1 || r > 5) return;

    final controller = ref.read(
      stationReviewSubmitControllerProvider(widget.stationId).notifier,
    );
    // Re-entry guard — controller đã loading thì bỏ qua tap thừa.
    if (ref.read(stationReviewSubmitControllerProvider(widget.stationId)).isLoading) {
      return;
    }

    final rawComment = _comment.text;
    final clipped = rawComment.characters.take(kStationReviewComposeMaxComment).toString();

    try {
      await controller.submit(
        rating: r,
        comment: clipped.isEmpty ? null : clipped,
        imageUrls: null,
      );

      if (!mounted) return;
      widget.onSubmitted?.call();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cảm ơn bạn đã đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không gửi được: $e')),
      );
    }
  }

  Widget _whiteSection(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadius),
        border: Border.all(color: StationReviewComposeTheme.cardBorder.withValues(alpha: 0.65)),
        boxShadow: StationReviewComposeTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final submitting = ref.watch(
      stationReviewSubmitControllerProvider(widget.stationId)
          .select((s) => s.isLoading),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RatingComposeBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RatingComposeHeader(
                onBack: () => Navigator.of(context).maybePop(),
                backEnabled: !submitting,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StationCard(
                            stationName: widget.stationName,
                            address: widget.stationAddress,
                          ),
                          const SizedBox(height: 22),
                          RatingOverviewCard(
                            rating: _rating,
                            onRatingChanged: (v) => setState(() => _rating = v),
                          ),
                          const SizedBox(height: 22),
                          _whiteSection(
                            CommentBox(
                              controller: _comment,
                              maxLength: kStationReviewComposeMaxComment,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ImageUploadComingSoonBanner(theme: Theme.of(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottom),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SubmitButton(
                      enabled: _rating != null,
                      loading: submitting,
                      onPressed: _submit,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner thay thế ImagePickerBox khi backend chưa hỗ trợ multipart upload.
///
/// Cùng pattern với `_ImageUploadComingSoonBanner` ở `report_station_issue_page.dart`
/// (PR 4 cho bad_reports). Body text tailored cho ngữ cảnh đánh giá thay vì báo cáo
/// vi phạm. Khi backend triển khai endpoint upload, replace banner này bằng
/// `ImagePickerBox` cũ (kèm logic upload → URL → submit). Cân nhắc lúc đó promote
/// banner thành `shared/widgets/coming_soon_banner.dart` parameterize title+body.
class _ImageUploadComingSoonBanner extends StatelessWidget {
  const _ImageUploadComingSoonBanner({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đính kèm ảnh sẽ ra mắt sau',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: StationReviewComposeTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hệ thống hiện chưa hỗ trợ đính kèm ảnh từ máy. Bạn có thể đánh giá bằng số sao và bình luận; ảnh sẽ được hỗ trợ trong bản cập nhật sau.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
