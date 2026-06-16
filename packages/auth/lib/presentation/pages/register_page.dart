import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import '../widgets/input_label.dart';
import '../widgets/custom_input_decoration.dart';
import '../widgets/role_dropdown.dart';
import 'otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscured = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;
  String? _selectedRole = 'QualityManager';

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@gmail\.com$', caseSensitive: false);
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _onRegister() async {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });

    bool hasError = false;

    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Username is required');
      hasError = true;
    }

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
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Password min 8 characters');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole ?? 'QualityManager',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => OtpPage(
                email: _emailController.text.trim(),
                isForgotPassword: false,
              ),
        ),
      );
    } catch (e) {
      setState(
        () => _generalError = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  label: const Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
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
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            const InputLabel('Username'),
                            TextField(
                              controller: _fullNameController,
                              decoration: customInputDecoration(
                                hint: 'Username',
                                icon: Icons.person_outline,
                              ),
                            ),
                            _buildErrorText(_nameError),

                            const InputLabel('Work Email'),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.email],
                              onChanged: (val) {
                                setState(() {
                                  _emailError =
                                      val.trim().isEmpty
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

                            const InputLabel('Password'),
                            TextField(
                              controller: _passwordController,
                              obscureText: _isObscured,
                              onChanged: (val) {
                                setState(() {
                                  _passwordError =
                                      val.isEmpty
                                          ? 'Password is required'
                                          : val.length < 8
                                          ? 'Password min 8 characters'
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
                                  onPressed:
                                      () => setState(
                                        () => _isObscured = !_isObscured,
                                      ),
                                ),
                              ),
                            ),
                            _buildErrorText(_passwordError),

                            const InputLabel('Password Verification'),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _isObscuredConfirm,
                              onChanged: (val) {
                                setState(() {
                                  _confirmPasswordError =
                                      val.isEmpty
                                          ? 'Please confirm your password'
                                          : val != _passwordController.text
                                          ? 'Passwords do not match'
                                          : null;
                                });
                              },
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
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _isObscuredConfirm =
                                                !_isObscuredConfirm,
                                      ),
                                ),
                              ),
                            ),
                            _buildErrorText(_confirmPasswordError),

                            const InputLabel('Role'),
                            RoleDropdown(
                              selectedRole: _selectedRole,
                              onChanged:
                                  (val) => setState(() => _selectedRole = val),
                            ),

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
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _onRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'SIGN UP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
