import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import '../widgets/action_button.dart';
import 'login_page.dart';
import 'reset_password_page.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final bool isForgotPassword;

  const OtpPage({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _onVerify() async {
    if (_otpCode.length < 4) {
      setState(() => _errorMessage = 'Please enter 4 digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();

      if (widget.isForgotPassword) {
        final resetToken = await authService.verifyForgotPasswordOtp(
          email: widget.email,
          otp: _otpCode,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => ResetPasswordPage(
                  email: widget.email,
                  resetToken: resetToken,
                ),
          ),
        );
      } else {
        await authService.verifyEmail(email: widget.email, otp: _otpCode);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Invalid or expired OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final authService = GetIt.instance<AuthService>();
      if (widget.isForgotPassword) {
        await authService.requestForgotPasswordOtp(email: widget.email);
      } else {
        await authService.resendOtp(email: widget.email);
      }
      _startTimer();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has been resent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend OTP'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final otpBoxSize = 64.0;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            children: [
              SizedBox(width: 8),
              Icon(Icons.arrow_back_ios, size: 16, color: Colors.black87),
              Text(
                'Back',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ],
          ),
        ),
        leadingWidth: 80,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.07,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  children: [
                    // Logo
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 34,
                        color: Colors.white,
                      ),
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

                    SizedBox(height: screenHeight * 0.04),

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Verification Code',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.055).clamp(18.0, 24.0),
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Deskripsi — font lebih besar
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: (screenWidth * 0.038).clamp(
                                  13.0,
                                  16.0,
                                ),
                                color: Colors.grey,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'We have sent a 4-digit verification code to your registered work email\n',
                                ),
                                TextSpan(
                                  text: widget.email,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 4 kotak OTP dengan jarak yang cukup
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Row(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: TextField(
                                      controller: _controllers[index],
                                      focusNode: _focusNodes[index],
                                      maxLength: 1,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontSize: (screenWidth * 0.06).clamp(
                                          20.0,
                                          28.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: '',
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty && index < 3) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  ),
                                  if (index < 3)
                                    const SizedBox(
                                      width: 16,
                                    ), // jarak antar kotak
                                ],
                              );
                            }),
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

                          const SizedBox(height: 16),

                          // Countdown timer
                          GestureDetector(
                            onTap:
                                (_secondsRemaining == 0 && !_isResending)
                                    ? _onResendOtp
                                    : null,
                            child: Text(
                              _isResending
                                  ? 'Resending...'
                                  : _secondsRemaining > 0
                                  ? 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                  : 'Resend code',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    (_secondsRemaining > 0 || _isResending)
                                        ? Colors.grey
                                        : AppColors.primary,
                                fontWeight:
                                    (_secondsRemaining > 0 || _isResending)
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ActionButton(
                                label: 'VERIFY & PROCEED',
                                onPressed: _onVerify,
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // "Having trouble?" di BAWAH
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Having trouble? ',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Contact Support',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
