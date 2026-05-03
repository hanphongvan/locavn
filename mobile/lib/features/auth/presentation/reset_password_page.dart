import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../data/password_reset_api.dart';
import 'reset_password_controller.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';
import 'widgets/login_screen_theme.dart';
import 'widgets/login_text_field.dart';

/// Đặt lại mật khẩu — `POST /api/auth/reset-password` (token từ query `?token=`).
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  String? _submitError;
  bool _success = false;
  String? _successMessage;
  bool _obscure1 = true;
  bool _obscure2 = true;

  String? get _token => widget.initialToken?.trim();

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _submitError = null;
      _success = false;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final res = await ref
          .read(resetPasswordControllerProvider.notifier)
          .submit(
            token: token,
            newPassword: _pw.text,
            confirmPassword: _pw2.text,
          );
      if (!mounted) return;
      if (res.ok) {
        setState(() {
          _success = true;
          _successMessage = res.message;
          _submitError = null;
        });
      } else {
        setState(() => _submitError = res.message);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Đặt lại mật khẩu thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tokenMissing = _token == null || _token!.isEmpty;
    final submitting = ref.watch(resetPasswordControllerProvider).isLoading;

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
                              tooltip: 'Quay lại đăng nhập',
                              onPressed: submitting
                                  ? null
                                  : () => context.go(AppRoute.login),
                              icon: Icon(Icons.arrow_back_rounded, color: LoginScreenTheme.titleBlue),
                            ),
                          ],
                        ),
                        Text(
                          'Đặt lại mật khẩu',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: LoginScreenTheme.titleBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (tokenMissing) ...[
                          Text(
                            'Liên kết đặt lại mật khẩu không hợp lệ.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go(AppRoute.login),
                            style: TextButton.styleFrom(foregroundColor: LoginScreenTheme.gradientStart),
                            child: const Text('Về đăng nhập'),
                          ),
                        ]
                        else if (_success) ...[
                          Text(
                            _successMessage ?? ResetPasswordResult.defaultSuccess,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: LoginScreenTheme.titleBlue,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GradientButton(
                            label: 'ĐĂNG NHẬP',
                            loading: false,
                            onPressed: () => context.go(AppRoute.login),
                          ),
                        ] else ...[
                          Text(
                            'Mật khẩu mới phải có ít nhất 6 ký tự và khớp ô xác nhận.',
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
                                    label: 'Xác nhận mật khẩu',
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
                                    onFieldSubmitted: (_) {
                                      if (!submitting) _submit();
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
                            label: 'ĐẶT LẠI MẬT KHẨU',
                            loading: submitting,
                            onPressed: _submit,
                          ),
                        ],
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
