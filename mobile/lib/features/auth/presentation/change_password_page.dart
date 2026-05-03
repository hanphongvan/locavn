import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import 'change_password_controller.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';
import 'widgets/login_screen_theme.dart';
import 'widgets/login_text_field.dart';

/// Đổi mật khẩu — `POST /api/auth/change-password` (JWT), hash đồng bộ đăng ký / đăng nhập legacy.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _submitError;
  bool _obscure0 = true;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _current.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final res = await ref
          .read(changePasswordControllerProvider.notifier)
          .submit(
            currentPassword: _current.text,
            newPassword: _pw.text,
            confirmPassword: _pw2.text,
          );
      if (!mounted) return;
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message.isEmpty ? 'Đã đổi mật khẩu.' : res.message)),
        );
        context.pop(true);
      } else {
        setState(() => _submitError = res.message.isEmpty ? 'Không đổi được mật khẩu.' : res.message);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Đổi mật khẩu thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final submitting = ref.watch(changePasswordControllerProvider).isLoading;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Quay lại',
                              onPressed: submitting
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      }
                                    },
                              icon: Icon(Icons.arrow_back_rounded, color: LoginScreenTheme.titleBlue),
                            ),
                          ],
                        ),
                        Text(
                          'Đổi mật khẩu',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: LoginScreenTheme.titleBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mật khẩu mới phải có ít nhất 6 ký tự và khác mật khẩu hiện tại.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: LoginScreenTheme.titleBlue.withValues(alpha: 0.75),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(LoginScreenTheme.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LoginTextField(
                                  label: 'Mật khẩu hiện tại',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  controller: _current,
                                  enabled: !submitting,
                                  obscureText: _obscure0,
                                  textInputAction: TextInputAction.next,
                                  suffix: IconButton(
                                    tooltip: _obscure0 ? 'Hiện' : 'Ẩn',
                                    onPressed: submitting ? null : () => setState(() => _obscure0 = !_obscure0),
                                    icon: Icon(
                                      _obscure0 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: LoginScreenTheme.titleBlue.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Bắt buộc';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                LoginTextField(
                                  label: 'Mật khẩu mới',
                                  prefixIcon: Icons.vpn_key_outlined,
                                  controller: _pw,
                                  enabled: !submitting,
                                  obscureText: _obscure1,
                                  textInputAction: TextInputAction.next,
                                  suffix: IconButton(
                                    tooltip: _obscure1 ? 'Hiện' : 'Ẩn',
                                    onPressed: submitting ? null : () => setState(() => _obscure1 = !_obscure1),
                                    icon: Icon(
                                      _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: LoginScreenTheme.titleBlue.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Bắt buộc';
                                    if (v.length < 6) return 'Tối thiểu 6 ký tự';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                LoginTextField(
                                  label: 'Xác nhận mật khẩu mới',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  controller: _pw2,
                                  enabled: !submitting,
                                  obscureText: _obscure2,
                                  textInputAction: TextInputAction.done,
                                  suffix: IconButton(
                                    tooltip: _obscure2 ? 'Hiện' : 'Ẩn',
                                    onPressed: submitting ? null : () => setState(() => _obscure2 = !_obscure2),
                                    icon: Icon(
                                      _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: LoginScreenTheme.titleBlue.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Bắt buộc';
                                    if (v != _pw.text) return 'Mật khẩu không khớp';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_submitError != null) ...[
                          const SizedBox(height: 10),
                          Material(
                            color: scheme.errorContainer,
                            borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _submitError!,
                                      style: textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        GradientButton(
                          label: 'LƯU MẬT KHẨU MỚI',
                          loading: submitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
