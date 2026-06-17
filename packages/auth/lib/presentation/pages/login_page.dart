import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:get_it/get_it.dart';
import '../widgets/input_label.dart';
import '../widgets/custom_input_decoration.dart';
import '../widgets/action_button.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscured = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@gmail\.com$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _onLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    bool hasError = false;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _emailError = 'Email must use @gmail.com');
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: 'QualityManager',
      );

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Role yang dipilih tidak sesuai')) {
        msg = 'Role yang dipilih tidak sesuai dengan akun ini';
      } else if (msg.contains('Email atau password')) {
        msg = 'Email atau password salah';
      } else {
        msg = 'Login gagal, coba lagi';
      }
      setState(() => _generalError = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        error,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      body: AutofillGroup(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QualiTrack',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  'Precision Quality & Audit Management',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const InputLabel('Work Email'),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: const [AutofillHints.email],
                        onChanged: (val) {
                          setState(() {
                            _emailError = val.trim().isEmpty
                                ? 'Email is required'
                                : !_isValidEmail(val.trim())
                                    ? 'Email must use @gmail.com'
                                    : null;
                          });
                        },
                        decoration: customInputDecoration(
                          hint: 'name@gmail.com',
                          icon: Icons.mail_outline,
                        ),
                      ),
                      _buildErrorText(_emailError),

                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordPage(
                                    initialEmail: _emailController.text,
                                  ),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forget Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      TextField(
                        controller: _passwordController,
                        obscureText: _isObscured,
                        onChanged: (val) {
                          setState(() {
                            _passwordError = val.isEmpty
                                ? 'Password is required'
                                : null;
                          });
                        },
                        decoration: customInputDecoration(
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _isObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _isObscured = !_isObscured),
                          ),
                        ),
                      ),
                      _buildErrorText(_passwordError),

                      if (_generalError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _generalError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 25),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ActionButton(
                              label: 'SIGN IN',
                              onPressed: _onLogin,
                            ),

                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              "Don't have account?",
                              style: TextStyle(color: Colors.grey),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                              child: const Text(
                                'SIGN UP',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}