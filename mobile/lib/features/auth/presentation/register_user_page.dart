import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../data/register_user_models.dart';
import '../data/register_user_providers.dart';
import 'register_user_controller.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';
import 'widgets/login_brand_logo.dart';
import 'widgets/login_screen_theme.dart';
import 'widgets/login_text_field.dart';

/// Đăng ký người dùng — giao diện đồng bộ [LoginPage] (nền, thẻ trắng, trường nhập, nút gradient).
class RegisterUserPage extends ConsumerStatefulWidget {
  const RegisterUserPage({super.key});

  @override
  ConsumerState<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends ConsumerState<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _displayCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _submitError;
  bool? _usernameTaken;

  bool _obscurePw = true;
  bool _obscurePw2 = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _displayCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUsernameBlur() async {
    final u = _userCtrl.text.trim();
    setState(() => _usernameTaken = null);
    if (u.isEmpty) return;
    try {
      final api = ref.read(registerUserApiProvider);
      final r = await api.checkUserName(u);
      if (!mounted) return;
      setState(() => _usernameTaken = r.taken);
    } catch (_) {
      if (mounted) setState(() => _usernameTaken = null);
    }
  }

  String? _optionalEmail(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!t.contains('@')) return 'Email không hợp lệ';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_usernameTaken == true) {
      setState(() => _submitError = 'Tên đã tồn tại.');
      return;
    }

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final addr = _addressCtrl.text.trim();

    final body = RegisterUserRequestDto(
      userName: _userCtrl.text.trim(),
      displayName: _displayCtrl.text.trim(),
      password: _pwCtrl.text,
      confirmPassword: _pw2Ctrl.text,
      email: email.isEmpty ? null : email,
      phone: phone.isEmpty ? null : phone,
      address: addr.isEmpty ? null : addr,
      isActived: false,
      loai: 5,
      donViId: null,
      roles: const <RoleSelectionDto>[],
      dVs: const <DonViSelectionDto>[],
    );

    try {
      final res = await ref
          .read(registerUserControllerProvider.notifier)
          .submit(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo tài khoản ${res.userName}. Vui lòng đăng nhập.')),
      );
      context.go(AppRoute.login);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitError = 'Đăng ký thất bại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final logoSize = MediaQuery.sizeOf(context).shortestSide < 360 ? 64.0 : 80.0;
    final submitting = ref.watch(registerUserControllerProvider).isLoading;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                        : () {
                                            if (context.canPop()) {
                                              context.pop();
                                            } else {
                                              context.go(AppRoute.login);
                                            }
                                          },
                                    icon: Icon(Icons.arrow_back_rounded, color: LoginScreenTheme.titleBlue),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                              Center(child: LoginBrandLogo(size: logoSize)),
                              const SizedBox(height: 12),
                              Text(
                                'Đăng ký tài khoản',
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  color: LoginScreenTheme.titleBlue,
                                  fontWeight: FontWeight.w800,
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
                                          label: 'Tên đăng nhập',
                                        
                                          prefixIcon: Icons.person_outline_rounded,
                                          controller: _userCtrl,
                                          enabled: !submitting,
                                          textInputAction: TextInputAction.next,
                                          onEditingComplete: _onUsernameBlur,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                                            return null;
                                          },
                                        ),
                                        if (_usernameTaken == true) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Tên đã tồn tại.',
                                            style: textTheme.bodySmall?.copyWith(color: scheme.error),
                                          ),
                                        ],
                                        const SizedBox(height: 16),
                                        LoginTextField(
                                          label: 'Tên hiển thị',
                                          prefixIcon: Icons.badge_outlined,
                                          controller: _displayCtrl,
                                          enabled: !submitting,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        LoginTextField(
                                          label: 'Mật khẩu',
                                          prefixIcon: Icons.lock_outline_rounded,
                                          controller: _pwCtrl,
                                          enabled: !submitting,
                                          obscureText: _obscurePw,
                                          textInputAction: TextInputAction.next,
                                          suffix: IconButton(
                                            tooltip: _obscurePw ? 'Hiện' : 'Ẩn',
                                            onPressed: submitting ? null : () => setState(() => _obscurePw = !_obscurePw),
                                            icon: Icon(
                                              _obscurePw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                          controller: _pw2Ctrl,
                                          enabled: !submitting,
                                          obscureText: _obscurePw2,
                                          textInputAction: TextInputAction.next,
                                          suffix: IconButton(
                                            tooltip: _obscurePw2 ? 'Hiện' : 'Ẩn',
                                            onPressed: submitting ? null : () => setState(() => _obscurePw2 = !_obscurePw2),
                                            icon: Icon(
                                              _obscurePw2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                              color: LoginScreenTheme.titleBlue.withValues(alpha: 0.55),
                                            ),
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return 'Bắt buộc';
                                            if (v != _pwCtrl.text) return 'Mật khẩu không khớp';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        LoginTextField(
                                          label: 'Email (tuỳ chọn)',
                                          prefixIcon: Icons.mail_outline_rounded,
                                          controller: _emailCtrl,
                                          enabled: !submitting,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: _optionalEmail,
                                        ),
                                        const SizedBox(height: 16),
                                        LoginTextField(
                                          label: 'Điện thoại (tuỳ chọn)',
                                          prefixIcon: Icons.phone_outlined,
                                          controller: _phoneCtrl,
                                          enabled: !submitting,
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
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
                                const SizedBox(height: 14),
                                GradientButton(
                                  label: 'HOÀN TẤT ĐĂNG KÝ',
                                  loading: submitting,
                                  onPressed: _submit,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
