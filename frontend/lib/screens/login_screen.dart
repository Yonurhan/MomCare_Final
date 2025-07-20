import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// IMPORTANT: Make sure you have these files in your project and they are imported correctly.
import '../services/auth_service.dart'; // Your REAL AuthService
import '../utils/validators.dart'; // Your REAL Validators

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Define colors based on the design
  static const Color primaryColor = Color(0xFFE9407A);
  static const Color backgroundColor = Colors.white;
  static const Color hintColor = Color(0xFFB0B0B0);
  static const Color textFieldBackgroundColor = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted && authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Login berhasil!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Navigation will be handled by the Consumer in main.dart
        // but we can also push from here if needed.
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight:
                          screenHeight - MediaQuery.of(context).padding.top),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Image.asset(
                          'assets/images/login.png',
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.pregnant_woman_rounded,
                              size: 120,
                              color: primaryColor,
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to access your account',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildEmailField(),
                              const SizedBox(height: 20),
                              _buildPasswordField(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionsRow(),
                        const SizedBox(height: 30),
                        _buildLoginButton(),
                        const SizedBox(height: 40),
                        _buildSeparator(),
                        const SizedBox(height: 20),
                        _buildSocialLoginRow(),
                        const Spacer(),
                        _buildSignUpLink(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmail,
      style: GoogleFonts.poppins(),
      decoration: _buildInputDecoration(
        hintText: 'Enter your email',
        suffixIcon: const Icon(Icons.mail_outline, color: hintColor, size: 22),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: Validators.validatePassword,
      style: GoogleFonts.poppins(),
      decoration: _buildInputDecoration(
        hintText: 'Password',
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: hintColor,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: hintColor),
      filled: true,
      fillColor: textFieldBackgroundColor,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value!;
                  });
                },
                activeColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: hintColor, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Remember me',
              style: GoogleFonts.poppins(color: Colors.black54),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Forgot password?',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: primaryColor.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.5),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 3)
            : Text(
                'Done',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        const Expanded(child: Divider(color: hintColor, endIndent: 10)),
        Text(
          'or sign in with',
          style: GoogleFonts.poppins(color: Colors.black54),
        ),
        const Expanded(child: Divider(color: hintColor, indent: 10)),
      ],
    );
  }

  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(FontAwesomeIcons.google, () {}),
        const SizedBox(width: 24),
        _buildSocialIcon(FontAwesomeIcons.facebookF, () {}),
        const SizedBox(width: 24),
        _buildSocialIcon(FontAwesomeIcons.xTwitter, () {}),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: FaIcon(icon, size: 24, color: primaryColor),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.poppins(color: Colors.black54),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/register');
          },
          child: Text(
            'Sign up',
            style: GoogleFonts.poppins(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
