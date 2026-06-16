import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core/app_colors.dart';
import 'package:core_services/core_services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final String photoPath;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.photoPath,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isObscured = true;
  bool _isObscuredNew = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;
  bool _isSendingOtp = false;
  String? _errorMessage;
  File? _selectedPhoto;
  bool _isEmailVerified = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _emailController.addListener(_onEmailChanged);
    _passwordController.text = '********';
  }

  void _onEmailChanged() {
    if (_emailController.text.trim() != widget.email && _isEmailVerified) {
      setState(() => _isEmailVerified = false);
    } else {
      setState(() {});
    }
  }

  bool get _isEmailFormatValid {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatRole(String role) {
    if (role == 'Auditor' || role == 'AuditorInternal') return 'Auditor Internal';
    if (role.isEmpty) return '-';
    return role
        .replaceAllMapped(RegExp(r'(?<=[a-z])([A-Z])'), (Match m) => ' ${m[1]}')
        .trim();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text('Camera', style: GoogleFonts.inter()),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() => _selectedPhoto = File(picked.path));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text('Gallery', style: GoogleFonts.inter()),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() => _selectedPhoto = File(picked.path));
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
    );
  }

  Future<void> _requestEmailVerification() async {
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) return;

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    try {
      final authService = GetIt.instance<AuthService>();
      await authService.requestEmailChangeOtp(newEmail: newEmail);

      if (!mounted) return;
      setState(() => _isSendingOtp = false);
      _showOtpDialog(newEmail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _errorMessage = 'Gagal mengirim OTP ke email baru. Pastikan email valid.';
      });
    }
  }

  Future<void> _showOtpDialog(String newEmail) async {
    final controllers = List.generate(4, (_) => TextEditingController());
    final focusNodes = List.generate(4, (_) => FocusNode());
    bool isVerifying = false;
    String? otpError;

    int secondsRemaining = 59;
    Timer? timer;
    StateSetter? dialogSetState;
    bool isResending = false;

    void startTimer() {
      timer?.cancel();
      secondsRemaining = 59;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (secondsRemaining == 0) {
          t.cancel();
          dialogSetState?.call(() {});
        } else {
          dialogSetState?.call(() => secondsRemaining--);
        }
      });
      dialogSetState?.call(() {});
    }

    startTimer();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            dialogSetState = setModalState;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: SingleChildScrollView(
                child: Container(
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enter Verification Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                                  'We have sent a 4-digit verification code to your new email\n',
                            ),
                            TextSpan(
                              text: newEmail,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return SizedBox(
                            width: 55,
                            height: 60,
                            child: TextField(
                              controller: controllers[index],
                              focusNode: focusNodes[index],
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
                                  focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      if (otpError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          otpError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: GestureDetector(
                          onTap: (secondsRemaining == 0 && !isResending)
                              ? () async {
                                  dialogSetState?.call(() => isResending = true);
                                  try {
                                    final authService = GetIt.instance<AuthService>();
                                    await authService.requestEmailChangeOtp(newEmail: newEmail);
                                    startTimer();
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('OTP sudah dikirim ulang!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('Gagal kirim ulang OTP!'), backgroundColor: Colors.red),
                                      );
                                    }
                                  } finally {
                                    dialogSetState?.call(() => isResending = false);
                                  }
                                }
                              : null,
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: (secondsRemaining == 0 && !isResending) ? AppColors.primary : Colors.grey,
                                fontWeight: (secondsRemaining == 0 && !isResending) ? FontWeight.bold : FontWeight.normal,
                              ),
                              children: [
                                const TextSpan(text: 'Didn\'t receive the code? '),
                                TextSpan(
                                  text: isResending
                                      ? 'resending...'
                                      : secondsRemaining == 0
                                          ? 'resend code'
                                          : 'resend code in ${secondsRemaining}s',
                                  style: TextStyle(
                                    color: (secondsRemaining == 0 && !isResending) ? AppColors.primary : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed:
                              isVerifying
                                  ? null
                                  : () async {
                                    final otpCode =
                                        controllers.map((c) => c.text).join();
                                    if (otpCode.length < 4) {
                                      setModalState(
                                        () => otpError = 'Masukkan 4 digit OTP',
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      isVerifying = true;
                                      otpError = null;
                                    });

                                    try {
                                      final authService =
                                          GetIt.instance<AuthService>();
                                      await authService.verifyEmailChange(
                                        otp: otpCode,
                                      );

                                      if (!this.mounted) return;
                                      setState(() {
                                        _isEmailVerified = true;
                                        _errorMessage = null;
                                      });
                                      Navigator.pop(ctx); // Tutup dialog OTP

                                      // Langsung otomatis jalankan Save Changes untuk semuanya (nama, foto)
                                      // dan tutup halamannya supaya user tidak bingung.
                                      _saveChanges();
                                    } catch (e) {
                                      setModalState(
                                        () =>
                                            otpError =
                                                'OTP salah atau sudah kadaluarsa',
                                      );
                                    } finally {
                                      if (this.mounted)
                                        setModalState(
                                          () => isVerifying = false,
                                        );
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isVerifying
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'VERIFY & PROCEED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    timer?.cancel();
  }

  void _onSaveChanges() {
    // Validasi password jika diubah

    if (_newPasswordController.text.isNotEmpty) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() => _errorMessage = 'Password baru tidak sama');
        return;
      }
      if (_newPasswordController.text.length < 8) {
        setState(() => _errorMessage = 'Password baru minimal 8 karakter');
        return;
      }
    }

    setState(() => _errorMessage = null);
    _showConfirmDialog();
  }

  bool _hasUnsavedChanges() {
    if (_usernameController.text.trim() != widget.name) return true;
    if (_emailController.text.trim() != widget.email) return true;
    if (_newPasswordController.text.isNotEmpty) return true;
    if (_confirmPasswordController.text.isNotEmpty) return true;
    if (_selectedPhoto != null) return true;
    return false;
  }

  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Perubahan Belum Disimpan',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar tanpa menyimpan?',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Keluar',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Are you sure you want to save the changes to your profile? This action will update your account information.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveChanges();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final authService = GetIt.instance<AuthService>();
      
      bool nameChanged = _usernameController.text.trim() != widget.name;
      bool emailChanged = _emailController.text.trim() != widget.email;

      if (nameChanged) {
        await authService.updateProfile(
          name: _usernameController.text.trim(),
        );
      }

      if (_newPasswordController.text.isNotEmpty) {
        await authService.changePassword(
          newPassword: _newPasswordController.text,
        );
      }

      if (_selectedPhoto != null) {
        await authService.updateProfilePhoto(_selectedPhoto!.path);
      }

      if (emailChanged && !_isEmailVerified) {
        if (mounted) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan klik "Verify Now" untuk memverifikasi email baru Anda terlebih dahulu.'),
            backgroundColor: Colors.orange,
          ),
        );
        return; 
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile berhasil diupdate!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getPhotoProvider() {
    if (_selectedPhoto != null) return FileImage(_selectedPhoto!);
    if (widget.photoPath.isNotEmpty) {
      // photoPath dari backend berupa path relatif, misal: /uploads/profiles/xxx.jpg
      return NetworkImage(ApiService.fixImageUrl(widget.photoPath));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasUnsavedChanges()) {
          final shouldPop = await _showUnsavedChangesDialog();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontSize: (screenWidth * 0.06).clamp(20.0, 24.0),
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: AppColors.border),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.borderLight,
                          backgroundImage: _getPhotoProvider(),
                          child:
                              _getPhotoProvider() == null
                                  ? Icon(
                                    Icons.person,
                                    size: 52,
                                    color: AppColors.primaryMuted,
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.name.isEmpty ? '-' : widget.name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRole(widget.role).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form fields
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Username',
                      controller: _usernameController,
                    ),
                    Divider(height: 1, color: AppColors.borderLight),
                    // Custom Email Field with Verification
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Email',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_emailController.text.trim() != widget.email && !_isEmailVerified)
                                if (!_isEmailFormatValid)
                                  Text(
                                    'Format email tidak valid',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: _isSendingOtp ? null : _requestEmailVerification,
                                    child: _isSendingOtp
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Text(
                                            'Verify Now',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF2ECC71),
                                            ),
                                          ),
                                  )
                              else if (_emailController.text.trim() != widget.email && _isEmailVerified)
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: AppColors.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: AppColors.borderLight),
                    _buildPasswordField(
                      label: 'New Password',
                      controller: _newPasswordController,
                      isObscured: _isObscuredNew,
                      onToggle:
                          () =>
                              setState(() => _isObscuredNew = !_isObscuredNew),
                    ),
                    Divider(height: 1, color: AppColors.borderLight),
                    _buildPasswordField(
                      label: 'New Password Verivication',
                      controller: _confirmPasswordController,
                      isObscured: _isObscuredConfirm,
                      onToggle:
                          () => setState(
                            () => _isObscuredConfirm = !_isObscuredConfirm,
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 24),

              Align(
                alignment: Alignment.centerRight,
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                          onPressed: _onSaveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: Text(
                            'save changes',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscured,
    required VoidCallback onToggle,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isObscured,
            readOnly: readOnly,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: readOnly ? Colors.grey : Colors.black87,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: Colors.grey,
                ),
                onPressed: onToggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: readOnly ? AppColors.borderLight : AppColors.primary,
                  width: readOnly ? 1 : 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
