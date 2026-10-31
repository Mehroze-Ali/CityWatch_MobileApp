import 'package:flutter/material.dart';
import 'package:urbanissuesclassifier/theme/app_theme.dart';
import 'package:urbanissuesclassifier/services/api_service.dart';
import 'package:urbanissuesclassifier/models/user_model.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = false;
  bool _rememberMe = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  double _passwordStrength = 0.0;
  String _passwordStrengthLabel = 'Weak';
  Color _strengthColor = AppTheme.alertRed;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = 'Weak';
        _strengthColor = Colors.grey;
      });
      return;
    }

    double strength = 0;
    // Length check
    if (password.length >= 8) strength += 0.2;
    // Capital letter check
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    // Small letter check
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    // Digit check
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    // Special character check
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.4) {
        _passwordStrengthLabel = 'Weak';
        _strengthColor = AppTheme.alertRed;
      } else if (strength <= 0.8) {
        _passwordStrengthLabel = 'Fair';
        _strengthColor = AppTheme.warningOrange;
      } else {
        _passwordStrengthLabel = 'Strong';
        _strengthColor = AppTheme.statusResolved;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Top Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: Image.asset(
              'assets/images/auth_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Center(
                    child: Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.38,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.6, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // Top Branding
          Positioned(
            top: 60,
            left: 28,
            child: const Text(
              'CityWatch',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 26,
                letterSpacing: 1.8,
              ),
            ),
          ),

          // Bottom White Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.33,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(60)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(60),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 42, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLogin ? 'Welcome back.' : 'Welcome.',
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Fields
                      if (!_isLogin) ...[
                        _buildTextField(
                          label: 'Name',
                          hint: 'Enter your name',
                          controller: _nameController,
                        ),
                        const SizedBox(height: 18),
                      ],
                      _buildTextField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        isPassword: true,
                      ),

                      // Password Strength Indicator
                      if (!_isLogin && _passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: _passwordStrength,
                                backgroundColor: Colors.grey[200],
                                color: _strengthColor,
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _passwordStrengthLabel,
                              style: TextStyle(
                                color: _strengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (!_isLogin) ...[
                        _buildTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmPasswordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _agreeToTerms,
                                onChanged: (v) {
                                  setState(() {
                                    _agreeToTerms = v ?? false;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                activeColor: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'I agree to the Terms and Conditions',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_isLogin) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) {
                                  setState(() {
                                    _rememberMe = v ?? false;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                activeColor: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 35),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _handleSubmit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            disabledBackgroundColor: Colors.grey[400],
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Sign in' : 'Sign up',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      // Toggle Link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : "Already a member yet? ",
                                ),
                                TextSpan(
                                  text: _isLogin ? 'Sign up' : 'Sign in',
                                  style: const TextStyle(
                                    color: Color(0xFF4A90E2),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/admin-login'),
                          child: Text(
                            'Admin Portal Login',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(context, 'Please fill in all required fields');
      return;
    }

    // Email Regex Validation
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      _showError(context, 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // LOGIN
        final result = await _apiService.login(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (result['success']) {
          final UserModel user = result['user'];
          _showSuccess(context, 'Welcome back, ${user.name}!');
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          _showError(context, result['message'] ?? 'Login failed');
        }
      } else {
        // SIGN UP
        // Strong Password Validation
        // Requires: 8+ chars, uppercase, lowercase, digit, special char
        final passwordRegex = RegExp(
          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
        );

        // OR using our strength label logic to be user friendly
        // If strength is weak or fair (less than strong), we can block or warn.
        // Let's enforce strictly as requested "regex for password".

        if (!passwordRegex.hasMatch(password)) {
          _showError(
            context,
            'Password too weak. Must contain uppercase, lowercase, number & special char.',
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (_nameController.text.trim().isEmpty) {
          _showError(context, 'Please enter your name');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (password != _confirmPasswordController.text) {
          _showError(context, 'Passwords do not match');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        if (!_agreeToTerms) {
          _showError(context, 'Please agree to the Terms and Conditions');
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final result = await _apiService.register(
          username: _nameController.text.trim(),
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (result['success']) {
          _showSuccess(context, 'Account created successfully! Please log in.');
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          setState(() {
            _isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        } else {
          _showError(context, result['message'] ?? 'Registration failed');
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(context, 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.alertRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusResolved,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            enabled: !_isLoading,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
