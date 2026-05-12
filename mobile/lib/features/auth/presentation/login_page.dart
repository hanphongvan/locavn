import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_info/package_info_provider.dart';
import '../../../core/auth/admin_auth_repository.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/biometric/biometric_login_coordinator.dart';
import '../../../core/auth/biometric/biometric_providers.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/auth/apple/apple_sign_in_service.dart';
import '../../../core/auth/google/google_sign_in_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/role_home_navigation.dart';
import 'widgets/feature_badge.dart';
import 'widgets/gradient_button.dart';
import 'widgets/login_background.dart';
import 'widgets/login_brand_logo.dart';
import 'widgets/login_screen_theme.dart';
import 'widgets/login_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final auth = ref.read(authSessionControllerProvider);
      await auth.login(_userCtrl.text, _passCtrl.text);
      if (!mounted) return;
      await BiometricLoginCoordinator.onPasswordLoginSuccess(
        ref: ref,
        context: context,
        username: _userCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      final loai = auth.session!.loai;
      final home = roleHomeLocationForLoai(loai);
      if (home == null) {
        context.go(AppRoute.accessDenied);
        return;
      }
      context.go(home);
    } on UnsupportedPortalLoaiException {
      if (mounted) {
        context.go(AppRoute.accessDenied);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorUserMessage(e) ?? 'Đăng nhập thất bại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForgotPassword() {
    if (_loading) return;
    context.push(AppRoute.forgotPassword);
  }

  Future<void> _onGoogleLoginPressed() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authSessionControllerProvider);
      final ok = await auth.loginWithGoogle();
      if (!mounted) return;
      if (!ok) {
        // User cancel chooser — không hiện lỗi.
        return;
      }
      final loai = auth.session!.loai;
      final home = roleHomeLocationForLoai(loai);
      if (home == null) {
        context.go(AppRoute.accessDenied);
        return;
      }
      context.go(home);
    } on UnsupportedPortalLoaiException {
      if (mounted) context.go(AppRoute.accessDenied);
    } on GoogleSignInException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorUserMessage(e) ?? 'Đăng nhập Google thất bại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAppleLoginPressed() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authSessionControllerProvider);
      final ok = await auth.loginWithApple();
      if (!mounted) return;
      if (!ok) {
        // User cancel Apple sheet — không hiện lỗi.
        return;
      }
      final loai = auth.session!.loai;
      final home = roleHomeLocationForLoai(loai);
      if (home == null) {
        context.go(AppRoute.accessDenied);
        return;
      }
      context.go(home);
    } on UnsupportedPortalLoaiException {
      if (mounted) context.go(AppRoute.accessDenied);
    } on AppleSignInException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = dioErrorUserMessage(e) ?? 'Đăng nhập Apple thất bại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onBiometricLoginPressed(BiometricLoginUiState ui) async {
    if (_loading) return;
    if (ui.kind != BiometricLoginUiKind.ready) return;

    setState(() => _loading = true);
    setState(() => _error = null);
    try {
      final auth = ref.read(authSessionControllerProvider);
      final ok = await BiometricLoginCoordinator.loginWithBiometric(
        ref: ref,
        context: context,
        sessionController: auth,
      );
      if (!mounted || !ok) return;
      final loai = auth.session!.loai;
      final home = roleHomeLocationForLoai(loai);
      if (home == null) {
        context.go(AppRoute.accessDenied);
        return;
      }
      context.go(home);
    } on UnsupportedPortalLoaiException {
      if (mounted) {
        context.go(AppRoute.accessDenied);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = BiometricLoginCoordinator.loginErrorMessage(e) ?? 'Đăng nhập thất bại.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packageInfoAsync = ref.watch(packageInfoProvider);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final logoSize = MediaQuery.sizeOf(context).shortestSide < 360 ? 88.0 : 112.0;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8 + bottomInset),
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
                              const SizedBox(height: 8),
                              Center(child: LoginBrandLogo(size: logoSize)),
                              const SizedBox(height: 20),
                              Text(
                                'Quanh tôi',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: LoginScreenTheme.titleBlue,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Tìm cây xăng, chợ, siêu thị',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: LoginScreenTheme.titleBlue.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
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
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      LoginTextField(
                                        label: 'Tên đăng nhập / Số điện thoại',
                                        hint: 'Nhập tên đăng nhập hoặc số điện thoại',
                                        prefixIcon: Icons.person_outline_rounded,
                                        controller: _userCtrl,
                                        enabled: !_loading,
                                        textInputAction: TextInputAction.next,
                                        keyboardType: TextInputType.text,
                                        autofillHints: const [AutofillHints.username],
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Vui lòng nhập tên đăng nhập hoặc số điện thoại';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),
                                      LoginTextField(
                                        label: 'Mật khẩu',
                                        hint: 'Nhập mật khẩu',
                                        prefixIcon: Icons.lock_outline_rounded,
                                        controller: _passCtrl,
                                        enabled: !_loading,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        onFieldSubmitted: (_) {
                                          if (!_loading) _submit();
                                        },
                                        suffix: IconButton(
                                          tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                          onPressed: _loading
                                              ? null
                                              : () => setState(() => _obscurePassword = !_obscurePassword),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: LoginScreenTheme.titleBlue.withValues(alpha: 0.55),
                                          ),
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Vui lòng nhập mật khẩu';
                                          }
                                          return null;
                                        },
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _loading ? null : _openForgotPassword,
                                          style: TextButton.styleFrom(
                                            foregroundColor: LoginScreenTheme.gradientStart,
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                            // a11y: giữ Material default tap target ≥ 48dp.
                                          ),
                                          child: const Text('Quên mật khẩu?'),
                                        ),
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 4),
                                        Semantics(
                                          container: true,
                                          liveRegion: true,
                                          label: 'Lỗi đăng nhập',
                                          child: Material(
                                            color: scheme.errorContainer,
                                            borderRadius: BorderRadius.circular(
                                              LoginScreenTheme.controlRadius,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 22),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      _error!,
                                                      style: textTheme.bodyMedium?.copyWith(
                                                        color: scheme.onErrorContainer,
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      GradientButton(
                                        label: 'ĐĂNG NHẬP',
                                        loading: _loading,
                                        onPressed: _submit,
                                      ),
                                      const SizedBox(height: 12),
                                      Center(
                                        child: TextButton(
                                          onPressed: _loading ? null : () => context.push(AppRoute.register),
                                          style: TextButton.styleFrom(
                                            foregroundColor: LoginScreenTheme.gradientStart,
                                            textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          child: const Text('Đăng ký tài khoản'),
                                        ),
                                      ),
                                      Consumer(
                                        builder: (context, ref, _) {
                                          final asyncUi = ref.watch(biometricLoginUiProvider);
                                          return asyncUi.when(
                                            loading: () => const SizedBox.shrink(),
                                            error: (err, st) => const SizedBox.shrink(),
                                            data: (ui) {
                                              if (!ui.showButton) {
                                                return const SizedBox.shrink();
                                              }
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  const SizedBox(height: 20),
                                                  const _OrDivider(),
                                                  const SizedBox(height: 16),
                                                  OutlinedButton.icon(
                                                    onPressed: _loading
                                                        ? null
                                                        : () => _onBiometricLoginPressed(ui),
                                                    icon: Icon(
                                                      Icons.fingerprint_rounded,
                                                      color: LoginScreenTheme.gradientStart,
                                                    ),
                                                    label: Text(
                                                      ui.buttonLabel,
                                                      style: textTheme.labelLarge?.copyWith(
                                                        color: LoginScreenTheme.titleBlue,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: LoginScreenTheme.titleBlue,
                                                      side: const BorderSide(color: LoginScreenTheme.fieldBorder),
                                                      padding: const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                        horizontal: 12,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(
                                                          LoginScreenTheme.controlRadius,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      _GoogleLoginSection(
                                        loading: _loading,
                                        onPressed: _onGoogleLoginPressed,
                                      ),
                                      _AppleLoginSection(
                                        loading: _loading,
                                        onPressed: _onAppleLoginPressed,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Wrap(
                                alignment: WrapAlignment.spaceEvenly,
                                spacing: 12,
                                runSpacing: 16,
                                children: const [
                                  FeatureBadge(
                                    icon: Icons.location_on_rounded,
                                    text: 'Theo dõi mọi lúc',
                                    iconColor: LoginScreenTheme.gradientStart,
                                  ),
                                  FeatureBadge(
                                    icon: Icons.verified_user_rounded,
                                    text: 'Minh bạch, tin cậy',
                                    iconColor: LoginScreenTheme.gradientEnd,
                                  ),
                                  FeatureBadge(
                                    icon: Icons.groups_2_rounded,
                                    text: 'Phục vụ người dân',
                                    iconColor: LoginScreenTheme.gradientEnd,
                                  ),
                                ],
                              ),                           
                              const SizedBox(height: 8),
                              Text(
                                '© 2026 Cục Quản lý và phát triển thị trường trong nước – Bộ Công Thương',
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: LoginScreenTheme.titleBlue.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                packageInfoAsync.when(
                                  loading: () => 'Phiên bản —',
                                  error: (Object _, StackTrace _) => 'Phiên bản',
                                  data: (info) =>
                                      'Phiên bản ${info.version} (${info.buildNumber})',
                                ),
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: LoginScreenTheme.gradientStart,
                                  fontWeight: FontWeight.w600,
                                ),
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

class _GoogleLoginSection extends ConsumerWidget {
  const _GoogleLoginSection({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final google = ref.watch(googleSignInServiceProvider);
    if (!google.isConfigured) {
      return const SizedBox.shrink();
    }
    final biometricUi = ref.watch(biometricLoginUiProvider);
    final biometricVisible = biometricUi.maybeWhen(
      data: (ui) => ui.showButton,
      orElse: () => false,
    );
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!biometricVisible) ...[
          const SizedBox(height: 20),
          const _OrDivider(),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: loading ? null : onPressed,
          icon: const _GoogleGlyph(),
          label: Text(
            'Đăng nhập với Google',
            style: textTheme.labelLarge?.copyWith(
              color: LoginScreenTheme.titleBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: LoginScreenTheme.titleBlue,
            side: const BorderSide(color: LoginScreenTheme.fieldBorder),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glyph chữ "G" tự vẽ (không phụ thuộc asset). Có thể thay bằng asset SVG/logo Google chính chủ sau.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(color: LoginScreenTheme.fieldBorder)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4285F4),
          height: 1.0,
        ),
      ),
    );
  }
}

class _AppleLoginSection extends ConsumerWidget {
  const _AppleLoginSection({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apple = ref.watch(appleSignInServiceProvider);
    // Apple Sign-In MVP chỉ hỗ trợ iOS native. Android/web: ẩn nút.
    if (!apple.isAvailable) return const SizedBox.shrink();

    // Vì Google section đã render OrDivider khi biometric hidden, Apple chỉ cần spacing dưới Google.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        SignInWithAppleButton(
          onPressed: loading ? () {} : onPressed,
          height: 48,
          style: SignInWithAppleButtonStyle.black,
          borderRadius: BorderRadius.circular(LoginScreenTheme.controlRadius),
          text: 'Đăng nhập với Apple',
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    Widget line() => Expanded(
          child: Container(height: 1, color: LoginScreenTheme.fieldBorder),
        );
    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'HOẶC',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: LoginScreenTheme.titleBlue.withValues(alpha: 0.38),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
          ),
        ),
        line(),
      ],
    );
  }
}
