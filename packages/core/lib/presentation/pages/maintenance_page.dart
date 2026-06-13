import 'package:flutter/material.dart';

class MaintenancePage extends StatefulWidget {
  const MaintenancePage({super.key});

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  bool _isChecking = false;

  double get _buttonWidth => _isChecking ? 52 : 180;

  Future<void> _checkMaintenance() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Simulasi call API
      await Future.delayed(const Duration(seconds: 2));

      // TODO:
      // Ganti dengan response dari backend
      bool isMaintenance = true;

      if (!mounted) return;

      if (isMaintenance) {
        await Future.delayed(const Duration(milliseconds: 500));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System is still under maintenance.')),
        );
      } else {
        // TODO:
        // Redirect ke Login / Dashboard
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EDF3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Image.asset('assets/icon/Qualek.png', height: 140),

              const SizedBox(height: 80),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            const Icon(
                              Icons.description,
                              size: 50,
                              color: Color(0xFF0D4B9E),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.settings,
                                  size: 20,
                                  color: Color(0xFF0D4B9E),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        const Expanded(
                          child: Text(
                            'System Maintenance',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D4B9E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'QualiTrack is currently under\nmaintenance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A6478),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "We're making improvements to\ndeliver a better experience.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A6478),
                      ),
                    ),

                    const SizedBox(height: 40),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      width: _isChecking ? 52 : 180,
                      height: 52,
                      child: Material(
                        color: const Color(0xFF1EA7FF),
                        borderRadius: BorderRadius.circular(100),
                        elevation: 6,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: _isChecking ? null : _checkMaintenance,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeIn,
                              switchOutCurve: Curves.easeOut,
                              child:
                                  _isChecking
                                      ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.8,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Check Again',
                                        key: ValueKey('text'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
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
    );
  }
}
