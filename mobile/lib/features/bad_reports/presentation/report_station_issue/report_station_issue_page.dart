import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/bad_reports_api.dart';
import '../../../stations/presentation/station_review/station_review_compose_theme.dart';
import '../../../stations/presentation/station_review/widgets/image_picker_box.dart';
import '../../../stations/presentation/station_review/widgets/station_info_card.dart';
import '../private_bad_report_compose_sheet.dart';
import 'bad_report_submit_controller.dart';
import 'violation_options.dart';
import 'widgets/description_box.dart';
import 'widgets/report_notice_box.dart';
import 'widgets/submit_report_button.dart';
import 'widgets/violation_type_selector.dart';

const int kBadReportComposeMaxDescription = 500;

class ReportStationIssuePage extends ConsumerStatefulWidget {
  const ReportStationIssuePage({
    super.key,
    this.stationId,
    this.stationName,
    this.stationAddress,
  });

  final int? stationId;
  final String? stationName;
  final String? stationAddress;

  @override
  ConsumerState<ReportStationIssuePage> createState() => _ReportStationIssuePageState();
}

class _ReportStationIssuePageState extends ConsumerState<ReportStationIssuePage> {
  final _description = TextEditingController();
  final Set<String> _violationIds = {};
  final List<XFile> _images = [];
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_violationIds.isEmpty) return;

    final controller = ref.read(
      badReportSubmitControllerProvider(widget.stationId).notifier,
    );
    // Re-entry guard — controller đã loading thì bỏ qua tap thừa.
    if (ref.read(badReportSubmitControllerProvider(widget.stationId)).isLoading ||
        _busy) {
      return;
    }

    final desc = _description.text;
    // TextField.maxLength đã chặn input >500 ở UI; `.take()` chỉ là defensive identity.
    final clipped = desc.characters.take(kBadReportComposeMaxDescription).toString();
    final content = buildBadReportApiContent(
      violationIds: _violationIds,
      extraDescription: clipped.trim().isEmpty ? null : clipped,
    );

    if (_images.isNotEmpty && ref.read(portalSessionScopeProvider) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để đính kèm ảnh.'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      List<String>? imageUrls;
      if (_images.isNotEmpty) {
        final api = ref.read(badReportsApiProvider);
        imageUrls = <String>[];
        for (final x in _images) {
          final url = await api.uploadBadReportImage(x);
          if (!isBadReportImageUrlAllowed(url)) {
            throw const FormatException('URL ảnh từ máy chủ không hợp lệ.');
          }
          imageUrls.add(url);
        }
      }

      await controller.submit(content: content, imageUrls: imageUrls);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo. Cảm ơn bạn!'),
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _cardTitle {
    final n = widget.stationName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final id = widget.stationId;
    if (id != null) return 'Cây xăng #$id';
    return 'Báo cáo vi phạm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Chỉ rebuild khi loading flag đổi, không phải mọi state đổi.
    final submitting = ref.watch(
      badReportSubmitControllerProvider(widget.stationId)
          .select((s) => s.isLoading),
    );
    final blocking = submitting || _busy;

    return Scaffold(
      backgroundColor: StationReviewComposeTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: blocking ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: StationReviewComposeTheme.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo vi phạm',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: StationReviewComposeTheme.primary,
                          ),
                        ),
                        Text(
                          'Gửi phản ánh để cơ quan quản lý xử lý',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StationInfoCard(
                          stationName: _cardTitle,
                          address: widget.stationAddress,
                        ),
                        const SizedBox(height: 22),
                        ViolationTypeSelector(
                          selectedIds: _violationIds,
                          onSelectionChanged: (ids) => setState(() {
                            _violationIds
                              ..clear()
                              ..addAll(ids);
                          }),
                        ),
                        const SizedBox(height: 22),
                        DescriptionBox(
                          controller: _description,
                          maxLength: kBadReportComposeMaxDescription,
                        ),
                        const SizedBox(height: 22),
                        ImagePickerBox(
                          images: _images,
                          maxImages: kBadReportMaxImageUrls,
                          onAddImages: (next) => setState(() {
                            _images
                              ..clear()
                              ..addAll(next);
                          }),
                          onRemoveAt: (i) => setState(() => _images.removeAt(i)),
                          sectionTitle: 'Ảnh đính kèm (tuỳ chọn)',
                        ),
                        const SizedBox(height: 20),
                        const ReportNoticeBox(),
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
                  child: SubmitReportButton(
                    enabled: _violationIds.isNotEmpty,
                    loading: blocking,
                    onPressed: _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
