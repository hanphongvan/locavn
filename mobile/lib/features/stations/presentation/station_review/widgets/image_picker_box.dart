import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../station_review_compose_theme.dart';

/// Vùng tải ảnh nét đứt + lưới xem trước (thư viện / máy ảnh).
///
/// [useRatingComposeChrome]: giao diện nổi bật cho màn đánh giá; mặc định `false` (vd. báo cáo).
class ImagePickerBox extends StatelessWidget {
  const ImagePickerBox({
    super.key,
    required this.images,
    required this.maxImages,
    required this.onAddImages,
    required this.onRemoveAt,
    this.sectionTitle = 'Hình ảnh (tuỳ chọn)',
    this.useRatingComposeChrome = false,
  });

  final List<XFile> images;
  final int maxImages;
  final ValueChanged<List<XFile>> onAddImages;
  final ValueChanged<int> onRemoveAt;
  final String sectionTitle;
  final bool useRatingComposeChrome;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final remain = maxImages - images.length;
    if (remain <= 0) return;

    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery && remain > 1) {
        final batch = await picker.pickMultiImage(imageQuality: 85);
        if (batch.isEmpty) return;
        final merged = [...images, ...batch.take(remain)];
        onAddImages(merged);
        return;
      }
      final one = await picker.pickImage(source: source, imageQuality: 85);
      if (one == null) return;
      onAddImages([...images, one]);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không chọn được ảnh: $e')),
      );
    }
  }

  void _openSourceSheet(BuildContext context) {
    final remain = maxImages - images.length;
    if (remain <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tối đa $maxImages ảnh.')),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pick(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = images.length < maxImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: useRatingComposeChrome ? FontWeight.w800 : FontWeight.w700,
            color: useRatingComposeChrome
                ? StationReviewComposeTheme.textPrimary
                : StationReviewComposeTheme.primary,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadiusMd),
          child: InkWell(
            onTap: canAdd ? () => _openSourceSheet(context) : null,
            borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadiusMd),
            child: CustomPaint(
              foregroundPainter: _DashedRoundedBorder(
                color: canAdd
                    ? (useRatingComposeChrome
                        ? StationReviewComposeTheme.primary.withValues(alpha: 0.45)
                        : theme.colorScheme.outlineVariant)
                    : theme.colorScheme.outline,
                radius: StationReviewComposeTheme.cardRadiusMd,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: useRatingComposeChrome ? 28 : 22,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: useRatingComposeChrome
                      ? StationReviewComposeTheme.uploadFill
                      : Colors.white,
                  borderRadius: BorderRadius.circular(StationReviewComposeTheme.cardRadiusMd),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: useRatingComposeChrome ? 40 : 36,
                      color: canAdd
                          ? StationReviewComposeTheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Thêm hình ảnh',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: StationReviewComposeTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tối đa $maxImages ảnh',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: useRatingComposeChrome
                            ? StationReviewComposeTheme.textSecondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: useRatingComposeChrome ? FontWeight.w500 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final x = images[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Thumb(file: x),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onRemoveAt(index),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(file.path, fit: BoxFit.cover);
    }
    return Image.file(File(file.path), fit: BoxFit.cover);
  }
}

class _DashedRoundedBorder extends CustomPainter {
  _DashedRoundedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
