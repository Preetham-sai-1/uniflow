import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../widgets/brand_logo.dart';

class LoginView extends StatefulWidget {
  final AppState appState;
  final VoidCallback onLoginSuccess;
  final String? initialEmail;
  final String? initialPassword;

  const LoginView({
    super.key,
    required this.appState,
    required this.onLoginSuccess,
    this.initialEmail,
    this.initialPassword,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController =
        TextEditingController(text: widget.initialPassword ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    bool isValid = true;

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required.');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please provide a valid email address.');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required.');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    if (!_validateInputs()) {
      setState(() {
        _errorMessage = 'Please provide valid credentials.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await widget.appState.login(email, password);
      if (mounted) {
        widget.onLoginSuccess();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on NetworkException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } on ApiTimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Authentication failed. Please verify credentials and server availability.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      body: Row(
        children: [
          // Left Hero Branding Panel (Desktop & Tablet)
          if (isWide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryNavy, Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLogo(
                        isLight: true, fontSize: 24, showBadge: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Text(
                        'DIGITAL WORKFLOW PLATFORM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'One Campus.\nOne Connected\nJourney.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Navigate bonafide certificates, smart ID badge replacements, and equipment bookings with zero counter queues.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: _HeroMetric(
                              label: '100% ONLINE',
                              sub: 'Zero physical paperwork',
                            ),
                          ),
                          _HeroDivider(),
                          Expanded(
                            child: _HeroMetric(
                              label: '3 STAGES',
                              sub: 'Transparent live tracking',
                            ),
                          ),
                          _HeroDivider(),
                          Expanded(
                            child: _HeroMetric(
                              label: 'SECURE ACCESS',
                              sub: 'Role-governed engine',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Right Authentication Form Area
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isWide) ...[
                        const BrandLogo(fontSize: 22, showBadge: true),
                        const SizedBox(height: 32),
                      ],

                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in with your institutional credentials to access your campus workspace.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.error_outline_rounded,
                                    size: 18, color: Color(0xFFDC2626)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Text(
                        'Campus Email',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.email_outlined, size: 20),
                          hintText: 'user@uniflow.edu',
                          errorText: _emailError,
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.lock_outline_rounded, size: 20),
                          hintText: 'Enter password',
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        onSubmitted: (_) => _handleSignIn(),
                      ),

                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String sub;

  const _HeroMetric({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white24,
    );
  }
}
