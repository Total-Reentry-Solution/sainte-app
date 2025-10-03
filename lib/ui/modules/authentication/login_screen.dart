import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../components/input/input_field.dart';
import '../../components/input/password_field.dart';
import '../../components/buttons/primary_button.dart';

// SAINTE LOGIN SCREEN - Fixed with proper navigation and rounded inputs
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_loginFormKey.currentState!.validate()) {
      print('Login - Email: ${_emailController.text}');
      print('Login - Password: ${_passwordController.text}');
      print('Login - Remember me: $_rememberMe');
      
      // Navigate to home immediately
      if (mounted) {
        try {
          context.go('/home');
        } catch (e) {
          print('Navigation error: $e');
          // Fallback navigation
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    }
  }

  void _handleRegister() {
    if (_registerFormKey.currentState!.validate()) {
      print('Register - Email: ${_emailController.text}');
      print('Register - Password: ${_passwordController.text}');
      print('Register - Confirm Password: ${_confirmPasswordController.text}');
      
      // Navigate to account type selection immediately
      if (mounted) {
        try {
          context.go('/account-type');
        } catch (e) {
          print('Navigation error: $e');
          // Fallback navigation
          Navigator.of(context).pushReplacementNamed('/account-type');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left side - Dark with single large people image
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  // Single large people image centered
                  const Center(
                    child: SizedBox(
                      width: 432,
                      child: Image(
                        image: AssetImage('assets/images/People.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Dark overlay
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  // Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sainte title at top
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            'Sainte',
                            style: TextStyle(
                              color: const Color(0xFF3AE6BD),
                              fontSize: 54,
                              fontFamily: 'InterBold',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // "Everybody is a sainte" text at bottom
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            "Everybody is a sainte",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Right side - Light with login form
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                child: Column(
                  children: [
                    // Tab bar
                    TabBar(
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: 'Login'),
                        Tab(text: 'Register'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Form
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildLoginForm(),
                          _buildRegisterForm(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email field
          InputField(
            label: 'Email',
            hint: 'hello@gmail.com',
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          // Password field
          PasswordField(
            label: 'Password',
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          // Remember me and Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement forgot password
                  print('Forgot password clicked');
                },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Login button
          PrimaryButton(
            text: 'Login',
            onPress: _handleLogin,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign up',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          // Email field
          InputField(
            label: 'Email',
            hint: 'hello@mail.com',
            controller: _emailController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          // Password field
          PasswordField(
            label: 'Password',
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          // Confirm Password field
          PasswordField(
            label: 'Repeat password',
            hint: 'Repeat password',
            controller: _confirmPasswordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(text: 'By signing Up, you agree to have read our '),
                      TextSpan(
                        text: 'privacy policy,',
                        style: TextStyle(color: Color(0xFF3AE6BD)),
                      ),
                      TextSpan(text: ' as well as our '),
                      TextSpan(
                        text: 'end user license agreement',
                        style: TextStyle(color: Color(0xFF3AE6BD)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Sign up button
          PrimaryButton(
            text: 'Sign up',
            onPress: _handleRegister,
          ),
        ],
      ),
    );
  }
}