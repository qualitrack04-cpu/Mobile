import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import '../widgets/action_button.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
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
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onResetPassword() async {
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password wajib diisi');
      hasError = true;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Password minimal 8 karakter');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Silakan konfirmasi password');
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Password tidak sama');
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.resetPassword(
        email: widget.email,
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
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
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              // Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield,
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'QualiTrack',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Precision Quality & Audit Management',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
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
                    // Judul
                    Text(
                      'Reset Your Password',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // New Password
                    const Text(
                      'New Password',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      onChanged: (val) {
                        setState(() {
                          _passwordError = val.isEmpty
                              ? 'Password wajib diisi'
                              : val.length < 8
                                  ? 'Password minimal 8 karakter'
                                  : null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscured
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _isObscured = !_isObscured),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    _buildErrorText(_passwordError),
                    const SizedBox(height: 8),

                    // Password Verification
                    const Text(
                      'Password Verivication',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _isObscuredConfirm,
                      onChanged: (val) {
                        setState(() {
                          _confirmPasswordError = val.isEmpty
                              ? 'Silakan konfirmasi password'
                              : val != _passwordController.text
                                  ? 'Password tidak sama'
                                  : null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscuredConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                              () => _isObscuredConfirm = !_isObscuredConfirm),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    _buildErrorText(_confirmPasswordError),

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
                            label: 'RESET',
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