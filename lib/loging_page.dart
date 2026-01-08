// lib/loging_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:slt_hire_log/blocks/user/user_bloc.dart';
import 'package:slt_hire_log/blocks/user/user_event.dart';
import 'package:slt_hire_log/constants/app_colors.dart';
import 'package:slt_hire_log/fetch_user.dart';

class SLTLoginPage extends StatefulWidget {
  const SLTLoginPage({super.key});

  @override
  State<SLTLoginPage> createState() => _SLTLoginPageState();
}

class _SLTLoginPageState extends State<SLTLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  final List<String> _emailDomains = [
    '@slt.lk',
    '@gmail.com',
    '@yahoo.com',
    '@outlook.com',
  ];
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    emailController.removeListener(_onEmailChanged);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final text = emailController.text;
    if (text.contains('@')) {
      final parts = text.split('@');
      if (parts.length == 2 && parts[1].isNotEmpty) {
        final prefix = parts[0];
        final domainPart = parts[1].toLowerCase();

        setState(() {
          _emailSuggestions = _emailDomains
              .where((domain) => domain.substring(1).startsWith(domainPart))
              .map((domain) => '$prefix$domain')
              .toList();
          _showSuggestions = _emailSuggestions.isNotEmpty;
        });
      } else {
        _clearSuggestions();
      }
    } else {
      _clearSuggestions();
    }
  }

  void _clearSuggestions() {
    setState(() {
      _emailSuggestions = [];
      _showSuggestions = false;
    });
  }

  void _popIfPossible(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;
    final isLarge = screenSize.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FE),
      body: isSmall
          ? Container(color: AppColors.scaffoldBackgroundColor)
          : Row(
              children: [
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenSize.width,
                            child: SingleChildScrollView(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: isSmall ? screenSize.width * 0.9 : 400,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color.fromARGB(255, 154, 154, 154),
                                          spreadRadius: 6,
                                          blurRadius: 20,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: _buildLoginForm(context),
                                  ),
                                  if (isLarge)
                                    Container(
                                      width: 400,
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            "assets/SLTMobitel_logo.png",
                                            width: 400,
                                            height: 200,
                                          ),
                                          const Text(
                                            "SLT Hire Log",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 30,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
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

  Widget _buildLoginForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Login",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text("E-mail", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Stack(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: AppColors.scaffoldBackgroundColor,
                  hintText: "Enter email",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color.fromARGB(113, 158, 158, 158)),
                  ),
                ),
              ),
              if (_showSuggestions)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _emailSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            title: Text(
                              _emailSuggestions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              setState(() {
                                emailController.text = _emailSuggestions[index];
                                _showSuggestions = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text("Password", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.scaffoldBackgroundColor,
              hintText: "Enter password",
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password flow
              },
              child: const Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await _handleLogin(context);
              },
              child: const Text(
                "Login",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text("Access restricted to authorized staff only"),
          ),
          const SizedBox(height: 4),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                Text("Request Access", style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
      }
      return;
    }

    _showShimmerLoadingDialog(context);

    try {
      UserCredential credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Authentication failed');

      _popIfPossible(context); // ✅ Safe pop

      // ✅ DO NOT sign out here — keep user session!
      // ❌ Remove: await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        context.read<UserBloc>().add(FetchUserEvent(user.uid));
        
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const FetchUser()),
          );
      }

    } on FirebaseAuthException catch (e) {
      _popIfPossible(context);
      if (context.mounted) {
        _showErrorDialog(context, _getFirebaseErrorMessage(e));
      }
    } catch (e) {
      _popIfPossible(context);
      if (context.mounted) {
        _showErrorDialog(context, 'An unexpected error occurred');
      }
    }
  }

  void _showShimmerLoadingDialog(BuildContext context) {
    if (!context.mounted) return; // ✅ Guard

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Shimmer.fromColors(
                baseColor: const Color(0xFF0057A8),
                highlightColor: const Color(0xFF4CBD4C),
                period: const Duration(seconds: 1),
                child: Image.asset(
                  'assets/SLTMobitel_Logo.png',
                  width: 80,
                  height: 60,
                ),
              ),
              const SizedBox(height: 24),
              Shimmer.fromColors(
                baseColor: const Color(0xFF0F172A),
                highlightColor: const Color(0xFF64748B),
                period: const Duration(milliseconds: 1500),
                child: const Text(
                  "Authenticating...",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              const Text("Please wait", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email': return 'Invalid email address';
      case 'user-disabled': return 'This account has been disabled';
      case 'user-not-found': return 'No account found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'too-many-requests': return 'Too many attempts. Try again later.';
      default: return 'Login failed: ${e.message ?? 'Unknown error'}';
    }
  }
}