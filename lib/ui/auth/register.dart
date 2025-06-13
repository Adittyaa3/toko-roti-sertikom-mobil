  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:sertifikasitest/ui/auth/login.dart';
  import 'package:sertifikasitest/page/home.dart';

  class RegisterScreen extends StatefulWidget {
    const RegisterScreen({super.key});

    @override
    _RegisterScreenState createState() => _RegisterScreenState();
  }

  class _RegisterScreenState extends State<RegisterScreen> {
    
    final TextEditingController _fullNameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _passwordVerificationController =TextEditingController();
    

    bool _isPasswordVisible = false;
    bool _isPasswordVerificationVisible = false;
    bool _isLoading = false;

    
    String? _emailError;
    String? _passwordError;
    String? _passwordVerificationError;
    String? _fullNameError;

    Future<void> _validateAndRegister() async {
      // Reset errors
      setState(() {
        _emailError = null;
        _passwordError = null;
        _passwordVerificationError = null;
        _fullNameError = null;
      });

      // Validasi full name
      if (_fullNameController.text.isEmpty) {
        setState(() {
          _fullNameError = 'Full name cannot be empty';
        });
        return;
      }

      // Validasi email
      if (_emailController.text.isEmpty) {
        setState(() {
          _emailError = 'Email cannot be empty';
        });
        return;
      } else if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text)) {
        setState(() {
          _emailError = 'Please enter a valid email';
        });
        return;
      }

      // Validasi password
      if (_passwordController.text.isEmpty) {
        setState(() {
          _passwordError = 'Password cannot be empty';
        });
        return;
      } else if (_passwordController.text.length < 6) {
        setState(() {
          _passwordError = 'Password must be at least 6 characters';
        });
        return;
      }

      // Validasi password verification
      if (_passwordVerificationController.text.isEmpty) {
        setState(() {
          _passwordVerificationError = 'Password verification cannot be empty';
        });
        return;
      } else if (_passwordVerificationController.text !=
          _passwordController.text) {
        setState(() {
          _passwordVerificationError = 'Passwords do not match';
        });
        return;
      }

      // If no validation errors, proceed with registration
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (response.user != null) {
          await Supabase.instance.client.from('detail_users').insert({
            'user_id': response.user!.id,
            'nama_lengkap': _fullNameController.text,
            'role': 'customer', // Default role
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration successful!')),
            );
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else if (response.session == null && mounted) {
          // Handle cases where user is null but no specific error is thrown by supabase
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration failed: User could not be created.')),
          );
        }
      } on AuthException catch (e) {
        print('Supabase Auth Error: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${e.message}')),
          );
        }
      } catch (e) {
        print('General Registration Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${e.toString()}')),
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
      _passwordVerificationController.dispose();
      _fullNameController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double screenHeight = MediaQuery.of(context).size.height;

      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.11,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 28,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTextField(
                        'Full Name',
                        'assets/images/user.png',
                        screenWidth,
                        controller: _fullNameController,
                        keyboardType: TextInputType.text,
                        errorText: _fullNameError,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextField(
                        'Email',
                        'assets/images/iconlogin.png',
                        screenWidth,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextField(
                        'Password',
                        'assets/images/lock.png',
                        screenWidth,
                        controller: _passwordController,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onVisibilityChanged: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        errorText: _passwordError,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildTextField(
                        'Password Verification',
                        'assets/images/lock.png',
                        screenWidth,
                        controller: _passwordVerificationController,
                        isPassword: true,
                        isVisible: _isPasswordVerificationVisible,
                        onVisibilityChanged: () {
                          setState(() {
                            _isPasswordVerificationVisible =
                                !_isPasswordVerificationVisible;
                          });
                        },
                        errorText: _passwordVerificationError,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validateAndRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const  Color(0xFFD58600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      const Text(
                        'or Sign up with',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // SizedBox(height: screenHeight * 0.02),
                      // SizedBox(
                      //   width: double.infinity,
                      //   height: screenHeight * 0.06,
                      //   child: OutlinedButton(
                      //     onPressed: () async {
                      //       try {
                      //         // Sign up dengan Google
                      //         await Supabase.instance.client.auth.signInWithOAuth(
                      //           // Provider.google,
                      //           redirectTo: 'io.supabase.flutterquickstart://login-callback/',
                      //         );
                      //       } catch (e) {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text('Google sign up failed: $e')),
                      //         );
                      //       }
                      //     },
                      //     style: OutlinedButton.styleFrom(
                      //       side: const BorderSide(color: Color(0xFF205781)),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(16),
                      //       ),
                      //     ),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Image.asset(
                      //           'assets/images/google.png',
                      //           width: screenWidth * 0.05,
                      //           height: screenWidth * 0.05,
                      //         ),
                      //         SizedBox(width: screenWidth * 0.04),
                      //         const Text(
                      //           'SIGN UP WITH GOOGLE',
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
                      SizedBox(height: screenHeight * 0.02),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: Color(0xFFD58600),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'By clicking sign up you are agreeing to the\n',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: 'Terms of use',
                          style: TextStyle(
                            
                            color: Color(0xFFD58600),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: ' and the ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(
                          text: 'privacy policy',
                          style: TextStyle(
                            
                            color: Color(0xFFD58600),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildTextField(
      String label,
      String iconPath,
      double screenWidth, {
      TextEditingController? controller,
      TextInputType? keyboardType,
      bool isPassword = false,
      bool isVisible = false,
      VoidCallback? onVisibilityChanged,
      String? errorText,
    }) {
      return Container(
        width: double.infinity,
        height: screenWidth * 0.12,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFD58600)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: isPassword && !isVisible,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  suffixIcon:
                      isPassword
                          ? IconButton(
                            icon: Icon(
                              isVisible ? Icons.visibility : Icons.visibility_off,
                              color: const Color(0xFFD58600),
                            ),
                            onPressed: onVisibilityChanged,
                          )
                          : null,
                  errorText: errorText,
                  errorStyle: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
