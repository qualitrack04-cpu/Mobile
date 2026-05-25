import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import '../widgets/input_label.dart';
import '../widgets/custom_input_decoration.dart';
import '../widgets/action_button.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscured = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Password wajib diisi');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Password tidak sama');
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'Password minimal 8 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil direset!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Gagal reset password, coba lagi');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const Icon(Icons.shield, size: 45, color: AppColors.primary),
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
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your new password',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const InputLabel('New Password'),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscured,
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

                    const InputLabel('Confirm Password'),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscuredConfirm,
                      decoration: customInputDecoration(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _isObscuredConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _isObscuredConfirm = !_isObscuredConfirm),
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
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
                            label: 'RESET PASSWORD',
                            onPressed: _onResetPassword,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}