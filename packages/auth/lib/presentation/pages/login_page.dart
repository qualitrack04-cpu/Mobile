import 'package:flutter/material.dart';
import 'package:core/app_colors.dart';
import 'package:dashboard/presentation/pages/dashboard_screen.dart';

import '../widgets/input_label.dart';
import '../widgets/custom_input_decoration.dart';
import '../widgets/action_button.dart';
import '../widgets/role_dropdown.dart';

import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? _selectedRole = 'Quality Manager';
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),

          child: Column(
            children: [
              const Icon(
                Icons.shield,
                size: 45,
                color: AppColors.primary,
              ),

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
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
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

                    const InputLabel('Work Email'),

                    TextField(
                      decoration: customInputDecoration(
                        hint: 'name@company.com',
                        icon: Icons.mail_outline,
                      ),
                    ),

                    const InputLabel('Password'),

                    TextField(
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

                          onPressed: () {
                            setState(() {
                              _isObscured = !_isObscured;
                            });
                          },
                        ),
                      ),
                    ),

                    const InputLabel('Role'),

                    RoleDropdown(
                      selectedRole: _selectedRole,
                      onChanged: (val) {
                        setState(() {
                          _selectedRole = val;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    ActionButton(
                      label: 'SIGN IN',
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Don't have account?",
                style: TextStyle(color: Colors.grey),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },

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
      ),
    );
  }
}