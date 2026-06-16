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
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  // Countdown timer
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

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _onVerify() async {
    if (_otpCode.length < 4) {
      setState(() => _errorMessage = 'Masukkan 4 digit OTP');
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
            builder: (_) => ResetPasswordPage(
              email: widget.email,
              resetToken: resetToken,
            ),
          ),
        );
      } else {
        await authService.verifyEmail(
          email: widget.email,
          otp: _otpCode,
        );

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
      setState(() => _errorMessage = 'OTP salah atau sudah kadaluarsa');
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
          content: Text('OTP sudah dikirim ulang!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal kirim ulang OTP'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 30, right: 30, top: 40, bottom: 20),
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
                      'Enter Verification Code',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Deskripsi
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
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

                    // 4 digit OTP
                    Row(
                      children: List.generate(7, (i) {
                        if (i.isOdd) return const SizedBox(width: 12);
                        final index = i ~/ 2;
                        return Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                      onTap: (_secondsRemaining == 0 && !_isResending) ? _onResendOtp : null,
                      child: Text(
                        _isResending
                            ? 'Resending...'
                            : _secondsRemaining > 0
                                ? 'Resend code in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                : 'Resend code',
                        style: TextStyle(
                          fontSize: 13,
                          color: (_secondsRemaining > 0 || _isResending)
                              ? Colors.grey
                              : AppColors.primary,
                          fontWeight: (_secondsRemaining > 0 || _isResending)
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

              const SizedBox(height: 20),

              // Having trouble?
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}