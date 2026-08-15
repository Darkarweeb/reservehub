import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../features/authentication/presentation/providers/auth_provider.dart';
import '../../../localization/app_strings.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/brand/reserve_hub_logo.dart';

class AuthFormWidget extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  const AuthFormWidget({required this.onAuthSuccess, super.key});

  @override
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      widget.onAuthSuccess();
    } else if (mounted && authProvider.errorMessage != null) {
      Fluttertoast.showToast(
        msg: authProvider.errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
    if (success && mounted) {
      widget.onAuthSuccess();
    } else if (mounted && authProvider.errorMessage != null) {
      Fluttertoast.showToast(
        msg: authProvider.errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((p) => p.isLoading);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium tab bar
          _buildPremiumTabBar(),
          const SizedBox(height: 28),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              child: _tabController.index == 0
                  ? _buildLoginForm(isLoading)
                  : _buildSignupForm(isLoading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [RHBrandTokens.navyLight, RHBrandTokens.professionalBlue],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: RHBrandTokens.glowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: AppStrings.signIn),
          Tab(text: AppStrings.createAccount),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(AppStrings.email),
          const SizedBox(height: 7),
          _buildTextField(
            controller: _emailController,
            hint: 'you@business.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? AppStrings.invalidEmail
                : null,
          ),
          const SizedBox(height: 18),
          _buildLabel(AppStrings.password),
          const SizedBox(height: 7),
          _buildPasswordField(
            controller: _passwordController,
            hint: '••••••••',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => (v == null || v.length < 6)
                ? AppStrings.passwordTooShort
                : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: RHBrandTokens.electricBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.rememberMe,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.forgotPassword,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RHBrandTokens.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(AppStrings.signIn, _handleLogin, isLoading),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSignupForm(bool isLoading) {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLabel(AppStrings.fullName),
          const SizedBox(height: 7),
          _buildTextField(
            controller: _nameController,
            hint: 'Tu nombre completo',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                (v == null || v.length < 2) ? AppStrings.nameTooShort : null,
          ),
          const SizedBox(height: 16),
          _buildLabel(AppStrings.email),
          const SizedBox(height: 7),
          _buildTextField(
            controller: _emailController,
            hint: 'you@business.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@'))
                ? AppStrings.invalidEmail
                : null,
          ),
          const SizedBox(height: 16),
          _buildLabel(AppStrings.password),
          const SizedBox(height: 7),
          _buildPasswordField(
            controller: _passwordController,
            hint: '8+ caracteres',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => (v == null || v.length < 8)
                ? AppStrings.passwordTooShort
                : null,
          ),
          const SizedBox(height: 16),
          _buildLabel(AppStrings.confirmPassword),
          const SizedBox(height: 7),
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: 'Repite la contraseña',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) => v != _passwordController.text
                ? AppStrings.passwordsDoNotMatch
                : null,
          ),
          const SizedBox(height: 24),
          _buildSubmitButton(
            AppStrings.createAccount,
            _handleSignup,
            isLoading,
          ),
          const SizedBox(height: 14),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
                children: [
                  const TextSpan(text: AppStrings.agreeToTermsPrefix),
                  TextSpan(
                    text: AppStrings.termsAndConditions,
                    style: const TextStyle(
                      color: RHBrandTokens.electricBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                  const TextSpan(text: ' ${AppStrings.and} '),
                  TextSpan(
                    text: AppStrings.privacyPolicy,
                    style: const TextStyle(
                      color: RHBrandTokens.electricBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─── Field helpers ───────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(icon, size: 17, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RHBrandTokens.electricBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFFCBD5E1),
        ),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          size: 17,
          color: Color(0xFF94A3B8),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 17,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: onToggle,
          tooltip: obscure ? AppStrings.showPassword : AppStrings.hidePassword,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RHBrandTokens.electricBlue,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB91C1C), width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton(String label, VoidCallback onTap, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              RHBrandTokens.electricBlue,
              RHBrandTokens.professionalBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: RHBrandTokens.glowColor,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            elevation: 0,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}
