import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Pastikan semua file ini ada dan diimpor dengan benar
import '../services/auth_service.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  // State untuk Dropdown
  String? _selectedTrimester;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;

  // Definisikan warna agar konsisten dengan LoginScreen
  static const Color primaryColor = Color(0xFFE9407A);
  static const Color backgroundColor = Colors.white;
  static const Color hintColor = Color(0xFFB0B0B0);
  static const Color textFieldBackgroundColor = Color(0xFFF7F7F7);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animationController.forward();
  }

  // Helper untuk membuat animasi bertingkat (staggered)
  Animation<double> _createAnimation(double begin, double end) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(begin, end, curve: Curves.easeOut),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, _passwordController.text);
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final response = await authService.register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        int.tryParse(_ageController.text.trim()) ?? 0,
        int.tryParse(_weightController.text.trim()) ?? 0,
        int.tryParse(_heightController.text.trim()) ?? 0,
        int.tryParse(_selectedTrimester!) ??
            0, // Menggunakan nilai dari dropdown
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              response['message'] ?? 'Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildForm(),
                const SizedBox(height: 30),
                _buildRegisterButton(),
                const SizedBox(height: 24),
                _buildSignInLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget(
      {required Widget child, required double begin, double end = 1.0}) {
    final animation = _createAnimation(begin, end);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return _buildAnimatedWidget(
      begin: 0.0,
      end: 0.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black54),
            onPressed: () => Navigator.pop(context),
          ),
          Center(
            child: Column(
              children: [
                // Ganti 'assets/register_illustration.png' dengan path gambar Anda
                Image.asset(
                  'assets/images/register.png',
                  height: 140,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.edit_document,
                        size: 100, color: primaryColor);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Your Account',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s get you started!',
                  style:
                      GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Bagian Informasi Akun ---
          _buildAnimatedWidget(
              begin: 0.2,
              end: 0.6,
              child: _buildSectionTitle('Account Information')),
          _buildAnimatedWidget(
            begin: 0.3,
            end: 0.7,
            child: _buildTextFormField(
              controller: _usernameController,
              hintText: 'Username',
              validator: Validators.validateUsername,
              icon: Icons.person_outline,
            ),
          ),
          _buildAnimatedWidget(
            begin: 0.35,
            end: 0.75,
            child: _buildTextFormField(
              controller: _emailController,
              hintText: 'Email',
              validator: Validators.validateEmail,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
            ),
          ),
          _buildAnimatedWidget(
            begin: 0.4,
            end: 0.8,
            child: _buildTextFormField(
              controller: _passwordController,
              hintText: 'Password',
              validator: Validators.validatePassword,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: hintColor,
                    size: 22),
                onPressed: _togglePasswordVisibility,
              ),
            ),
          ),
          _buildAnimatedWidget(
            begin: 0.45,
            end: 0.85,
            child: _buildTextFormField(
              controller: _confirmPasswordController,
              hintText: 'Confirm Password',
              validator: _validateConfirmPassword,
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: hintColor,
                    size: 22),
                onPressed: _toggleConfirmPasswordVisibility,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Bagian Detail Pribadi ---
          _buildAnimatedWidget(
              begin: 0.5,
              end: 0.9,
              child: _buildSectionTitle('Personal Details')),
          _buildAnimatedWidget(
            begin: 0.55,
            end: 0.95,
            child: _buildTextFormField(
              controller: _ageController,
              hintText: 'Age',
              validator: Validators.validateAge,
              icon: Icons.cake_outlined,
              keyboardType: TextInputType.number,
            ),
          ),
          _buildAnimatedWidget(
            begin: 0.6,
            end: 1.0,
            child: Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _weightController,
                    hintText: 'Weight (kg)',
                    validator: Validators.validateWeight,
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextFormField(
                    controller: _heightController,
                    hintText: 'Height (cm)',
                    validator: Validators.validateHeight,
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ),
          _buildAnimatedWidget(
            begin: 0.65,
            end: 1.0,
            child: _buildTrimesterDropdown(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: GoogleFonts.poppins(),
        decoration: _buildInputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: hintColor, size: 22),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildTrimesterDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedTrimester,
        validator: (value) => value == null ? 'Pilih trimester' : null,
        hint: Text('Select Trimester',
            style: GoogleFonts.poppins(color: hintColor)),
        style: GoogleFonts.poppins(color: Colors.black87),
        decoration: _buildInputDecoration(
          hintText:
              '', // Hint text is handled by the DropdownButtonFormField itself
          prefixIcon: const Icon(Icons.pregnant_woman_outlined,
              color: hintColor, size: 22),
        ),
        items: ['1', '2', '3'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text('Trimester $value'),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedTrimester = newValue;
          });
        },
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: hintColor),
      filled: true,
      fillColor: textFieldBackgroundColor,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _buildRegisterButton() {
    return _buildAnimatedWidget(
      begin: 0.7,
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _register,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: primaryColor.withOpacity(0.7),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            shadowColor: primaryColor.withOpacity(0.4),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 3)
              : Text('Create Account',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return _buildAnimatedWidget(
      begin: 0.75,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Already have an account? ",
              style: GoogleFonts.poppins(color: Colors.black54)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text('Sign In',
                style: GoogleFonts.poppins(
                    color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
