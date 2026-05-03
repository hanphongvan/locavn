import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import 'forgot_password_controller.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';
import 'widgets/login_screen_theme.dart';
import 'widgets/login_text_field.dart';

/// Quên mật khẩu — `POST /api/auth/forgot-password`.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String? _serverMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Vui lòng nhập email';
    if (!t.contains('@') || t.length < 5) return 'Email không hợp lệ';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _serverMessage = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final res = await ref
          .read(forgotPasswordControllerProvider.notifier)
          .submit(email: _emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _serverMessage = res.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverMessage = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _serverMessage = 'Không gửi được yêu cầu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final loading = ref.watch(forgotPasswordControllerProvider).isLoading;

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
                              onPressed: loading
                                  ? null
                                  : () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go(AppRoute.login);
                                      }
                                    },
                              icon: Icon(Icons.arrow_back_rounded, color: LoginScreenTheme.titleBlue),
                            ),
                          ],
                        ),
                        Text(
                          'Quên mật khẩu',
                          textAlign: TextAlign.center,
                          style: textTheme.titleLarge?.copyWith(
                            color: LoginScreenTheme.titleBlue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhập email đã đăng ký. Chúng tôi sẽ gửi hướng dẫn đặt lại mật khẩu nếu email tồn tại.',
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
                                  label: 'Email',
                                  hint: 'ten@email.com',
                                  prefixIcon: Icons.email_outlined,
                                  controller: _emailCtrl,
                                  enabled: !loading,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.email],
                                  onFieldSubmitted: (_) {
                                    if (!loading) _submit();
                                  },
                                  validator: _validateEmail,
                                ),
                                if (_serverMessage != null) ...[
                                  const SizedBox(height: 14),
                                  Material(
                                    color: scheme.primaryContainer.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.mark_email_read_outlined, color: scheme.primary, size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _serverMessage!,
                                              style: textTheme.bodyMedium?.copyWith(
                                                color: LoginScreenTheme.titleBlue,
                                                height: 1.45,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                GradientButton(
                                  label: 'GỬI YÊU CẦU',
                                  loading: loading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
                          ),
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
