import 'dart:ui';
import 'package:flutter/material.dart';
import 'api_service.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;

  // Змінна для збереження дати у правильному форматі для бекенду
  String _backendDob = "";

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: primaryGold,
              onPrimary: Colors.black,
              surface: surfaceDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black.withOpacity(0.9),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Зберігаємо для бекенду у РРРР-ММ-ДД
        _backendDob = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        // Користувачу показуємо ММ/ДД/РРРР
        _dobController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() { _isLoading = true; });
    var result = await ApiService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _phoneController.text.trim(),
      _backendDob, // Відправляємо на бекенд правильний формат
    );

    if (mounted) {
      setState(() { _isLoading = false; });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration successful!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration error.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1514933651103-005eec06c04b?q=80&w=2000',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 70.0, bottom: 24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: surfaceDark.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_outlined, color: primaryGold, size: 40),
                        const SizedBox(height: 12),
                        Text('Registration', style: TextStyle(color: primaryGold, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Join the Compromice family', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 24),

                        _buildTextField(label: 'NAME', hint: 'Artem', icon: Icons.person_outline, controller: _nameController),
                        const SizedBox(height: 16),

                        _buildTextField(label: 'EMAIL', hint: 'your@email.com', icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),

                        _buildTextField(label: 'PHONE', hint: '+380...', icon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'DATE OF BIRTH',
                          hint: 'Select date',
                          icon: Icons.calendar_today_outlined,
                          controller: _dobController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'PASSWORD',
                          isVisible: _isPasswordVisible,
                          controller: _passwordController,
                          onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: 'CONFIRMATION',
                          isVisible: _isConfirmVisible,
                          controller: _confirmPasswordController,
                          onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('SIGN UP', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account? ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text('Log in', style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({required String label, required bool isVisible, required VoidCallback onToggle, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
            suffixIcon: IconButton(
              icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 20),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGold),
            ),
          ),
        ),
      ],
    );
  }
}