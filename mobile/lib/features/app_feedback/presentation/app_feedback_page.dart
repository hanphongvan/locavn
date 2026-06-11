import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../stations/presentation/station_review/station_review_compose_theme.dart';
import '../../stations/presentation/station_review/widgets/image_picker_box.dart';
import '../data/app_feedback_api.dart';

const int kAppFeedbackMaxContent = 2000;

/// Màn gửi góp ý về ứng dụng (mở từ Tài khoản → Tương tác). Gửi được khi chưa đăng nhập.
class AppFeedbackPage extends ConsumerStatefulWidget {
  const AppFeedbackPage({super.key});

  @override
  ConsumerState<AppFeedbackPage> createState() => _AppFeedbackPageState();
}

class _AppFeedbackPageState extends ConsumerState<AppFeedbackPage> {
  final _content = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final List<XFile> _images = [];

  AppFeedbackCategory _category = AppFeedbackCategory.suggestion;
  bool _busy = false;

  @override
  void dispose() {
    _content.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSubmit => _content.text.trim().isNotEmpty && !_busy;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(appFeedbackApiProvider);

      List<String>? imageUrls;
      if (_images.isNotEmpty) {
        imageUrls = <String>[];
        for (final x in _images) {
          imageUrls.add(await api.uploadImage(x));
        }
      }

      await api.submit(
        category: _category,
        content: _content.text,
        contactEmail: _email.text,
        contactPhone: _phone.text,
        imageUrls: imageUrls,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).maybePop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đã gửi góp ý. Cảm ơn bạn đã đóng góp!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không gửi được: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                    onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: StationReviewComposeTheme.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Góp ý ứng dụng',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: StationReviewComposeTheme.primary,
                          ),
                        ),
                        Text(
                          'Phản ánh lỗi hoặc đề xuất để chúng tôi cải thiện ứng dụng',
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
                        _SectionLabel('Loại góp ý'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: [
                            for (final c in AppFeedbackCategory.values)
                              ChoiceChip(
                                label: Text(c.label),
                                selected: _category == c,
                                onSelected: _busy ? null : (_) => setState(() => _category = c),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _SectionLabel('Nội dung góp ý'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _content,
                          enabled: !_busy,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: kAppFeedbackMaxContent,
                          textInputAction: TextInputAction.newline,
                          decoration: const InputDecoration(
                            hintText: 'Mô tả chi tiết lỗi gặp phải hoặc ý tưởng của bạn…',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _SectionLabel('Thông tin liên hệ (tuỳ chọn)'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phone,
                          enabled: !_busy,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 22),
                        ImagePickerBox(
                          images: _images,
                          maxImages: AppFeedbackApi.maxImages,
                          onAddImages: (next) => setState(() {
                            _images
                              ..clear()
                              ..addAll(next);
                          }),
                          onRemoveAt: (i) => setState(() => _images.removeAt(i)),
                          sectionTitle: 'Ảnh đính kèm (tuỳ chọn)',
                        ),
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
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: _busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Gửi góp ý'),
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: StationReviewComposeTheme.primary,
          ),
    );
  }
}
