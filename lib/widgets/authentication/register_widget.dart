import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../data/auth_service.dart';
import '../../screens/settings/terms_and_privacy_policy.dart';

class RegisterWidget extends StatefulWidget {
  const RegisterWidget({super.key});

  @override
  RegisterWidgetState createState() => RegisterWidgetState();
}

class RegisterWidgetState extends State<RegisterWidget>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isTermsAccepted = false;
  bool _isLoading = false;

  late AnimationController _snackAnimationController;
  late Animation<double> _snackAnimation;

  @override
  void initState() {
    super.initState();
    _snackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _snackAnimation = CurvedAnimation(
        parent: _snackAnimationController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _snackAnimationController.dispose();
    super.dispose();
  }
Future<void> _register() async {
  if (_formKey.currentState!.validate() && _isTermsAccepted) {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String name = _nameController.text.trim();

    // ✅ Ensure email format is correct before calling Firebase
    if (!_isValidEmail(email)) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid email format. Please enter a valid email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? errorMessage = await _authService.register(email, password, name);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      _showSnackBar("Registration successful!", Colors.green);
      Navigator.pushReplacementNamed(context, '/login', arguments: email);
    } else {
      _showSnackBar(errorMessage, Colors.red);
    }
  }
}

bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email);
  }

// ✅ Utility function to show SnackBar messages
void _showSnackBar(String message, Color color) {
  _snackAnimationController.forward(from: 0);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.transparent,
      content: FadeTransition(
        opacity: _snackAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
  void _navigateToTermsPage() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 📌 **App Logo**
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.app_registration,
                        size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "My Exercises",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Create an account to get started!\nJoin and explore the features.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // 📌 **Form Section**
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _nameController,
                          label: "Name",
                          icon: Icons.person_outline,
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Please enter your name'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _emailController,
                          label: "Email",
                          icon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            } else if (!RegExp(
                                    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          controller: _passwordController,
                          label: "Password",
                          icon: Icons.lock_outline,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 📌 **Terms & Conditions Agreement**
                  Row(
                    children: [
                      Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (value) =>
                            setState(() => _isTermsAccepted = value ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _navigateToTermsPage,
                          child: const Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 📌 **Register Button**
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        backgroundColor: Colors.blue,
                      ),
                      onPressed:
                          _isTermsAccepted && !_isLoading ? _register : null,
                      child: const Text('Sign Up',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 📌 **Login Navigation**
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Login',
                            style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 📌 **Loading Indicator**
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child:
                    const Center(child: CupertinoActivityIndicator(radius: 15)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
}
