import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../../features/authentication/presentation/providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.outlineLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Tab bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
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
                Tab(text: 'Sign In'),
                Tab(text: 'Create Account'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: _tabController.index == 0 ? 300 : 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLoginForm(isLoading),
                _buildSignupForm(isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Email Address'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              hintText: 'you@business.com',
              prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          _buildLabel('Password'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Password must be 6+ characters'
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                  activeColor: AppTheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Remember me',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSubmitButton('Sign In', _handleLogin, isLoading),
        ],
      ),
    );
  }

  Widget _buildSignupForm(bool isLoading) {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Full Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Your full name',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
              ),
              validator: (v) =>
                  (v == null || v.length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 12),
            _buildLabel('Email Address'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'you@business.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildLabel('Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '8+ characters',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => (v == null || v.length < 8)
                  ? 'Password must be 8+ characters'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Repeat password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) => v != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildSubmitButton('Create Account', _handleSignup, isLoading),
            const SizedBox(height: 12),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                  children: [
                    const TextSpan(text: 'By signing up you agree to our '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildSubmitButton(String label, VoidCallback onTap, bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
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
                ),
              ),
      ),
    );
  }
}
