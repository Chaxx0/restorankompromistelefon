import 'dart:ui';
import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'api_service.dart';

class LoginTab extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginTab({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _LoginTabState createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final Color primaryGold = const Color(0xFFFFD700);
  final Color surfaceDark = const Color(0xFF1A1A1A);

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() { _isLoading = true; });
    var result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (mounted) {
      setState(() { _isLoading = false; });
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Welcome back to Kompromis!'), backgroundColor: Colors.green),
        );
        widget.onLoginSuccess();
      } else {
        // Show exact error from the server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid Email or password'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: surfaceDark.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant_menu, color: primaryGold, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Kompromis',
                        style: TextStyle(color: primaryGold, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Log into your guest account',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 40),

                      _buildTextField(label: 'EMAIL', hint: 'your@email.com', icon: Icons.email_outlined, controller: _emailController),
                      const SizedBox(height: 20),

                      _buildPasswordField(),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('LOG IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('New guest? ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          GestureDetector(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegistrationScreen()),
                              );
                              if (result == true) {
                                widget.onLoginSuccess();
                              }
                            },
                            child: Text(
                              'Register',
                              style: TextStyle(color: primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
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
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, required IconData icon, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.white54, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGold)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PASSWORD', style: TextStyle(color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white54, size: 20),
              onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryGold)),
          ),
        ),
      ],
    );
  }
}