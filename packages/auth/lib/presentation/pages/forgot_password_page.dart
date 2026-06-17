import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import '../widgets/custom_input_decoration.dart';
import 'otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w\.-]+@gmail\.com$',
      caseSensitive: false,
    );
    return emailRegex.hasMatch(email.trim());
  }

  Future<void> _onRequestOtp() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }
    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _errorMessage = 'Email must use @gmail.com');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.requestForgotPasswordOtp(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            email: _emailController.text.trim(),
            isForgotPassword: true,
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Email not found');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 18),
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

            // Konten utama
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.07),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: screenHeight * 0.04),

                            // Logo
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.shield, size: 34, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'QualiTrack',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              'Precision Quality & Audit Management',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            ),

                            SizedBox(height: screenHeight * 0.05),

                            // Card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth * 0.06),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.055).clamp(18.0, 24.0),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Enter your registered work email below. We will send you a OTP Code to reset your password.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: (screenWidth * 0.038).clamp(13.0, 16.0),
                                      color: Colors.grey,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    decoration: customInputDecoration(
                                      hint: 'name@company.com',
                                      icon: Icons.mail_outline,
                                    ),
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red, fontSize: 13),
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  _isLoading
                                      ? const Center(child: CircularProgressIndicator())
                                      : SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: ElevatedButton(
                                            onPressed: _onRequestOtp,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: const Text(
                                              'SEND OTP CODE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // "Remember your password?" di BAWAH
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Remember your password? ',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
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
            ),
          ],
        ),
      ),
    );
  }
}