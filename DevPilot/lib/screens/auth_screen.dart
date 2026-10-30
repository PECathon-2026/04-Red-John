import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../widgets/phosphor_icon.dart';

/// Authentication Screen providing unified Sign In and Account Creation.
/// Designed for developers with high-contrast Light Theme, Phosphor icons,
/// passkey/GitHub options, client-side validation, and instant Demo Mode bypass.
class AuthScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback? onBack;

  const AuthScreen({
    super.key,
    required this.onSuccess,
    this.onBack,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: 'Aryan');
  final TextEditingController _emailController =
      TextEditingController(text: 'developer@devpilot.io');
  final TextEditingController _passwordController =
      TextEditingController(text: '••••••••••••');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthSubmit() async {
    HapticFeedback.mediumImpact();
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      // Simulate client-side instantaneous authentication
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() => _isLoading = false);
        widget.onSuccess();
      }
    }
  }

  Future<void> _handleOAuth(String provider) async {
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onSuccess();
    }
  }

  void _showForgotKeyDialog() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const PhosphorIcon('shield-check', size: 18, color: T.onPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Recovery instructions dispatched to ${_emailController.text}',
                style: T.bodySm.copyWith(color: T.onPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: T.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: T.rSm),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: T.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.onBack != null)
                      GestureDetector(
                        key: const Key('auth_back_button'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onBack!();
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: T.surface,
                            borderRadius: T.rSm,
                            border: Border.all(color: T.border, width: 1),
                          ),
                          child: const Center(
                            child: PhosphorIcon('arrow-left', size: 18, color: T.onSurface),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    // Platform badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: T.badgeCircle,
                        border: Border.all(color: T.border, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PhosphorIcon('shield-check', size: 12, color: T.success),
                          const SizedBox(width: 6),
                          Text(
                            'OFFLINE READY • LOCAL ENCLAVE',
                            style: T.labelUpXs.copyWith(
                              fontSize: 9,
                              color: T.onSurfaceVar,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
                const SizedBox(height: 32),

                // Brand Crest & Header
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: T.surface,
                      borderRadius: T.rLg,
                      border: Border.all(color: T.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: PhosphorIcon('rocket-launch', size: 28, color: T.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Greeting & Subtitle
                Center(
                  child: Text(
                    _isSignUp ? 'Create Account' : 'Welcome back',
                    style: T.displaySm.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: T.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _isSignUp
                        ? 'Initialize your developer workspace on DevPilot'
                        : 'Authenticate to access autonomous mission control',
                    style: T.bodyMd.copyWith(
                      color: T.onSurfaceVar,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Segmented Tab Switcher (Sign In vs Create Account)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: T.surfaceMuted,
                    borderRadius: T.badgeCircle,
                    border: Border.all(color: T.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isSignUp) {
                              HapticFeedback.selectionClick();
                              setState(() => _isSignUp = false);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !_isSignUp ? T.surface : Colors.transparent,
                              borderRadius: T.badgeCircle,
                              boxShadow: !_isSignUp
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'SIGN IN',
                              style: T.labelUpSm.copyWith(
                                fontSize: 11,
                                fontWeight:
                                    !_isSignUp ? FontWeight.w700 : FontWeight.w500,
                                color: !_isSignUp ? T.onSurface : T.onSurfaceVar,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isSignUp) {
                              HapticFeedback.selectionClick();
                              setState(() => _isSignUp = true);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _isSignUp ? T.surface : Colors.transparent,
                              borderRadius: T.badgeCircle,
                              boxShadow: _isSignUp
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'CREATE ACCOUNT',
                              style: T.labelUpSm.copyWith(
                                fontSize: 11,
                                fontWeight:
                                    _isSignUp ? FontWeight.w700 : FontWeight.w500,
                                color: _isSignUp ? T.onSurface : T.onSurfaceVar,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: T.rLg,
                    border: Border.all(color: T.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name field for Sign Up
                      if (_isSignUp) ...[
                        Text(
                          'DEVELOPER NAME',
                          style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                        ),
                        const SizedBox(height: 6),
                        _buildTextInput(
                          controller: _nameController,
                          hint: 'Aryan (Lead Engineer)',
                          icon: 'user',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Please enter a name' : null,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email / ID Field
                      Text(
                        'DEVELOPER EMAIL OR ID',
                        style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                      ),
                      const SizedBox(height: 6),
                      _buildTextInput(
                        controller: _emailController,
                        hint: 'developer@devpilot.io',
                        icon: 'user',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      Text(
                        'MASTER KEY / PASSWORD',
                        style: T.labelUpXs.copyWith(color: T.onSurfaceVar),
                      ),
                      const SizedBox(height: 6),
                      _buildTextInput(
                        controller: _passwordController,
                        hint: '••••••••••••',
                        icon: 'lock',
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: T.onSurfaceVar,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 4) ? 'Enter master key' : null,
                      ),
                      const SizedBox(height: 14),

                      // Options Row: Remember Me & Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: T.accent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v ?? true),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember device',
                                  style: T.bodySm.copyWith(
                                    color: T.onSurfaceVar,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isSignUp)
                            GestureDetector(
                              onTap: _showForgotKeyDialog,
                              child: Text(
                                'Forgot key?',
                                style: T.bodySm.copyWith(
                                  color: T.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Primary Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('auth_submit_button'),
                          onPressed: _isLoading ? null : _handleAuthSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: T.primary,
                            foregroundColor: T.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: T.rMd),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isSignUp
                                          ? 'INITIALIZE ACCOUNT'
                                          : 'SIGN IN TO CONSOLE',
                                      style: T.labelUpSm.copyWith(
                                        color: T.onPrimary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const PhosphorIcon(
                                      'arrow-right',
                                      size: 18,
                                      color: T.onPrimary,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Divider with text
                Row(
                  children: [
                    Expanded(child: Container(height: 1, color: T.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OR CONNECT WITH',
                        style: T.labelUpXs.copyWith(
                          fontSize: 9,
                          color: T.onSurfaceMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Expanded(child: Container(height: 1, color: T.border)),
                  ],
                ),
                const SizedBox(height: 18),

                // Quick Auth Options: GitHub & Passkey
                Row(
                  children: [
                    Expanded(
                      child: _buildOAuthButton(
                        label: 'GitHub',
                        icon: 'code',
                        onTap: () => _handleOAuth('GitHub'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildOAuthButton(
                        label: 'Passkey',
                        icon: 'shield-check',
                        onTap: () => _handleOAuth('Passkey'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Instant Demo Mode Bypass Button
                Center(
                  child: TextButton(
                    key: const Key('demo_mode_button'),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onSuccess();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explore in Demo Mode',
                          style: T.bodyMd.copyWith(
                            color: T.onSurfaceVar,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: T.onSurfaceVar),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    required String icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: T.bodyMd.copyWith(color: T.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: T.bodyMd.copyWith(color: T.onSurfaceMuted, fontSize: 14),
        filled: true,
        fillColor: T.surfaceMuted,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: PhosphorIcon(icon, size: 18, color: T.onSurfaceVar),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: T.rMd,
          borderSide: const BorderSide(color: T.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: T.rMd,
          borderSide: const BorderSide(color: T.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: T.rMd,
          borderSide: const BorderSide(color: T.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: T.rMd,
          borderSide: const BorderSide(color: T.destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: T.rMd,
          borderSide: const BorderSide(color: T.destructive, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOAuthButton({
    required String label,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: T.rMd,
          border: Border.all(color: T.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(icon, size: 18, color: T.onSurface),
            const SizedBox(width: 8),
            Text(
              label,
              style: T.bodyMd.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: T.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
