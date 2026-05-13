import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';        // TAMBAH
import 'package:dashboard/presentation/pages/dashboard_screen.dart';
import 'package:get_it/get_it.dart';                    // TAMBAH

import '../widgets/input_label.dart';
import '../widgets/custom_input_decoration.dart';
import '../widgets/action_button.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();     // TAMBAH
  final _passwordController = TextEditingController();  // TAMBAH
  bool _isObscured = true;
  bool _isLoading = false;                              // TAMBAH
  String? _errorMessage;                                // TAMBAH

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    // Validasi field kosong
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Email dan password wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Email atau password salah');
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
              const Text('QualiTrack',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const Text('Precision Quality & Audit Management',
                  style: TextStyle(fontSize: 12, color: AppColors.primary)),
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
                        offset: Offset(0, 10))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sign In',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),

                    const InputLabel('Work Email'),
                    TextField(
                      controller: _emailController,          // TAMBAH
                      keyboardType: TextInputType.emailAddress,
                      decoration: customInputDecoration(
                        hint: 'name@company.com',
                        icon: Icons.mail_outline,
                      ),
                    ),

                    const InputLabel('Password'),
                    TextField(
                      controller: _passwordController,       // TAMBAH
                      obscureText: _isObscured,
                      decoration: customInputDecoration(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(_isObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 20),
                          onPressed: () =>
                              setState(() => _isObscured = !_isObscured),
                        ),
                      ),
                    ),

                    // TAMBAH: tampilkan error kalau ada
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],

                    const SizedBox(height: 25),

                    // TAMBAH: loading indicator atau tombol
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ActionButton(
                            label: 'SIGN IN',
                            onPressed: _onLogin,            // UBAH
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Text("Don't have account?",
                  style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RegisterPage())),
                child: const Text('SIGN UP',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}