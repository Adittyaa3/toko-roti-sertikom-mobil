import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sertifikasitest/main.dart';
import 'package:sertifikasitest/ui/auth/register.dart'; // Ubah dari login.dart ke register.dart

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String? _emailError;
  String? _passwordError;
  bool _isLoading = false;

  Future<void> _validateAndLogin() async {
    // Perform synchronous validation first
    String? currentEmailError;
    String? currentPasswordError;

    // Validasi email
    if (_emailController.text.isEmpty) {
      currentEmailError = 'Email cannot be empty';
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailController.text)) {
      currentEmailError = 'Please enter a valid email';
    }

    // Validasi password
    if (_passwordController.text.isEmpty) {
      currentPasswordError = 'Password cannot be empty';
    } else if (_passwordController.text.length < 6) {
      currentPasswordError = 'Password must be at least 6 characters';
    }

    // Update the UI with validation errors synchronously
    setState(() {
      _emailError = currentEmailError;
      _passwordError = currentPasswordError;
    });

    // Jika tidak ada error validasi, lanjutkan proses login
    if (currentEmailError == null && currentPasswordError == null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Login menggunakan Supabase (asynchronous operation)
        final response =
            await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return; // Check if the widget is still in the tree

        if (response.user != null) {
          // Login berhasil, arahkan ke HomeScreen
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        if (!mounted) return;
        // Tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
          
                  const SizedBox(height: 30),
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFD58600),
                      fontSize: 28,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Image.asset(
                              'assets/images/iconlogin.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          hintText: 'Email',
                          hintStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD58600),
                              width: 1,
                            ),
                          ),
                          errorText: _emailError,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Image.asset(
                              'assets/images/lock.png',
                              width: 20,
                              height: 20,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFFD58600),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD58600),
                              width: 1,
                            ),
                          ),
                          errorText: _passwordError,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // Navigasi ke halaman Forgot Password
                            // Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
                          },
                          child: Text(
                            'Forgot Password',
                            style: TextStyle(
                              color: const Color(0xFFD58600),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validateAndLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD58600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Text(
                          'Or login with',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: 46,
                      //   child: OutlinedButton(
                      //     onPressed: () async {
                      //       try {
                      //         // Login dengan Google
                      //         await Supabase.instance.client.auth.signInWithOAuth(
                      //           Provider.google,
                      //           redirectTo: 'io.supabase.flutterquickstart://login-callback/',
                      //         );
                      //       } catch (e) {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text('Google login failed: $e')),
                      //         );
                      //       }
                      //     },
                      //     style: OutlinedButton.styleFrom(
                      //       side: const BorderSide(
                      //         color: Color(0xFF205781),
                      //         width: 1,
                      //       ),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(16),
                      //       ),
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Image.asset(
                      //           'assets/images/google.png',
                      //           width: 22,
                      //           height: 22,
                      //         ),
                      //         const SizedBox(width: 10),
                      //         Text(
                      //           'Login with Google',
                      //           style: TextStyle(
                      //             color: Colors.black,
                      //             fontSize: 14,
                      //             fontFamily: 'Poppins',
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(
                              color: const Color(0xFFD58600),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}